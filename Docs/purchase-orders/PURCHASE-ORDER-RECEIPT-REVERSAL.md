# Undoing a receipt entered in error

> **Implemented.** Everything below is what was actually built — schema, domain layer, API,
> permissions, and the frontend contract. Nothing here is a proposal.
>
> Companion docs: [PURCHASE-ORDERS-DESIGN.md](PURCHASE-ORDERS-DESIGN.md) for the order itself,
> [STOCK-COST-FROM-INVENTORY.md](../inventory/STOCK-COST-FROM-INVENTORY.md) for the cost layers
> this unwinds.

---

## 1. Why

A storekeeper types 500 where he meant 50, or receives a lorry against the wrong order. Until
now the only correction was a stocktake adjustment (`POST /stock-movements/adjustments`), and it
fixes the shelf while quietly corrupting the book:

- the adjustment draws **FIFO**, so it eats the *oldest* cost layer on the shelf — often bought
  at a different price — while the erroneous layer stays put and is sold to a customer later at
  the wrong cost;
- the purchase order stays `completed` with `quantity_received = 500`, so the vendor's paperwork
  and the shelf disagree permanently;
- an investor's deal goes on showing stock it never had.

Reversal fixes all four at once, for as long as fixing them is still possible.

---

## 2. The rule

> **A receipt may be taken back for 24 hours after it was posted, and only while none of the
> stock it brought in has been touched.**

The two halves are deliberately different in kind, and the distinction is the whole design:

| | Kind | Waivable? |
|---|---|---|
| Within 24 hours of the receipt | **Policy** — own up to a mistake the same day | **Yes**, by `purchase_orders.reverse_receipt_any_time` |
| Nothing drawn from the arriving layers | **Arithmetic** | **No.** Not by any grant, at any age |
| No layer repriced by hand | Protects somebody else's judgement | No |
| The receipt not already reversed | | No |

A layer nobody has touched is exactly as safe to withdraw on the third day as on the first — so
the clock protects discipline, not the ledger. Once a single unit has left, its cost is already
sitting in an order's COGS where no reversal reaches it, and there is no arithmetic that puts it
back. Past that point the honest correction is the stock adjustment, which *writes the difference
off* rather than pretending the receipt never happened.

### The anchor is the receipt, never the purchase order

The clock starts at `stock_arrivals.created_at`. Anchoring it to when the PO was issued would
expire the window before any stock existed — an order sent on the 1st whose lorry arrives on the
9th would land with its window seven days shut.

### "Nothing drawn on" is tested against the consumption rows

Not against `quantity_remaining`. A layer drawn for an order that was later cancelled is credited
back to *that same layer* by `CreditBackStockBatches`, so its remainder equals what it received
again and it looks pristine — while having a real history of movement behind it.
`stock_batch_consumptions` rows are never edited or deleted, so «هل مُسَّت هذه الدفعة يوماً» is
the question with a truthful answer.

---

## 3. What it does

One transaction, all of it or none:

| | Before | After |
|---|---|---|
| `warehouse_stocks.quantity` | 500 | 0 |
| the arrival's `stock_batches.quantity_remaining` | 500 | 0, with a `stock_batch_consumptions` row explaining it |
| `stock_movements` | one `purchase_arrival` | plus one `arrival_reversal`, `reverses_movement_id` → the arrival |
| `purchase_order_items.quantity_received` | 500 | 0 |
| `purchase_orders.status` | `completed` | `arrived` |
| `stock_arrivals` | stands | kept, stamped `reversed_at` / `reversed_by` / `reversal_reason` |

**Nothing is deleted.** The arrival, its lines, the movements and the layers all stay exactly
where they are — the document is annotated, never rewritten. Re-receiving is a *new* arrival, not
an un-reversal of this one, which is why the order goes back to `arrived` rather than `new`: a
shipment demonstrably turned up against it, and it is open to be received correctly.

**It does not draw FIFO.** `WithdrawArrivalStockBatches` takes back the exact layers the arrival
opened, found by `stock_batches.stock_movement_id`, scoped to the arrival's own warehouse — that
column is deliberately copied onto layers an internal transfer recreates elsewhere, so it does
not identify a layer on its own.

**Investor money is not touched.** Cash moves when a deal is *funded*; stock is bought off the
investor when it *leaves the shelf*. A receipt entered in error sits between the two — the goods
never left — so there is nothing owed to unwind and the wallet must not twitch. The deal stays
open, waiting for the lorry to be received again.

`DealStockPosition` needed no change to agree: it buckets draws as sold / damaged / short by
movement type, and `arrival_reversal` is none of the three, so the withdrawal is skipped. Since
`quantity_received` there is *derived* (`remaining + sold + damaged + short`), a reversed receipt
reads «وصل ٠» on the deal screen — which is the truth.

---

## 4. Database

**`stock_arrivals`** — `2026_09_06_100300_add_reversal_to_stock_arrivals_table`

| Column | Type | Notes |
|---|---|---|
| `reversed_at` | timestamp, nullable | null on every receipt that stands |
| `reversed_by` | FK → `users`, nullable, `nullOnDelete` | |
| `reversal_reason` | string(500), nullable | required by the request, not by the column |

CHECK `stock_arrivals_reversal_is_whole`: `reversed_at` and `reversal_reason` are both set or
both null. `reversed_by` is deliberately outside the pair — it is `nullOnDelete`, so a departed
employee's row legitimately clears it years later while the audit trail still names them.

No new column records that a *movement* was reversed: `stock_movements.reverses_movement_id` and
its partial UNIQUE already existed, and are what make a second withdrawal against the same
arrival a database error rather than a silently halved shelf.

---

## 5. API

### `POST /purchase-orders/{purchase_order}/receipt-reversal`

Guarded by **`inventory.manage`** — the same grant that posted the receipt. Undoing one is the
same job on the same document, and whoever can put stock on a shelf by mistake must be able to
take it back off. `purchase_orders.manage` does not open this door, exactly as it does not open
the receiving one.

```json
{ "reason": "سُجّلت الكمية خطأً — ٥٠٠ بدل ٥٠" }
```

`reason` is **required** (3–500 chars). A stock correction nobody has to account for is precisely
what this feature exists to prevent. `reversed_by` is stamped from the authenticated user and is
never read from the body.

Returns the reopened order as `PurchaseOrderResource` (`200`).

| Failure | Status | Exception |
|---|---|---|
| No receipt on this order to undo | 422 | `PurchaseOrderReceiptNotReversible` |
| Already reversed | 422 | `StockArrivalAlreadyReversed` |
| Past 24 hours, without the override | 422 | `StockArrivalReversalWindowClosed` |
| Something already drawn from the layers | 422 | `ArrivalBatchAlreadyDrawnOn` |
| A layer repriced by hand | 422 | `ArrivalBatchWasRevalued` |
| Lacks `inventory.manage` | 403 | — |

### New permission

`purchase_orders.reverse_receipt_any_time` — «التراجع عن استلام شحنة بعد انتهاء مهلة الـ٢٤ ساعة».
Its own grant rather than part of `inventory.manage`, the same reasoning `inventory.revalue`
carries. **It waives the clock and nothing else.** It does not grant access to the endpoint; the
controller reads it off the caller to decide only whether the window applies.

### Reading the affordance

`GET /purchase-orders/{id}` gains two fields, computed against the **asking user's** grants:

| Field | Meaning |
|---|---|
| `receipt_reversible_until` | ISO-8601 deadline, or `null` if the order has no live receipt |
| `can_reverse_receipt` | whether *this* caller may undo it right now |

So the manager sees the button on day three and the storekeeper does not. Both fields are absent
from the list endpoint — it has no button to draw.

They answer the window and the grant only, not the three arithmetic guards: pre-empting those
would mean reading every line's cost layers on every order in a list, to save a refusal the API
already gives clearly. The button being offered and the act refused is honest; the button being
hidden on a perfectly reversible receipt would not be.

### `StockArrivalResource`

Gains `reversed_at`, `reversal_reason`, `reversed_by` and `reversed_by_user`, so a shipment
screen can say «مُلغى: سُجّلت الكمية خطأً» instead of quietly not showing the document at all.

---

## 6. Where the code lives

Dependencies run one way — `PurchaseOrder` → `Vendor` → `Inventory` — exactly as the receive path
does.

| Module | What it owns |
|---|---|
| **Inventory** | `MovementType::ArrivalReversal`, `StockMovementData::arrivalReversal()`, `ApplyStockChange::withdrawArrival()`, `WithdrawArrivalStockBatches`, and the two guards no grant waives |
| **Vendor** | `ReverseStockArrival` — the 24-hour window (`WINDOW_HOURS`, `windowClosesAt()`), the document stamp, and one ledger movement per line through `InventoryService` |
| **PurchaseOrder** | `ReversePurchaseOrderReceipt` — its own paperwork only: `quantity_received` back down, status back to `arrived`. It knows none of the guards |
| **Application** | one route, one FormRequest, one controller method, two resource fields |

The window lives in one constant, read by one method, which the resource also reads — so changing
24 to anything else is a single line, and the screen follows automatically.

---

## 7. Tests

- `tests/Feature/Api/V1/PurchaseOrderReceiptReversalTest.php` — 13 tests: the full unwind, the
  edge of the window, past the window, the manager's override, the manager still refused once one
  unit has been drawn, no double reversal, no receipt to undo, the reason requirement, the
  permission split, the batch-ledger invariant across a reversal, and the per-caller affordance.
- `tests/Feature/Investors/FundPurchaseOrderTest.php` — the funded lorry: the deal's layer goes
  back to zero, the deal stays open, and not one dinar moves.
