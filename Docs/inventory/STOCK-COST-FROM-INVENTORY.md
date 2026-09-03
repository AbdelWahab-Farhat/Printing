# Setting stock cost from inventory — design

> **Status: the backend is implemented; the app is not wired up.** Phases 1, 2, 3 and Phase 4's
> API half are built, tested and green. Phase 0 and the app-side of Phases 2–4 are **frontend
> work and deliberately untouched** — see
> [STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md](STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md).
>
> Companion docs: [COST-TRACKING-UNIT-CONVERSION.md](../costing/COST-TRACKING-UNIT-CONVERSION.md) for the
> batch-costing machinery this extends, [INVENTORY-STOCK-SCREEN.md](INVENTORY-STOCK-SCREEN.md),
> and [PROFIT-AND-LOSS-COST-TRACKING.md](../costing/PROFIT-AND-LOSS-COST-TRACKING.md) for where these
> numbers end up.

---

## 1. Why

Two gaps, both about a cost that was never recorded or was recorded wrong.

**Stock arrives outside a purchase order.** A storekeeper records a delivery or a stocktake
correction, and the cost layer that opens behind it has to be priced by hand — there is no vendor
document to read a price from.

**A cost that is already on the shelf turns out to be wrong.** The invoice arrives after the
goods at a different figure, or 3.5 was typed as 35, or the stock predates costing entirely and
is carried at zero.

That last case is not hypothetical. The
[opening-balance backfill](../../backend/database/migrations/2026_08_12_100200_backfill_opening_balance_stock_batches.php)
created one `unit_cost = 0` layer per shelf, stamped `1970-01-01` **deliberately** so it is
consumed before any correctly-costed layer. Every order drawing on that stock records
`material_cost = 0`: gross profit on those orders is overstated by the whole material cost, and
the P&L's `cost_of_goods_sold.material` understates by the same amount, until that stock is used
up.

---

## 2. What exists today

```
RecordStockMovement ──(one transaction, one row lock)──▶ ApplyStockChange
                                                            ├─ warehouse_stocks.quantity
                                                            └─ stock_batches (cost layers)
                                                                  │
                                        ConsumeStockBatchesFifo ──┤ oldest received_at first
                                                                  ▼
                                                     stock_batch_consumptions.total_cost
                                                                  ▼
                                        DeductOrderStock → order_items.material_cost (frozen)
```

**The invariant everything hangs on:** for any `(warehouse_id, stock_item_id)`,
`SUM(stock_batches.quantity_remaining) == warehouse_stocks.quantity`. `ApplyStockChange` is the
only code that writes either side, under one `lockForUpdate`, in one transaction — which is why
`StockBatch` is `#[Fillable([])]`. `StockBatchLedgerTest` enforces it.

**Four doors a cost can enter by, all at batch-creation time:**

| Door | `unit_cost` |
|---|---|
| Purchase order → `ReceivePurchaseOrder` → arrival line | the PO line's `final_unit_cost` (landed) |
| `POST /stock-arrivals` (vendor document, no PO) | `null` → layer opens at **`0.000`** |
| `POST /stock-movements/arrivals` | optional → **`0.000`** if omitted |
| `POST /stock-movements/adjustments` + `direction=increase` | **required** |

**And no door out.** Nothing updates `stock_batches.unit_cost` after the layer is opened.
Transfers relocate layers verbatim; reversals credit back the exact layers consumed. There is
**no read endpoint for batches at all** — no controller, no resource, no route — so nothing can
show a clerk what a shelf's layers cost or that one opened at zero.

---

## 3. Decisions

| Question | Decision |
|---|---|
| Which batches may be repriced? | By **consumption state**, not by cost. A zero cost is a symptom; a wrong cost is the commoner fault and must be correctable |
| Reprice part of a layer? | Yes — **split**, with `split_from_batch_id` recording the lineage |
| Which half is consumed first? | The **revalued** quantity |
| A batch that came from a purchase order? | **Warning, never a refusal** |
| Restate past orders? | **No.** Revaluation is prospective |
| A suggested cost when none is known? | **Offered, never applied** |

---

## 4. Phase 0 — the app sends the cost *(frontend — not built)*

**Nothing to build on the server: the API has accepted `unit_cost` since batch costing landed.**
What is missing is the app sending it.

`WarehouseRepository.recordArrival` and `recordAdjustment` do not, and `RecordAdjustmentRequest`
**requires** it on an increase — so «تسوية بالزيادة» from the app returns 422 every time, and
every arrival posted from the app opens its cost layer at `0.000`, quietly filling the uncosted
queue that Phase 2 now surfaces.

Specified in the frontend-integration doc. It is the cheapest of the five and the only one that
fixes a refusal staff are hitting today.

---

## 5. Phase 1 — make a batch traceable

**Migration** — `stock_batches` gains three nullable columns:

| Column | Why |
|---|---|
| `stock_movement_id` → `stock_movements`, `nullOnDelete` | The id is already in hand: `RecordStockMovement::moveBalances()` passes it to `decrease()` and simply not to `increase()`. Gives `batch → movement → reference_id → stock_arrival → purchase_order_id` — what makes the PO warning possible, and lets a list say «من توريد رقم ١٢» instead of showing anonymous layers |
| `split_from_batch_id` → `stock_batches`, `nullOnDelete` | The lineage |
| `revalued_at` | So a list can mark a layer «سُعِّرت يدوياً» without joining the audit trail |

`ApplyStockChange::increase()`/`openBatch()` take the movement id; `relocateBatches()` carries the
source batch's through, as it already does `received_at` and `source_type`.

**Existing rows stay NULL** and read as «غير معروف». No heuristic backfill — matching old batches
to movements by timestamp would be a guess presented as a fact.

`stock_arrival_item_id` already exists in the schema and is **never populated** (`RecordStockArrival`
creates the arrival line *after* the movement, so the id does not exist yet at batch-creation
time — a documented follow-up). `stock_movement_id` reaches the same document by one more hop and
covers every batch, not only the ones from a vendor document.

---

## 6. Phase 2 — let people see the layers

**`GET /stock-batches`**, behind `inventory.view`. One endpoint with filters rather than a nested
route per shelf, because the two questions asked of it differ only in scope:

| Query | Answers |
|---|---|
| `?warehouse_id=2&stock_item_id=7` | what one shelf's layers cost, in the order they will be drawn |
| `?uncosted=1` | **the work queue** — every layer at `0.000` with stock left, oldest first |
| `?remaining=0` | used-up layers, excluded by default: they cannot be repriced and are in no queue |

**Ordered `received_at, id` — the order FIFO consumes them**, which is the single most useful
fact on the screen: the layer at the top is the one the next order takes from. That is also what
makes `uncosted=1` a work list rather than a report; each row on it has a deadline.

Each layer carries the three flags the app draws its warnings from — `can_be_revalued`,
`is_partly_consumed`, `purchase_order_id` — rather than letting a client re-derive rules the
domain owns. The purchase order is resolved in **one subquery for the whole page**
(`batch → movement → arrival → order`), not a lookup per row.

---

## 7. Phase 3 — revalue, with an optional split

**One endpoint:** `PATCH /stock-batches/{batch}/cost`

```jsonc
{ "unit_cost": "3.500", "quantity": "100.000", "reason": "فاتورة المورد وصلت بسعر مختلف" }
```

`quantity` omitted → the whole remainder, no split. `quantity < quantity_remaining` → splits.
`quantity > quantity_remaining` → 422. One call, so a split can never be left dangling.

### The consumption gate

| State | Behaviour |
|---|---|
| Untouched (`remaining == received`) | Allowed — the correction is complete |
| Partly consumed | **Allowed.** The read endpoint flags it so the app warns «صُرف منها ٢٠٠ من ٥٠٠ — التصحيح يسري على المتبقي فقط» |
| Fully consumed (`remaining == 0`) | **Refused** — `BatchIsFullyConsumed`. Nothing left to reprice |

**A PO-linked batch is a warning, not a refusal.** The app says «هذه الدفعة من أمر شراء رقم ٧ —
التعديل قد يخالف سعر الفاتورة»; the server allows it. Refusing would exclude the commonest real
correction — the invoice disagreeing with the delivery note.

### The split — the revalued quantity stays on the original row

FIFO is `ORDER BY received_at, id`, so the original row always wins the tie. Rather than fight
that, the revalued quantity **stays on the original** and the *untouched remainder* splits off:

```
Before:  #40 — received 500, remaining 300 (200 consumed) @ 0.000

Revalue 100 @ 3.500:

#40 (original)  remaining = 100   received = 300   unit_cost = 3.500   ← consumed FIRST
                revalued_at = now
#41 (new)       remaining = 200   received = 200   unit_cost = 0.000   ← untouched remainder
                split_from_batch_id = 40
                received_at, source_type, stock_movement_id ← copied from #40
```

Why this shape:

- **`ConsumeStockBatchesFifo` is not touched at all** — no ordering column, no third term in the
  `ORDER BY`, no change to the one query the whole costing system depends on.
- **`received_at` keeps meaning the age of the stock.** Nudging a timestamp to force order would
  make a layer claim to be older than it is, and successive splits would walk it past genuinely
  older stock on the same shelf.
- **The invariant holds by construction:** 100 + 200 = the 300 that was there.
  `warehouse_stocks.quantity` is untouched, because no quantity moved.
- **The arithmetic stays honest on the parent:** `received − remaining` = 200, exactly what its
  consumption rows record. The consumed quantity stays with the row that holds its consumptions.

**Locking:** `RevalueStockBatch` calls `ApplyStockChange::lockBalance()` on the
`(warehouse, stock_item)` row **before touching any batch row** — same lock, same order as every
other write in this domain. Without it a revaluation can interleave with a fulfillment drawing on
the same layer.

### The revaluation ledger

**New table `stock_batch_revaluations`:** `stock_batch_id`, `quantity`, `old_unit_cost`,
`new_unit_cost`, `reason`, `user_id`, timestamps, soft deletes.

A revaluation changes the book value of inventory with **no physical event behind it**, and the
audit trail records columns changing rather than why. This is where the reason lives, and it is
the only thing that could ever answer «كم رفعنا أو خفّضنا قيمة المخزون هذا الربع؟». `reason` is
required, `min:3` — the same demand `RecordAdjustmentRequest` already makes of an adjustment, for
the same reason.

### Permission

`inventory.revalue` — «تعديل تكلفة دفعة مخزون», its own grant. Changing the book value of stock
without touching a shelf is a different trust level from recording a transfer.

---

## 8. Phase 4 — a suggested cost, offered not applied

The arrival form's cost box starts **empty**, with a chip beneath it:

```
آخر سعر معروف: ٣٫٥٠٠ د.ل / كغم — توريد ١٢ أغسطس        [ استخدامه ]
```

Tapping fills the box. Not tapping leaves it empty, the layer opens at `0.000`, and it lands in
the uncosted queue.

- **The tap is the confirmation** — no dialog, one gesture, and a cost in the database is always
  something a person chose.
- **No provenance column is needed.** A pre-filled box would require a `cost_source` flag to tell
  decided costs from inherited ones; an empty box makes that unnecessary.
- **The date and source are shown, not just the number.** A six-month-old price should look six
  months old, so the storekeeper makes a judgement instead of accepting a figure.

Applied silently on the server this would be actively harmful: zero-cost layers would stop
appearing, and the only signal that anybody was meant to price the stock would be gone.

**API — built.** `last_known_unit_cost` on `GET /stock-items/{id}`:

```jsonc
"last_known_unit_cost": {
  "unit_cost": "3.500",
  "received_at": "2026-08-12T09:00:00+00:00",
  "source_type_label": "توريد"
}
```

The most recently *received* layer carrying any cost at all, across every warehouse — the shelf a
delivery happens to land on says nothing about what the material is worth. Null when nothing was
ever priced, which is exactly when there is nothing to suggest; a zero-cost layer is the absence
of a price, not a price of zero.

**On the single-item response only.** It is a `latestCostedBatch` relation loaded by
`StockItemController::show()`, so a fifteen-row listing does not run fifteen queries to draw a
hint no list shows.

---

## 9. Files

**New**

- `app/Domain/Inventory/Actions/RevalueStockBatch.php`
- `app/Domain/Inventory/Models/StockBatchRevaluation.php`
- `app/Domain/Inventory/Exceptions/BatchIsFullyConsumed.php`
- `app/Domain/Inventory/Exceptions/RevaluationExceedsRemaining.php`
- `app/Domain/Inventory/Queries/StockBatchListQuery.php`, `StockBatchFilters.php`
- `app/Application/Api/V1/Controllers/StockBatchController.php`
- `app/Application/Api/V1/Resources/StockBatchResource.php`
- `app/Application/Api/V1/Requests/Inventory/RevalueStockBatchRequest.php`
- `database/migrations/2026_09_01_110000_add_traceability_and_revaluation_to_stock_batches_table.php`
- `database/migrations/2026_09_01_110100_create_stock_batch_revaluations_table.php`
- `tests/Feature/Inventory/StockBatchRevaluationTest.php` — 20 cases

**Changed**

- `ApplyStockChange` — `increase()`/`openBatch()` take the movement id; `relocateBatches()` carries it
- `RecordStockMovement` — passes the movement id into `increase()`
- `ConsumeStockBatchesFifo` / `BatchDraw` — carry `stockMovementId` so a transfer preserves it
- `StockBatch` — two relations, four predicates (`consumedQuantity`, `isPartlyConsumed`, `isFullyConsumed`, `isUncosted`), `revalued_at` cast
- `StockItem` — `latestCostedBatch()`; `StockItemResource` — `last_known_unit_cost`; `StockItemController::show()` loads it
- `InventoryService` — `paginateStockBatches()`, `revalueStockBatch()`
- `PermissionName` — `RevalueStock = 'inventory.revalue'`
- `AuditSubject` + `AuditAttributeLabels` — the revaluation and the three new batch columns
- `routes/api.php` — two routes

---

## 10. Verification

```bash
php artisan migrate
php artisan test --filter=StockBatch     # 20 revaluation + 8 ledger cases
./vendor/bin/pint
```

**On this machine** the project needs PHP ≥ 8.4.1 and the `php` on `PATH` is XAMPP's 8.2.12,
which refuses to boot the autoloader. Use `~/.config/herd/bin/php84/php.exe artisan …`.

---

## 11. What this does to orders already in the system

**Nothing already fulfilled moves. Everything not yet fulfilled will cost more — correctly — and
reported profit will fall.**

**Not affected.** Stock leaves on first entry into «جاهزة للطباعة» or «جاهزة»
(`ChangeOrderStatus`), and `material_cost` is frozen there from `stock_batch_consumptions`.
Revaluation is prospective and never rewrites a consumption, so `order_items.material_cost`,
`orders.total_cogs`, gross profit and every past P&L period are untouched. `warehouse_stocks`,
`stock_movements`, `stock_batch_consumptions`, `order_items` and `orders` gain no columns.
Arrivals, transfers, fulfillments, reversals, scrap and `RestateOrderStockDeduction` keep working
— they read `quantity_remaining` and `received_at`, both of which the split preserves.

**Affected on purpose.** Orders not yet at «جاهزة للطباعة» record the corrected cost when they
deduct. And **reported gross profit will drop, visibly**: pricing the zero-cost layers raises
`cost_of_goods_sold.material` and lowers gross profit on new orders. This is a correction, not a
regression — today's numbers are wrong in the flattering direction — but whoever reads the P&L
should be told before they notice it.

**One narrow consequence.** The original row carries the new cost while consumptions already
recorded against it happened at the old one. If such an order is cancelled,
`CreditBackStockBatches` returns that quantity to the same batch — now valued differently — so
inventory book value moves with no purchase behind it. It fires only on cancellations of orders
that ran before a correction, and the new value is arguably the right one.

---

## 12. Order of work

| Phase | Backend | App |
|---|---|---|
| 0 — send the cost on the way in | nothing to do; the API already accepts it | **outstanding, and a live 422** |
| 1 — traceability | ✅ built | n/a |
| 2 — read the layers | ✅ built | outstanding |
| 3 — revalue with split | ✅ built | outstanding |
| 4 — suggested cost | ✅ `last_known_unit_cost` | outstanding |

The app-side work is specified in
[STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md](STOCK-COST-FROM-INVENTORY-FRONTEND-INTEGRATION.md).
Phase 0 is worth doing first there too: it needs no new screen and fixes a refusal staff are
hitting today.
