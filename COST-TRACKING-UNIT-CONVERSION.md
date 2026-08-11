# Cost tracking, units of measurement, and order fulfillment — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, and API.
> Nothing here is a proposal.
>
> Companion docs: [PURCHASE-ORDERS-DESIGN.md](PURCHASE-ORDERS-DESIGN.md) and
> [VENDORS-AND-PURCHASE-ORDERS.md](VENDORS-AND-PURCHASE-ORDERS.md) for the purchase order
> machinery this work extends. Backend only — nothing in `frontend/` was touched.

---

## 1. Why

Three gaps closed in one pass, because they touch overlapping tables and the same review made
sense for all three:

1. **Purchase orders carried no money.** A PO line was `quantity_ordered` /
   `quantity_received` only — a deliberate original decision (see
   VENDORS-AND-PURCHASE-ORDERS.md §2: "لا مال فيها إطلاقاً"). Planned cost per line, an order
   total, and the actual cost of what arrived are now tracked.
2. **Nothing recorded which unit a quantity was in.** `warehouse_stocks` and
   `purchase_order_items` now carry a snapshot of the product's unit (piece/kilogram).
3. **Selling in one unit while stocking in another was unhandled.** An employee can now record,
   directly on a sales line, how much that line actually takes out of the warehouse — and stock
   is deducted from the warehouse in its own unit, automatically, once, the first time an order
   goes to print.

---

## 2. Purchase order cost tracking

### Database

**`purchase_order_items`** — two columns added:

| Column | Type | Notes |
|---|---|---|
| `unit_cost` | `decimal(12,3)`, nullable, CHECK `>= 0` | The negotiated vendor cost per unit. Typed by whoever raises the order — there is no catalogue price for what *we* pay a vendor, unlike a customer's `unit_price`. |
| `total_cost` | `decimal(14,2)`, nullable, CHECK `>= 0` | `unit_cost * quantity_ordered`, rounded. Never typed — computed and force-filled by the domain layer only. |

**`purchase_orders`** — one column added:

| Column | Type | Notes |
|---|---|---|
| `total_amount` | `decimal(14,2)`, nullable, CHECK `>= 0` | Sum of every line's `total_cost`. Recomputed by `RecalculatePurchaseOrderTotal` after every create/update. |

**`stock_arrival_items`** — two columns added:

| Column | Type | Notes |
|---|---|---|
| `unit_cost` | `decimal(12,3)`, nullable | Copied from the ordering line's `unit_cost`. Stays `null` for a plain, unplanned `POST /stock-arrivals` — that endpoint's input never changes. |
| `total_cost` | `decimal(14,2)`, nullable | Priced against the quantity **actually received in this shipment**, not the order line's own `total_cost` — a partial receipt costs less than the whole line. |

All three sets of columns are nullable and unbackfilled: there is no historical cost to derive
for rows that predate this change.

**No cost column was added to `stock_movements` or `warehouse_stocks`.** Cost stays on the
paperwork (the order line, the arrival line) and never touches the quantity ledger/balance —
purchase orders still never write directly to inventory tables.

### Domain

- `PurchaseOrder\Support\Money` — a same-domain copy of `Order\Support\Money` (round-half-away-
  from-zero, since bcmath truncates). Kept local rather than shared to avoid a new
  `PurchaseOrder → Order` dependency.
- `PurchaseOrder\Actions\RecalculatePurchaseOrderTotal` — the one place `total_amount` is
  derived, mirroring `Order\Actions\RecalculateOrderTotals`. Called at the end of
  `CreatePurchaseOrder` and `UpdatePurchaseOrder`.
- `CreatePurchaseOrder` / `UpdatePurchaseOrder` — compute each line's `total_cost` and force-fill
  it alongside the client-supplied `unit_cost`; never trust a total from the request.
- `ReceivePurchaseOrder` — for each received line, copies the matched `PurchaseOrderItem`'s
  `unit_cost` and computes `total_cost` against the received quantity, then passes both through
  to `Vendor\DTOs\StockArrivalItemData` (new, optional `unitCost`/`totalCost` fields, always
  `null` through the generic endpoint — only this action ever sets them, the same treatment
  `purchaseOrderId` already gets).
- `Vendor\Actions\RecordStockArrival` — force-fills the two cost columns onto `StockArrivalItem`
  from the DTO.

### API

- `POST /purchase-orders`, `PUT /purchase-orders/{id}` — `items.*.unit_cost` is now **required**,
  `numeric`, `gte:0`.
- `PurchaseOrderResource` — `total_amount` (string, or `null` on a pre-existing order).
- `PurchaseOrderItemResource` — `unit_cost`, `total_cost` (strings, or `null`).
- `StockArrivalItemResource` — `unit_cost`, `total_cost` (strings, or `null`).

---

## 3. Units of measurement

Reuses the existing `Catalog\Enums\PricingUnit` (`piece` / `kilogram`) — no new enum. Both
`Inventory` and `PurchaseOrder` already depend on `Catalog` one-way, the same as `Order` does for
`order_items.pricing_unit`, which this follows exactly.

### Database

| Table | Column | Notes |
|---|---|---|
| `warehouse_stocks` | `unit` — `string(20)`, `NOT NULL` | A snapshot of the product's `pricing_unit`, written once when the balance row is *created*. Backfilled from each row's product, then closed to `NOT NULL`. |
| `purchase_order_items` | `unit` — `string(20)`, `NOT NULL` | Same snapshot treatment, for display only — it never drives an inventory decision. |

### Domain

- `ApplyStockChange::increase()` / `decrease()` now take a `PricingUnit $unit` parameter.
  `increase()` writes it only when creating a brand-new balance row; an existing row's `unit` is
  never rewritten.
- **New guard:** if a movement targets an existing balance whose stored `unit` differs from the
  product's *current* `pricing_unit` (i.e. the product's unit was edited after stock in the old
  unit already existed), `ApplyStockChange` throws `Inventory\Exceptions\UnitOfMeasurementMismatch`
  (422) instead of silently mixing units in one balance.
- `RecordStockMovement` resolves the variant once (reused for both the existing whole-quantity
  guard and the new unit check) and passes `variant->product->pricing_unit` down.
- `CreatePurchaseOrder` / `UpdatePurchaseOrder` set each line's `unit` from
  `productVariant->product->pricing_unit` when the line is written.

### API

- `WarehouseStockResource` — `unit`, `unit_label`.
- `PurchaseOrderItemResource` — `unit`, `unit_label`.

---

## 4. Order fulfillment: manual unit conversion

The first real link between `Order` and `Inventory`. Before this, stock only ever left a
warehouse through the generic, order-unaware `POST /stock-movements/fulfillments` — nothing
about an order's own lifecycle touched a balance.

**The number is manual and direct, not a multiplier.** A product may be sold by the piece while
the warehouse counts the same thing by the kilogram (or the reverse) — and bags are typically
weighed together as a batch on a scale, not counted piece by piece and multiplied out by a
per-piece factor. So there is no per-unit conversion rate: an employee reads the total for the
whole line off the scale and types that number directly, only when the sales unit and the
warehouse unit genuinely differ.

### Database

| Table | Column | Notes |
|---|---|---|
| `order_items` | `warehouse_quantity` — `decimal(12,3)`, nullable, CHECK `> 0` | The total this line actually takes out of the warehouse, in the warehouse's own unit — entered directly, not derived from `quantity`. `null` is the common case (sales unit = warehouse unit, deduct `quantity` as-is) — a permanent snapshot once set, never recomputed. |
| `orders` | `stock_deducted_at` — `timestamp`, nullable | Stamped once, on the *first* entry into `printing`. Unlike `printing_started_at`, never overwritten by a later visit — its whole job is remembering whether stock has already left the warehouse. |
| `orders` | `fulfillment_warehouse_id` — FK → `warehouses`, nullable, `nullOnDelete` | The warehouse the clerk named at that first entry. Same "denormalise the fact onto the order" treatment `shipping_company_id` already gets. |

### Domain

- `Order\Actions\DeductOrderStock` (new) — for each order line, deducts `warehouse_quantity`
  as-is (or `quantity` unchanged when it's `null`) via `InventoryService::recordMovement()` with
  `MovementType::OrderFulfillment` — `from_warehouse_id` = the named warehouse,
  `to_warehouse_id = null` (stock leaves the business; it does not move to another warehouse).
  There is no multiplication against `quantity` — the value entered is trusted whole, because a
  batch weighed together on a scale has no meaningful per-piece number to derive it from.
- `ChangeOrderStatus` calls it, inside its own transaction, **only** when the target is `printing`
  and `stock_deducted_at` is still `null`. `printing` is re-enterable (`ready`/`shortage` both
  lead back into it for a reprint) — this guard is what stops a reprint from deducting a second
  time.
- **Insufficient stock refuses the whole status change**, not just the deduction —
  `ApplyStockChange::decrease()`'s existing `InsufficientStock` exception rolls back the shared
  transaction, so the order stays in its previous status.
- `OrderItem::warehouse_quantity` is fillable via `AddOrderItem`/`SyncOrderItems`, the normal
  create/update-lines path — no special endpoint. It can be entered (or left null) any time the
  line itself is editable — at order creation, or on any later edit — independently of the
  `/orders/{id}/status` call that actually triggers the deduction.

### API — a new transition field

`TransitionFields::for()` gains a `warehouse_id` field on the `printing` target (new
`TransitionFieldType::Warehouse`, modelled on the existing `ShippingCompany` case — an FK chosen
from a maintained list, options not inlined). **Required only when `stock_deducted_at` is still
`null`** — a reprint that already deducted stock is offered the field but not made to fill it in,
the same `required: ! hasDesigns($order)` idiom the `design_ids` field already uses.

- `StoreOrderRequest` / `UpdateOrderRequest` — `items.*.warehouse_quantity`: `nullable`,
  `numeric`, `gt:0`.
- `OrderItemResource` — `warehouse_quantity` (string, or `null`).
- `OrderResource` — `fulfillment_warehouse_id`, `stock_deducted_at`.

### Known gap — editing a line after stock has already left

`Order::itemsAreEditable()` allows editing lines while `new`, `designing`, **or `printing`** — so
a clerk can change a line's `quantity` or `warehouse_quantity` *after* `stock_deducted_at` is
already set. Nothing re-adjusts the warehouse balance when that happens: `SyncOrderItems` has no
dependency on Inventory at all, and `DeductOrderStock` only ever runs once per order. The edit
changes the paperwork; the stock already deducted reflects whatever the line said at the moment
of that first `printing` entry. Not solved here — flagged for a future decision (lock the fields
once deducted, or post an adjusting movement for the delta).

---

## 5. Where the code lives

```
backend/app/Domain/PurchaseOrder/
├── Support/Money.php                              ← new
├── Actions/RecalculatePurchaseOrderTotal.php       ← new
├── Actions/{Create,Update,Receive}PurchaseOrder.php  ← touched, cost + unit
├── Models/{PurchaseOrder,PurchaseOrderItem}.php    ← touched, casts/fillable
└── DTOs/PurchaseOrderItemData.php                  ← touched, +unitCost

backend/app/Domain/Vendor/
├── Actions/RecordStockArrival.php                  ← touched, force-fills cost
├── DTOs/StockArrivalItemData.php                   ← touched, +unitCost/+totalCost
└── Models/StockArrivalItem.php                     ← touched, casts

backend/app/Domain/Inventory/
├── Exceptions/UnitOfMeasurementMismatch.php        ← new
├── Actions/ApplyStockChange.php                    ← touched, +unit param, mismatch guard
├── Actions/RecordStockMovement.php                 ← touched, resolves variant once
└── Models/WarehouseStock.php                       ← touched, cast

backend/app/Domain/Order/
├── Actions/DeductOrderStock.php                    ← new
├── Exceptions/FulfillmentRequiresAnActor.php       ← new
├── Actions/ChangeOrderStatus.php                   ← touched, calls DeductOrderStock
├── Actions/AddOrderItem.php                        ← touched, +warehouse_quantity
├── Enums/TransitionFieldType.php                   ← touched, +Warehouse case
├── DTOs/{TransitionField,OrderItemData}.php        ← touched
├── Support/TransitionFields.php                    ← touched, +warehouse_id on printing
└── Models/{Order,OrderItem}.php                    ← touched, casts/fillable

backend/app/Application/Api/V1/
├── Requests/PurchaseOrder/{Store,Update}PurchaseOrderRequest.php  ← +unit_cost validation
├── Requests/Order/{Store,Update}OrderRequest.php                  ← +warehouse_quantity validation
└── Resources/{PurchaseOrder,PurchaseOrderItem,StockArrivalItem,
               WarehouseStock,Order,OrderItem}Resource.php         ← new fields exposed

backend/database/migrations/2026_08_09_*.php  (7 files — see §2–4 tables above)
backend/database/factories/{PurchaseOrderItem,WarehouseStock}Factory.php  ← new field defaults
```

---

## 6. Tests

Extended rather than duplicated, following each file's existing conventions:

- `tests/Feature/Api/V1/PurchaseOrderTest.php` — line/order total computation, `unit_cost`
  required on create, cost carried into a partial receive, plain arrivals stay cost-free.
- `tests/Feature/Inventory/StockLedgerTest.php` — unit snapshot on first arrival, the mismatch
  guard when a product's unit changes after stock exists.
- `tests/Feature/Orders/OrderTransitionFieldsTest.php` — `printing` asks for a warehouse (and
  only demands it on a first entry, not a reprint).
- `tests/Feature/Orders/OrderWorkflowTest.php` — deduction with and without an entered
  `warehouse_quantity`, a reprint not deducting twice, insufficient stock rolling back the whole
  transition, entering `printing` with no warehouse being refused.

Existing fixtures across `PurchaseOrderTest.php` and `OrderWorkflowTest.php` were updated to
supply the two newly-required fields (`unit_cost` on a PO line, `warehouse_id` when entering
`printing`) — full suite (997 tests) passes.

---

Last updated: 2026-08-11.
