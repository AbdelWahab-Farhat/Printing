# Settable stock unit, and fulfilment moved to «جاهزة» — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, API.
> Backend only — nothing in `frontend/` was touched. See
> [STOCK-UNIT-AND-READY-DEDUCTION-FRONTEND-INTEGRATION.md](STOCK-UNIT-AND-READY-DEDUCTION-FRONTEND-INTEGRATION.md)
> for wiring the app up to this.
>
> Companion doc: [COST-TRACKING-UNIT-CONVERSION.md](../costing/COST-TRACKING-UNIT-CONVERSION.md) — §3
> ("Units of measurement") and §4 ("Order fulfillment: manual unit conversion") are **superseded**
> by §2 and §3 below respectively. §4's "known gap" (editing a line after stock has left) is now
> partially closed as a side effect — see §3.

---

## 1. Why

Two requests, investigated together because the second turned out to depend on the first:

1. **Make `warehouse_stocks.unit` / `stock_batches.unit` settable.** They were pure one-time
   snapshots of the product's `pricing_unit`, never editable. Digging into *why* someone wanted
   this surfaced the real need: some products are **bought/stored in one unit and sold in
   another** — e.g. bought in by the kilogram, sold by the piece. The single `pricing_unit`
   column couldn't represent that; it drove selling price, order-quantity granularity, *and* the
   warehouse's unit all at once. Making the stock rows independently editable without fixing that
   would have let them drift from the product's `pricing_unit` — and since every stock movement
   re-derives its unit from the product, the very next movement would throw
   `UnitOfMeasurementMismatch` and lock the balance.
2. **Move the point where an order deducts stock from `printing` to `ready`.** Simpler on its own,
   but has one hidden dependency: the `warehouse_id` transition field has to move with it, or
   deduction silently stops firing.

---

## 2. A second unit: `products.stock_unit`

**The fix is a second, explicit column — not a decoupled/freestanding edit.** `pricing_unit`
keeps meaning "what the customer is charged by" (and governs order-quantity granularity, unchanged).
The new `stock_unit` means "what the warehouse counts this in" — governs warehouse-movement
granularity and the `warehouse_stocks`/`stock_batches` snapshot. This mirrors how this codebase
already snapshots canonical values everywhere else (`order_items.pricing_unit`,
`purchase_order_items.unit`, `stock_batches.unit_cost`, …) rather than inferring them at read
time — a freestanding, undeclared "stock unit" would have had no answer for what unit a
brand-new product's *first ever* arrival should use, before any balance row exists to read from.

### Database

**New migration** `2026_08_15_100000_add_stock_unit_to_products_table.php`

| Table | Column | Notes |
|---|---|---|
| `products` | `stock_unit` — `string(20)`, `NOT NULL` | Added nullable, backfilled `stock_unit = pricing_unit` for every existing row, then closed to `NOT NULL`. No behaviour changes for any existing product until someone explicitly sets a different `stock_unit`. |

`warehouse_stocks.unit` / `stock_batches.unit` — **unchanged in shape** (still `NOT NULL`, still
absent from each model's `Fillable`). What changed is what they're a snapshot *of*: `stock_unit`
now, not `pricing_unit`.

### Domain

- `Catalog\Models\Product` — `stock_unit` added to `Fillable` and cast to `PricingUnit`. Fillable
  only matters for **creation**: `UpdateProductRequest` deliberately carries no `stock_unit` rule,
  so a `PUT /products/{id}` can never touch it. The only writer after creation is the new
  `SetStockUnit` action (below).
- `Inventory\Actions\RecordStockMovement` — the unit passed into `ApplyStockChange` for every
  movement now resolves from `$variant->product->stock_unit`, not `pricing_unit`. That one line
  is the entire behavioural change; `ApplyStockChange`'s signatures are untouched.
- `Catalog\CatalogService::requiresWholeQuantities()` — now reads `stock_unit`, not `pricing_unit`.
  This method has exactly one caller (`RecordStockMovement`'s whole-quantity guard on a warehouse
  movement) — order-side quantity validation (`QuoteProductRequest`) reads `pricing_unit` directly
  and was untouched. So a kilogram-`stock_unit`, piece-`pricing_unit` product can now take a
  fractional warehouse movement while still refusing a fractional *order* quantity.
- **New action** `Inventory\Actions\SetStockUnit` — `(Product $product, PricingUnit $unit): Product`.
  In one `DB::transaction()`: updates `products.stock_unit`, then locks (in ascending
  warehouse/variant order, same deadlock-avoidance reasoning `ApplyStockChange::moveTransferBalances()`
  already uses) and updates **every** `WarehouseStock` and `StockBatch` row across **every**
  warehouse for the product's variants, to the same unit, atomically. This is what makes "always
  the same" a structural guarantee rather than a convention — the product, every balance, and
  every cost batch move together or not at all.
- No quantity restriction on `SetStockUnit` — it declares the real physical unit going forward, it
  does not "convert" existing numbers (nothing needs converting: the figures were correct in
  their own unit before the call and stay correct after it).
- `Inventory\Models\WarehouseStock` / `StockBatch` — docblocks updated to describe `SetStockUnit`
  as the (only) post-creation writer of `unit`. No fillable/cast change — `unit` was and remains
  absent from `Fillable` on both; nothing reaches it via mass assignment.
- `Inventory\InventoryService::setStockUnit()` — thin passthrough, matching the existing
  `setLowStockThreshold()` pattern.

### API

**New:** `PATCH /api/v1/products/{product}/stock-unit`, gated by `can:inventory.manage` (not
`products.manage` — this is an inventory fact about the product, not a catalogue one, even though
it's addressed by product id).

```jsonc
// PATCH /products/14/stock-unit
{ "unit": "kilogram" }
```

```jsonc
// 200 — data: the full ProductResource, refreshed
{ "id": 14, "pricing_unit": "piece", "stock_unit": "kilogram", … }
```

- `SetStockUnitRequest` — `unit`: `required`, `Rule::enum(PricingUnit::class)`.
- `StoreProductRequest` — new, **optional** `stock_unit` field (`nullable`,
  `Rule::enum(PricingUnit::class)`). Left out entirely on the common path, where it equals
  `pricing_unit` — `ProductData::fromArray()` defaults it to the submitted `pricing_unit` when
  absent.
- `UpdateProductRequest` — deliberately **no** `stock_unit` rule. Sending the key to `PUT
  /products/{id}` is simply ignored (not validated, not read).
- `ProductResource` — two new fields: `stock_unit` (string) and `stock_unit_label` (Arabic label,
  same treatment `pricing_unit`/`pricing_unit_label` already get).

---

## 3. Fulfilment moved from «قيد الطباعة» to «جاهزة»

**`Order\Actions\ChangeOrderStatus`** — the stock-deduction/costing guard:

```php
// was: $target === OrderStatus::Printing && $order->stock_deducted_at === null
$deductStock = $target === OrderStatus::Ready && $order->stock_deducted_at === null;
```

Everything downstream of this guard (`stock_deducted_at`, `fulfillment_warehouse_id`,
`DeductOrderStock`, `ApplyManufacturingRates`, `RecalculateOrderCogs`/`RecalculateOrderItemCost`,
production cost entries) is otherwise **unchanged** — it all already keyed off this one boolean.
`ReverseOrderStockDeduction` on cancellation is unaffected (`stock_deducted_at !== null` still
reads the same fact regardless of which status set it).

**`Order\Support\TransitionFields`** — the `warehouse_id` field (type `warehouse`, required
exactly when `$order->stock_deducted_at === null`) moved from the `printing` target to the
`ready` target, where it now sits alongside the pre-existing `weight_kg` field.

### Why this is safe

Confirmed from `OrderStatus::allowedNext()`: `ready` is reachable only from `printing`, and has
**no path back** to `printing`/`designing` (`Ready => [OfficePickup, OutForDelivery, Cancelled]`).
So an order reaches `ready` at most once, ever — the same single-shot guarantee
`stock_deducted_at === null` already relied on for `printing`'s old, re-enterable case (a reprint
bouncing `printing → designing → printing`). One consequence: the "does a reprint deduct/cost
twice" guard can no longer be exercised through a real transition sequence, since `ready` simply
cannot be re-entered legitimately — see §5 (Tests) for how that's now tested synthetically
instead.

**It's also a better fit than `printing` was.** `Order::itemsAreEditable()` includes `printing`
but not `ready` — so deducting at `ready` means an order's lines are frozen by the time stock
actually leaves the warehouse, closing the "known gap" flagged in
[COST-TRACKING-UNIT-CONVERSION.md §4](../costing/COST-TRACKING-UNIT-CONVERSION.md#4-order-fulfillment-manual-unit-conversion):
a line edited *while* `printing` (between the old deduction moment and the line change) used to
leave the warehouse balance reflecting a since-edited quantity. That specific race is now closed;
nothing else about that section changed (the manual `warehouse_quantity` entry itself, the
"no multiplier" behaviour, `DeductOrderStock`'s mechanics — all as documented there).

No route, controller, or request-shape change for this part — the `warehouse_id`/`weight_kg`
fields already travelled through the generic, server-driven `available_transitions[].fields`
list (`TransitionFields::for()` → `OrderResource` → `ChangeOrderStatusRequest`), so which
transition asks for them is entirely a server-side decision the client never hardcodes.

---

## 4. Where the code lives

```
backend/database/migrations/2026_08_15_100000_add_stock_unit_to_products_table.php   (new)

backend/app/Domain/Catalog/
├── Models/Product.php                    ← touched: +stock_unit fillable/cast
├── CatalogService.php                    ← touched: requiresWholeQuantities() reads stock_unit
├── DTOs/ProductData.php                  ← touched: +stockUnit, defaults to pricingUnit
└── Actions/CreateProduct.php             ← touched: writes stock_unit

backend/app/Domain/Inventory/
├── Actions/SetStockUnit.php              ← new
├── Actions/RecordStockMovement.php       ← touched: one line, stock_unit not pricing_unit
├── Models/WarehouseStock.php             ← touched: docblock only
├── Models/StockBatch.php                 ← touched: docblock only
└── InventoryService.php                  ← touched: +setStockUnit()

backend/app/Domain/Order/
├── Actions/ChangeOrderStatus.php         ← touched: trigger Printing → Ready
└── Support/TransitionFields.php          ← touched: warehouse_id moved to Ready

backend/app/Application/Api/V1/
├── Requests/Product/StoreProductRequest.php       ← touched: +stock_unit (optional)
├── Requests/Inventory/SetStockUnitRequest.php     ← new
├── Resources/ProductResource.php                  ← touched: +stock_unit, +stock_unit_label
└── Controllers/ProductController.php              ← touched: +setStockUnit()

backend/routes/api.php   ← + PATCH products/{product}/stock-unit  (can:inventory.manage)

backend/database/factories/ProductFactory.php      ← touched: +stock_unit default
backend/database/seeders/CatalogSeeder.php          ← touched: +stock_unit at each product creation
backend/app/Domain/Audit/AuditAttributeLabels.php   ← touched: +product.stock_unit label
```

Several docblock-only updates ride along in files that describe *when* deduction/costing fires
(now "ready" instead of "printing"): `Order\Actions\DeductOrderStock`,
`Order\Actions\ApplyManufacturingRates`, `Order\Actions\RecalculateOrderCogs`,
`Order\Actions\RecalculateOrderItemCost`, `Order\Enums\ManufacturingCostType`,
`Order\Models\Order` (the `stock_deducted_at` cast comment), `Order\OrderService`,
`Order\Enums\TransitionFieldType`, and two user-facing Arabic exception messages —
`Order\Exceptions\OrderNotYetInProduction` (scrap-loss guard: was "لم تدخل مرحلة الطباعة بعد",
now "لم يُخصم مخزونها بعد") and `Order\Exceptions\FulfillmentRequiresAnActor`.

---

## 5. Tests

No new test file — extended existing ones, following each file's own conventions.

**Stock unit:**

- `tests/Feature/Inventory/StockLedgerTest.php` — the existing "unit mismatch" test now changes
  `stock_unit` (not `pricing_unit`) to trigger `UnitOfMeasurementMismatch`, matching what actually
  drives movement resolution now.
- `tests/Feature/Audit/AuditAttributeLabelsTest.php` — passes once `product.stock_unit` has a
  label (it walks every loggable column and fails on any without one).

**Fulfilment timing** — the larger ripple, across every test that used to move an order into
`printing` expecting deduction/costing to fire there:

- `tests/Feature/Orders/OrderTransitionFieldsTest.php` — `warehouse_id` now asserted on `ready`,
  not `printing`; a new synthetic test (`stock_deducted_at` pre-set on an order still in
  `printing`, then moved to `ready`) covers the "not asked again" case in place of the old
  reprint-based one.
- `tests/Feature/Orders/ProductionCostTest.php` — `enterReady()` helper walks `printing` (no
  fields) then `ready` (with `warehouse_id`); the old reprint-guard test was rewritten
  (`test_stock_already_deducted_does_not_reapply_manufacturing_rates`) to construct an order
  directly in the post-deduction state and assert zero *new* entries, since `ready` can no longer
  be legitimately re-entered to test a real "second time".
- `tests/Feature/Orders/OrderWorkflowTest.php`, `OrderCancellationReversalTest.php`,
  `OrderShortageTest.php`, `ScrapLossTest.php` — mechanically updated (the `warehouse_id`
  auto-fill moved from the `printing` step to the `ready` step in each file's `move()`/similar
  helper) plus several tests renamed and materially rewritten where their whole point was
  deduction/costing/reversal timing — full list and reasoning were reviewed test-by-test against
  original intent during the change.
- `database/factories/ProductFactory.php`, `database/seeders/CatalogSeeder.php` — needed
  `stock_unit` added wherever they already set `pricing_unit`, or every product-creating test
  failed on the new `NOT NULL` constraint.

Verified locally (Postgres, `APP_ENV=testing`): full backend suite — **1261/1261** passing, 4170
assertions.

---

## 6. Compatibility note

**Behaviour change, not a contract break.** No existing field was renamed or removed. The
`warehouse_id`/`weight_kg` transition fields simply appear on a different `status` value in
`available_transitions[]` now (`ready` instead of `printing`) — any client that renders that list
generically (rather than hardcoding "the warehouse picker belongs on the printing screen")
needs no code change at all; see the frontend integration doc for what to actually verify.

The new `PATCH /products/{product}/stock-unit` endpoint and the two new `ProductResource` fields
(`stock_unit`, `stock_unit_label`) are additive.

---

Last updated: 2026-08-15.
