# Profit & Loss, batch inventory costing, and manufacturing job costing — backend changes

> **Implemented.** Everything below is what was actually built — schema, domain layer, and API.
> Nothing here is a proposal.
>
> Companion doc: [COST-TRACKING-UNIT-CONVERSION.md](COST-TRACKING-UNIT-CONVERSION.md), which this
> work extends directly — that pass got vendor cost onto purchase-order paperwork; this pass
> carries that cost through to the warehouse balance, through production, and out the other side
> as a profit-and-loss report. Backend only — nothing in `frontend/` was touched.

---

## 1. Why

Three numbers the business could not previously get out of the system, closed in one connected
piece of work because each is a precondition for the next:

1. **A unit of stock had no cost once it reached the warehouse.** `purchase_order_items` and
   `stock_arrival_items` already carried `unit_cost`/`total_cost` (see the companion doc), but
   `warehouse_stocks` and `stock_movements` carried none — the cost died at the warehouse door.
   There was no way to answer "what did the material for this order actually cost?"
2. **Nothing captured labour, machine time or overhead against a job.** An order's `grand_total`
   was pure revenue; nothing on the cost side existed at all.
3. **There was no report putting the two together.** Revenue and cost of goods sold each existed
   in fragments, never summed against each other over a period.

This closes all three: every unit of stock now remembers what it cost (FIFO-layered), every order
line accumulates what it cost to produce, and a profit-and-loss report reads both back. Two edge
cases that fall directly out of costed inventory — spoiled stock, and an order cancelled after its
stock already left the warehouse — are handled too.

---

## 2. FIFO batch costing (`Inventory`)

### Database

**`stock_batches`** — one row per cost layer of one size in one warehouse.

| Column | Type | Notes |
|---|---|---|
| `warehouse_id`, `product_variant_id` | FK | |
| `source_type` | `string(20)` → `StockBatchSourceType` | `purchase_arrival` \| `adjustment` \| `opening_balance` |
| `stock_arrival_item_id` | FK, nullable | Reserved for tracing a batch back to its costed arrival line. **Not populated yet** — `RecordStockArrival` creates the `StockArrivalItem` row *after* the movement (and therefore the batch) it produced, so the id doesn't exist at batch-creation time. A follow-up that reorders `RecordStockArrival` would wire this through. |
| `unit_cost` | `decimal(12,3)`, CHECK `>= 0` | Immutable once set |
| `quantity_received`, `quantity_remaining` | `decimal(12,3)` | Drawn down by FIFO consumption |
| `unit` | `string(20)` | Snapshot, same convention as `warehouse_stocks.unit` |
| `received_at` | `timestamp` | **The FIFO ordering key** — not `created_at` |

**`stock_batch_consumptions`** — append-only ledger of FIFO draws, one row per (movement, batch)
pair a decrease touched.

| Column | Type | Notes |
|---|---|---|
| `stock_batch_id`, `stock_movement_id` | FK | |
| `quantity`, `unit_cost`, `total_cost` | decimal | `unit_cost`/`total_cost` snapshotted from the batch at the moment of consumption |

**The invariant the whole design holds:** for every `(warehouse_id, product_variant_id)`,
`SUM(stock_batches.quantity_remaining)` always equals `warehouse_stocks.quantity`. Both are
written only by `ApplyStockChange`, under the same row lock, in the same transaction — they can
never drift apart.

**Backfill**: one zero-cost `opening_balance` batch per pre-existing `warehouse_stocks` row,
`received_at` pinned to `1970-01-01` so FIFO burns off the unknown-cost legacy stock before any
real costed layer.

### Domain

- **`ApplyStockChange`** — extended, not replaced. `decrease()` now also drives
  `ConsumeStockBatchesFifo` and returns a `StockChangeResult` (balance + what was drawn, oldest
  layer first). `increase()` opens one new batch at a given cost. `relocateBatches()` — new,
  used only by an internal transfer's destination — recreates the *exact* batches the paired
  `decrease()` drew from at the new warehouse, preserving `received_at`/cost/source rather than
  opening one fresh batch at a blended cost (that would both invert FIFO age and average away the
  layers FIFO exists to keep distinct). `creditBack()` — new, used by order-cancellation reversal
  (§5) — grows a balance by crediting back exactly the batches a given movement drew from.
- **`ConsumeStockBatchesFifo`** / **`CreditBackStockBatches`** — the two small actions that do the
  batch-row locking and arithmetic `ApplyStockChange` calls into.
- **`RecordStockMovement`** — reordered: the `stock_movements` row is now saved *before* balances
  move (consuming a cost layer needs the row's own id to attach `stock_batch_consumptions` to),
  still one transaction throughout. A transfer's two rows are now locked in ascending warehouse id
  *before* either balance moves, decoupling deadlock-avoidance lock order from the order the
  actual decrease/relocate calls run in.
- **Cost input on arrivals/adjustments**: `unit_cost` is optional on an arrival (missing → an
  explicit `0.000` layer, matching the same "unknown cost" placeholder the backfill uses — the
  arrival is not refused over a bookkeeping gap) and **required** on an *increasing* stocktake
  adjustment (no silent zero there — an adjustment has no natural cost signal of its own the way
  an arrival's missing price at least has a documented precedent for).
- **`Inventory\Support\Money`** — a same-context copy of `Order\Support\Money` (round-half-away-
  from-zero), matching the existing per-context duplication convention.

### API

- `POST /stock-movements/arrivals` — `unit_cost` now optional (`numeric`, `gte:0`).
- `POST /stock-movements/adjustments` — `unit_cost` now `required_if:direction,increase`.
- No new endpoint for reading batches directly yet — read through `stock_batches`/
  `stock_batch_consumptions` tables or a future report.

---

## 3. Manufacturing job costing (`Order`)

### Database

**`manufacturing_cost_rates`** — admin-curated rate table, the same shape `business_fields`
already is.

| Column | Notes |
|---|---|
| `product_id` | Nullable — null is the **default/fallback** rate for a cost type |
| `cost_type` | `string(20)` → `ManufacturingCostType` (`labor` \| `machine_runtime` \| `overhead` \| `scrap_loss`) |
| `rate_per_unit` | `decimal(12,3)` |
| `is_active` | |

One rate per `(product_id, cost_type)`, and one default per `cost_type` — two partial unique
indexes. No effective-date history: a changed rate only affects orders costed after the change;
historical accuracy comes from the rate being **snapshotted** onto each entry it produces.

**`production_cost_entries`** — append-only cost ledger against an order/line, shaped exactly like
`order_payments`.

| Column | Notes |
|---|---|
| `order_id`, `order_item_id` (nullable) | `order_item_id` null is reserved for shared overhead not yet allocated to a line — nothing writes that shape today |
| `cost_type` | Same enum |
| `quantity`, `rate` | Null for a scrap-loss entry (FIFO-derived, not rate-derived) |
| `amount` | Force-filled, never client-typed |
| `reverses_entry_id` | Self-FK, mirrors `order_payments.reverses_payment_id` — voids without deleting |

**`order_items`** gained four nullable `decimal(14,2)` columns: `material_cost` (permanent
snapshot, force-filled once by `DeductOrderStock`), `labor_cost`/`overhead_cost` (cached sums,
`MachineRuntime` folds into `overhead_cost` — there is no third cache column for it), `cogs`
(= material + labor + overhead, null until `material_cost` is known).

**`orders`** gained `total_cogs` (cached sum of line `cogs`). Gross profit itself is **not**
stored — `Order::grossProfit()` computes `grand_total - total_cogs` from the two cached columns.

**`order_items`** also gained `fulfillment_stock_movement_id` — a forward pointer to the ledger
row a line's own deduction produced, needed by order-cancellation reversal (§5).

### Domain

- **`ApplyManufacturingRates`** — runs inside `ChangeOrderStatus`'s transaction alongside
  `DeductOrderStock`, guarded by the same first-entry-into-`printing` condition (a reprint does
  not re-cost, exactly like it does not re-deduct material — see §6 for the manual path). For each
  line, for each rate-driven cost type: looks up the product-specific rate, falling back to the
  default, **skipping** (never inventing a zero) if neither exists.
- **Quantity consistency**: `OrderItem::producedQuantity()` (`warehouse_quantity ?? quantity`) is
  the one basis both `DeductOrderStock`'s material draw and `ApplyManufacturingRates`' labour/
  overhead compute against — they were at risk of using two different physical quantities for the
  same line.
- **`RecalculateOrderItemManufacturingCost`** / **`RecalculateOrderItemCost`** /
  **`RecalculateOrderCogs`** — the same "one place a cached total is derived" pattern
  `RecalculateOrderPayments`/`RecalculateOrderTotals` already establish, one level for the line and
  one for the order.
- **`DeductOrderStock`** — now also reads back `material_cost` from the `stock_batch_consumptions`
  rows its own movement produced, and stamps `fulfillment_stock_movement_id`.

### API

New CRUD for the rate table, the same shape `BusinessFieldController` already is — list/create/
update/activate/delete/history, behind `manufacturing_cost_rates.view`/`.manage`:

```
GET/POST     /manufacturing-cost-rates
GET/PUT      /manufacturing-cost-rates/{id}
PATCH        /manufacturing-cost-rates/{id}/activation
DELETE       /manufacturing-cost-rates/{id}   — no in-use guard; nothing references a rate by FK
GET          /manufacturing-cost-rates/{id}/logs
```

`OrderItemResource` gained `material_cost`, `labor_cost`, `overhead_cost`, `cogs`. `OrderResource`
gained `total_cogs`, `gross_profit`.

---

## 4. Service (design) revenue — no schema change

`orders.design_fee` (already implemented, charged only when `design_source` is `in_house`) remains
the sole mechanism for service revenue. It carries no cost counterpart anywhere in this work — by
construction, design revenue is 100% margin in this model. The P&L report (§7) reports it as its
own line for exactly this reason.

---

## 5. Order cancellation reversal

If `orders.stock_deducted_at` is set and the order is later cancelled, `ReverseOrderStockDeduction`
(called from inside `ChangeOrderStatus`, same transaction) undoes what `DeductOrderStock` did:

- **New `MovementType::OrderReversal`** — its own type, not a reuse of `Adjustment`: a system
  correcting a cancelled order's deduction and an operator correcting a miscount are different
  events, and a report should be able to tell them apart without inspecting `reference_id`.
- **Credits back the *exact* batches each line drew from** — never a fresh averaged one. A new
  batch would stamp a fresh `received_at` on stock that was, by definition, among the oldest on
  the shelf (inverting FIFO), and blending several layers into one average is exactly the mixing
  FIFO exists to avoid. `OrderItem::fulfillment_stock_movement_id` is what makes this
  unambiguous per line.
- **Every production-cost entry the line carries is voided by a further entry pointing back at
  it** — never edited or deleted, same rule `order_payments` already follows.
- **`order_items.material_cost`/`labor_cost`/`overhead_cost`/`cogs` and `orders.total_cogs` are
  left untouched.** They are the historical record of what production actually cost before the
  write-off — the reversal is a separate accounting event, not a rewrite of what happened.

A line that never reached printing (no `fulfillment_stock_movement_id`) is silently skipped, not
refused.

---

## 6. Scrap / spoilage during production

Bags spoiled while producing a specific order's line — a misprint, a run gone wrong.

- **New `MovementType::ScrapLoss`** — source-only, the same shape as `OrderFulfillment`.
- **`POST /orders/{order}/items/{item}/scrap`** — behind `inventory.manage` (it draws stock and
  posts a FIFO cost the same way a fulfillment does, regardless of which controller the route
  lives on — the same split `PurchaseOrderController::receiveArrival()` already draws). Requires
  `notes` (spoilage explains nothing about itself). Refused with 422 before the order has reached
  printing — there is nothing to spoil yet, and no `fulfillment_warehouse_id` to draw from.
- **`RecordScrapLoss`** draws from the same warehouse the order's own fulfillment used, reads the
  cost back from the FIFO consumption the movement produced (the same trick `DeductOrderStock`
  uses), and writes a `production_cost_entries` row (`cost_type = scrap_loss`, no rate — it is
  FIFO-derived, not rate-driven).
- **Deliberately does not touch the line's own `material_cost`/`cogs`.** Scrap is a separate,
  visible loss on the cost ledger, not a rewrite of what the original fulfillment cost.

This is also the documented manual path for reprint cost that `ApplyManufacturingRates` does not
capture automatically (§3) — a reprint's extra material or press time is recorded here, by hand.

---

## 7. Profit & loss reporting

New **`App\Domain\Reporting`** context — queries only, no models of its own, `ReportingService`
as its front door.

**A deliberate, documented exception to "cross-context access goes through the Service."** This
context's entire purpose is cross-cutting read aggregation over figures three other contexts
already compute and cache; routing each number through a service call would not reduce coupling,
only relocate it. What it must not do — and does not — is re-derive any of those figures itself:
every aggregate is a `SUM` over an already-cached column (`items_total`, `total_cogs`,
`order_items.material_cost`/`labor_cost`/`overhead_cost`, `order_payments.amount`), never a
re-computation of a money rule that already has one home. The one exception — which orders'
`design_fee` actually counts as revenue — restates `design_source = 'in_house'` in SQL, the same
trade-off `Order\Support\PaymentStatusExpression` already makes for the same reason: a report
spanning every order in a period cannot load each one into PHP to ask one boolean question of it.

**Accrual, not cash, and the two are never netted against each other.** Revenue is recognised when
an order is `delivered` or `settled` (`COALESCE(delivered_at, settled_at)` inside the period).
`total_cogs` has no cash-basis counterpart — materials were already paid for separately, through
purchase orders — so gross profit is only ever computed against the accrual figures. Cash actually
collected in the same window (`order_payments`, `type = payment` only — a reversal never counts)
is reported alongside as a reconciliation figure, never subtracted from anything.

```
GET /reports/profit-loss?from=YYYY-MM-DD&to=YYYY-MM-DD
```

Behind its own `reports.pnl.view` permission — separate from `orders.view`, since this is the one
screen putting every order's revenue *and* cost side by side. Response shape:

```json
{
  "period": { "from": "...", "to": "..." },
  "revenue": { "product": "...", "service": "...", "total": "..." },
  "cost_of_goods_sold": { "material": "...", "labor": "...", "overhead": "...", "total": "..." },
  "gross_profit": "...",
  "cash_collected": "...",
  "orders_recognized": 0
}
```

---

## 8. New permissions

| Value | Group |
|---|---|
| `manufacturing_cost_rates.view` / `.manage` | معدلات تكلفة التصنيع |
| `reports.pnl.view` | التقارير المالية |

Scrap recording and the batch-costing changes to arrivals/adjustments reuse the existing
`inventory.manage`. Nothing was auto-granted to the seeded `Staff` role — same as `inventory.manage`
itself, this is the administrator's to hand out.

---

## 9. Where the code lives

```
backend/app/Domain/Inventory/
├── Support/Money.php                                    ← new
├── Enums/StockBatchSourceType.php                        ← new
├── Enums/MovementType.php                                ← touched, +OrderReversal, +ScrapLoss
├── Models/{StockBatch,StockBatchConsumption}.php          ← new
├── DTOs/{BatchDraw,StockChangeResult}.php                 ← new
├── DTOs/StockMovementData.php                             ← touched, +unitCost, +orderReversal(), +scrapLoss()
├── Exceptions/InsufficientBatchStock.php                  ← new
├── Actions/ApplyStockChange.php                           ← touched, batch-aware increase/decrease + relocateBatches/creditBack
├── Actions/{ConsumeStockBatchesFifo,CreditBackStockBatches}.php  ← new
└── Actions/RecordStockMovement.php                        ← touched, movement-first ordering, transfer/reversal branches

backend/app/Domain/Order/
├── Enums/ManufacturingCostType.php                        ← new
├── Models/{ManufacturingCostRate,ProductionCostEntry}.php  ← new
├── Models/{Order,OrderItem}.php                            ← touched, +total_cogs/grossProfit(), +producedQuantity()/fulfillment_stock_movement_id
├── DTOs/ManufacturingCostRateData.php                      ← new
├── Queries/ManufacturingCostRate{Filters,ListQuery}.php    ← new
├── Exceptions/{ScrapRequiresAnActor,OrderNotYetInProduction}.php  ← new
├── Actions/{Create,Update}ManufacturingCostRate.php        ← new
├── Actions/ApplyManufacturingRates.php                     ← new
├── Actions/Recalculate{OrderItemManufacturingCost,OrderItemCost,OrderCogs}.php  ← new
├── Actions/DeductOrderStock.php                            ← touched, +material_cost/+fulfillment_stock_movement_id
├── Actions/ReverseOrderStockDeduction.php                  ← new
├── Actions/RecordScrapLoss.php                             ← new
├── Actions/ChangeOrderStatus.php                           ← touched, wires all of the above into printing/cancellation
└── OrderService.php                                        ← touched, +rate CRUD, +recordScrapLoss

backend/app/Domain/Reporting/                               ← new context
├── ReportingService.php
└── Queries/{ProfitAndLossFilters,ProfitAndLossSummaryQuery}.php

backend/app/Domain/Audit/Enums/AuditSubject.php             ← touched, +5 cases
backend/app/Domain/Identity/Enums/PermissionName.php        ← touched, +4 permissions

backend/app/Application/Api/V1/
├── Controllers/{ManufacturingCostRateController,ProfitAndLossController}.php  ← new
├── Controllers/OrderController.php                         ← touched, +storeScrapLoss
├── Requests/Order/{Store,Update}ManufacturingCostRateRequest.php  ← new
├── Requests/Order/RecordScrapLossRequest.php                ← new
├── Requests/Reporting/ProfitAndLossReportRequest.php        ← new
├── Requests/Inventory/{RecordArrivalRequest,RecordAdjustmentRequest}.php  ← touched, +unit_cost
├── Resources/{ManufacturingCostRateResource,ProductionCostEntryResource}.php  ← new
└── Resources/{OrderItemResource,OrderResource}.php          ← touched, +cost fields

backend/database/migrations/2026_08_12_*.php  (8 files)
backend/database/factories/{StockBatch,StockBatchConsumption,ManufacturingCostRate,ProductionCostEntry}Factory.php  ← new
backend/database/factories/WarehouseStockFactory.php         ← touched, auto-opens a zero-cost batch on creation
backend/routes/api.php                                        ← touched, +manufacturing-cost-rates, +reports/profit-loss, +orders/{order}/items/{item}/scrap
```

---

## 10. Tests

- `tests/Feature/Inventory/StockBatchLedgerTest.php` — FIFO ordering across layers, zero-cost
  fallback on an uncosted arrival, the adjustment cost requirement, transfers spanning multiple
  layers, insufficient-stock rollback leaving batches untouched.
- `tests/Feature/Api/V1/ManufacturingCostRateTest.php` — rate CRUD, the default-vs-product-specific
  uniqueness pair, permission checks.
- `tests/Feature/Orders/ProductionCostTest.php` — material + labor + overhead landing on a line and
  the order together, a cost type with no rate being skipped not zeroed, product-specific rate
  beating the default, a reprint not re-applying rates.
- `tests/Feature/Orders/OrderCancellationReversalTest.php` — exact-batch credit-back (not
  averaged), production-cost entries reversed, the line's own cost columns left untouched.
- `tests/Feature/Orders/ScrapLossTest.php` — stock drawn and FIFO-costed, the line's material cost
  untouched, refused before printing, refused over-quantity, ownership scoping, permission check.
- `tests/Feature/Api/V1/ProfitAndLossReportTest.php` — revenue/service split, the chargeable-only
  design-fee condition, accrual date fallback (`settled_at` when `delivered_at` is absent), period
  and status exclusion, cash collected independent of recognised orders, a reversal not counting
  as cash.

Existing fixtures updated: `StockLedgerTest.php` and `StockMovementTest.php` gained `unit_cost` on
their increasing-adjustment cases; `WarehouseStockFactory` now opens a matching zero-cost batch
whenever it creates a balance directly, which is what kept ~15 pre-existing tests (`OrderWorkflowTest`,
`StockMovementTest`) passing once real batch consumption started running underneath them. Full
suite (1042 tests) passes; Pint and `scramble:analyze` are both clean.

---

## 11. Known gaps, deliberately not closed here

- **Designer labor costing** — `design_fee` stays 100% margin; costing designer hours would need
  its own rate/ledger mechanism, not requested.
- **Rate versioning** — `manufacturing_cost_rates` has no effective-date history. Changing a rate
  only affects orders costed after the change.
- **Automatic reprint/rework costing** — a reprint does not re-deduct material or re-apply
  manufacturing rates; extra cost from one is recorded manually via §6's scrap endpoint.
- **`ProductVariant` deletion has no stock-holding guard.** `SyncProductVariants` soft-deletes a
  variant dropped from a product's edit payload with no check against `warehouse_stocks` *or*
  `stock_batches` — unlike `DeleteWarehouse`, which refuses while a warehouse still holds stock.
  Pre-existing (predates this work, for `warehouse_stocks`), and not fixed here — it is a Catalog-
  context decision (what should happen: refuse the whole sync, or skip deleting that one variant?)
  outside the scope of what was asked.
- **`stock_arrival_items.stock_movement_id` traceability isn't wired onto `stock_batches`** — see
  §2's note on `stock_arrival_item_id`; would need `RecordStockArrival` reordered to create the
  arrival-item row before the movement it produces.
- **No dedicated per-order or per-batch reporting endpoint** beyond the period summary in §7 —
  `OrderResource` already exposes a line's own `cogs`/`gross_profit` for a single-order view.

---

Last updated: 2026-08-12.
