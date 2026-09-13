# Partial delivery — التسليم الجزئي

> **Status: proposal.** Branch `feat/partial-delivery`. Nothing is implemented yet.
> Written in English by request; the shipped code and UI strings stay Arabic like the rest.
> Answers the BACKLOG item **«تعديل البنود عند الاستلام»**, whose open question was explicitly
> accounting rather than technical. This document proposes the accounting answer, lists the
> options that were live, and says which one is recommended and why.

---

## 1. The problem

A customer comes to the counter (or the courier arrives) and takes **part** of the order. 500
bags were made; they take 300 and leave 200.

Today the system has no word for that. `Delivered` is a single, near-final event that hands over
"the order". The two facts the shop needs recorded — **what did the customer actually take**, and
**what happened to the rest** — have nowhere to live.

The rest of the goods can only go two ways, and which one is not a judgement call:

| The line's production mode | What the leftover physically is | Where it goes |
|---|---|---|
| `none` — سادة, plain goods off a shelf | Ordinary saleable stock | **Back to the warehouse** |
| `in_house` — printed here | Bags carrying this customer's artwork | **A loss.** Nobody else can buy them |
| `outsourced` — وسيط, a vendor made it | Same: made to this order | **A loss** |

That is the rule the owner stated, and it is already expressible: `ProductionMode` is on the
product's category, and `OrderItem::isPrinted()` already asks that question per line for سعر
السادة. Nothing new has to be invented to know which branch a line takes.

**Per line, not per order.** `ResolveOrderFlow` puts a whole order on the printed road for one
printed line among five plain ones — right for the road, wrong for the goods. A mixed order must
restock its plain lines and write off its printed ones in the same breath. So the branch is read
from `OrderItem::isPrinted()` (already per line), never from `orders.production_flow`.

---

## 2. What already exists, and is not being rebuilt

This is most of the design. The feature is largely an assembly of parts that are already
load-bearing.

| Existing thing | What it already does for us |
|---|---|
| `OrderItem::billableQuantity()` | `quantity − shortage_quantity`, floored at 0. The **one place** a quantity becomes money. One more subtrahend and the whole invoice follows. |
| `OrderItem::deriveLineTotal()` | Never re-quotes `unit_price` for the smaller quantity. Exactly the rule we want: delivering less must not raise the per-bag price. |
| `RestateOrderStockDeduction` | Reverse-the-whole-movement-then-redraw-the-corrected-quantity. This **is** partial stock return, already written, already handling FIFO layers, investor re-posting and the singular `fulfillment_stock_movement_id`. |
| `TransitionFields` | Server-described per-line number fields, already used by نواقص and by the ready deduction. The app renders them with **no Dart release**. |
| `ProductionCostEntry` + `ManufacturingCostType` | A per-line, reversible, audited cost ledger with a free-text `cost_type varchar(20)` — no DB constraint to migrate. `ScrapLoss` is the precedent for a *named, non-additive* loss row. |
| `RefundOrderPayment` / `PaymentStatus::Overpaid` | A customer who paid 500 and takes 300 is already a solved case. No new work. |
| `ReverseOrderStockDeduction` | Reverses **every** active production-cost entry on a line, so a new cost type is cancelled and deleted correctly for free. |
| `OrderProfitFinalised` ordering | Dispatched last in `ChangeOrderStatus`, after totals and COGS. The investor split will see the corrected figures without being touched. |

---

## 3. The decisions — options, and the recommendation

### Decision 1 — Is the customer billed for what they left?

| | Option | Consequence |
|---|---|---|
| **A** ✅ | **No. The invoice follows what was handed over.** | Revenue falls. For a printed line, COGS stays whole, so the shop eats the full cost — which is precisely "a loss in the P&L". |
| B | Yes for printed lines (it was made to their artwork, their problem), no for plain ones. | Then there is **no loss to report** on printed lines — the question the owner asked would have no answer. Also splits the rule across two branches for no gain. |
| C | Ask per line at the counter. | Maximum flexibility, maximum arguing at the till, and an invoice nobody can reconstruct later. |

**Recommendation: A.** It is what makes the requested P&L loss exist at all, and it is the rule
the codebase already committed to for نواقص — «النقص ذنبنا لا ذنب العميل». If the shop later
wants to charge for abandoned printed goods, that is a *charge* on the order
(`additional_cost` already exists with a reason code), not a redefinition of the invoice.

### Decision 2 — Does the loss add to COGS, or is it only named?

The P&L computes gross profit as `revenue − COGS`, where COGS is the cached
`order_items.material_cost_actual / labor_cost / overhead_cost` frozen at «جاهزة».

Worked example — 300 printed bags at 1.55, cost 300.00, customer takes 200:

| | Before | After partial delivery |
|---|---|---|
| Revenue | 465.00 | **310.00** |
| COGS | 300.00 | **300.00** (we made 300 bags; that is a fact) |
| Gross profit | 165.00 | **10.00** |

The 155.00 lost is *already* in the statement, by construction — revenue fell while cost did not.

| | Option | Consequence |
|---|---|---|
| **A** ✅ | The `delivery_loss` entry is a **named, non-additive memo** — a new reported line on the P&L beside `write_offs`, not a new subtrahend. | Correct arithmetic. Follows `ScrapLoss`, which is deliberately excluded from `labor_cost`/`overhead_cost` for this exact reason. |
| B | Add it to COGS. | **Double-counts.** The 100 undelivered bags' cost would be charged twice: once inside the frozen `material_cost`, once as the loss row. Gross profit goes wrong. |

**Recommendation: A.** And a small honest note that follows from it: **`ScrapLoss` is invisible on
the P&L today** for the same structural reason. Whatever new reported-loss line this feature adds
should carry scrap too, or the report will name one kind of loss and stay silent about the other.

### Decision 3 — What is the loss *valued* at?

| | Option | Reads as |
|---|---|---|
| **A** ✅ | Its share of the line's COGS: `cogs × undelivered ÷ quantity` | «قيمة البضاعة التي صنعناها ولم تُبَع» — what the goods cost us. |
| B | Its foregone revenue: `unit_price × undelivered` | The margin we didn't earn. Already visible as the revenue drop; reporting it again as a "loss" double-tells the same story. |

**Recommendation: A** — cost, not price. A loss line on a cost statement is a cost.

### Decision 4 — Where is it recorded, given the item lock?

`Order::itemsAreEditable()` is false from «جاهزة» onward, and must stay so.

| | Option | |
|---|---|---|
| **A** ✅ | **A new derived column, written by its own action** — exactly how `warehouse_quantity` is written onto locked lines at «جاهزة», and how `shortage_quantity` moves money without `quantity` ever being touched. | The lock is not in the way; it guards `UpdateOrder`, not every write. |
| B | Open the lock at delivery and edit `quantity`. | Destroys the record of what the customer ordered — the very question a partial delivery is the answer to. Also makes the invoice unreconstructable. |
| C | Leave the lines alone, post a credit note in the payment ledger. | The other half of the BACKLOG question. Rejected: it hides the *quantity* fact in a money row, and the goods still have to be restocked or written off, which needs a per-line quantity anyway. |

**Recommendation: A.** It is the pattern this codebase already uses twice, and it keeps the whole
thing reversible by construction: clear `undelivered_quantity` and the invoice returns to what it
was, because nothing was ever subtracted in place.

### Decision 5 — Who is allowed to do it?

Recording a partial delivery **moves money** (it shrinks the invoice). `orders.status.delivered`
is held by anyone who can hand a parcel over, including a driver.

**Recommendation: a new permission `orders.partial_delivery`**, and — following the precedent of
the payment box in `TransitionFields::money()` — **withhold the fields, not the move**. A driver
without it delivers the order in full, exactly as today; a clerk with it sees the per-line boxes.

### Decision 6 — The restocked quantity, when the units differ

A line sold by the piece and stocked by the kilo has no meaningful per-piece weight —
`DeductOrderStock` says so at length and refuses to multiply one out.

**Recommendation:** ask. The delivered quantity is asked in the **pricing** unit (the number the
clerk has). For a restocked line whose `isStockedInAnotherUnit()` is true, a **second** box asks
the returned amount in the **stock** unit, pre-filled with the pro-rata as a *suggestion* the
storekeeper can correct on the scale. Where the units agree, nothing extra is asked and the
return is exact arithmetic.

---

## 4. The mechanism

### 4.1 One new column

```
order_items.undelivered_quantity   decimal(12,3) nullable
```

In the line's own **pricing** unit. Null means "took it all" — «nothing recorded» is not
«nothing left», the same distinction `shortage_quantity` already makes.

Nothing else is stored. The disposition is not a column: it is `isPrinted()`, asked at the moment
of delivery and recorded implicitly by *which* of the two things happened — a stock movement, or
a loss entry. Both are rows with dates on them.

### 4.2 One line changed in the money rule

```php
// OrderItem::billableQuantity()
quantity − shortage_quantity − undelivered_quantity     // floored at 0
```

Everything downstream follows with no further edits: `deriveLineTotal()`, `RecalculateOrderTotals`,
`grand_total`, `remainingAmount()`, `PaymentStatus`, the invoice message, and the investor split
(which reads `grand_total − total_cogs`).

### 4.3 Plain lines — restock

Reuse the `RestateOrderStockDeduction` mechanism: reverse the line's whole fulfillment movement,
re-draw the delivered quantity fresh. The leftover lands back on its **original cost layers**,
`material_cost` comes out right for the smaller draw, and `fulfillment_stock_movement_id` stays
singular so delete/restore/cancel keep working untouched.

The class is currently hard-wired to "lines stocked in another unit, at «جاهزة»". Extract the
reverse-and-redraw into a shared collaborator and give it a second caller rather than copying it —
one FIFO-unwinding path in the codebase, as today.

`OrderStockDrawn` fires as it already does for a restatement, so the investor's purchase is
unwound and re-posted for the smaller draw. He is un-paid for bags that came back. Correct, and
free.

### 4.4 Printed and outsourced lines — write off

One `ProductionCostEntry` per affected line:

```
cost_type  = ManufacturingCostType::DeliveryLoss   // new case, 'delivery_loss'
quantity   = undelivered_quantity
rate       = null                                   // like ScrapLoss — not rate-driven
amount     = cogs × undelivered ÷ quantity
notes      = «تسليم جزئي — لم يستلمه العميل»
```

**Not summed into `labor_cost`/`overhead_cost`** — Decision 2. `isRateDriven()` returns false for
it, and `RecalculateOrderItemManufacturingCost` ignores it exactly as it ignores `ScrapLoss` today.

Nothing moves in the warehouse. The goods left the shelf at «جاهزة» and are gone.

### 4.5 The form

Added to `TransitionFields::for()` on the move into `Delivered`, gated on the new permission:

- Per line: **«المُستلَم من {size} ({unit})»** — a `number`, `max = billableQuantity()`,
  pre-filled with the full billable quantity. The common case (took everything) is one tap.
- Per restocked line whose units differ: **«المُعاد إلى المخزن ({stock unit})»**, pre-filled with
  the pro-rata.
- A server-built hint per line naming what will happen to the remainder — «يعود إلى المخزن» or
  «يُسجَّل خسارة» — built the same way `deductionPreview()` is, so it cannot drift from the action.

`Delivered` is reachable from «استلام مكتب», «جاري التوصيل» and «مرتجع من المكتب». One target,
so all three roads get it with no extra branching.

### 4.6 Ordering inside `ChangeOrderStatus`

The write must land **before** `OrderProfitFinalised` (so the investor split sees the corrected
profit) and **after** the status attributes are saved. Concretely, a new block beside the existing
`restateStock` branch, then `RecalculateOrderTotals` and `RecalculateOrderCogs`.

**One known wrinkle, named rather than hidden.** `recordPaymentForOrder()` runs *early*, and the
payment box's `max` was built from `remainingAmount()` before the clerk typed anything. A clerk
who takes payment in the same move can therefore pay against the **pre-partial** remainder and
leave the order `overpaid`. That is already a solved state (`RefundOrderPayment`), but the
mitigation is worth building: move the partial-delivery write **above** the payment so the ledger
sees the corrected total, and say so in the money field's hint.

### 4.7 The P&L

A new reported line, beside `write_offs` and on the same reconciliation shelf — **reported, never
subtracted** (Decision 2):

```
'losses' => [
    'partial_delivery' => …,   // sum of active delivery_loss entries in the window
    'scrap'            => …,   // ← the existing gap, closed in the same change
],
```

Summed over active (non-reversed, non-reversing) entries on orders recognised in the window, which
is the query `RecalculateOrderItemManufacturingCost::activeEntriesFor()` already writes.

---

## 5. What this does **not** do

- **No return policy after delivery.** «تم الاستلام» stays final. A customer coming back tomorrow
  is the separate deferred BACKLOG item, and still needs a credit-note design.
- **No line added or removed at the counter.** Only quantities taken are recorded. A customer
  wanting a *different* product is a new order.
- **No re-quoting.** 300 ordered at the 300-tier price, 200 taken — still the 300-tier price.
- **No change to `quantity`, `material_cost` on written-off lines, or `total_cogs` semantics.**

---

## 6. Slices

Each slice is shippable and testable on its own; 1–3 are the whole feature for a shop that only
sells سادة, and 4–5 are the whole feature for a printing shop.

| # | Slice | Where |
|---|---|---|
| 1 | `undelivered_quantity` column + `billableQuantity()` + `OrderItemResource` + backfill-free migration | backend |
| 2 | `RecordPartialDelivery` action (writes the column, re-derives `line_total`, calls `RecalculateOrderTotals`) | backend |
| 3 | Restock path: extract the reverse-and-redraw collaborator out of `RestateOrderStockDeduction`, second caller, `OrderStockDrawn` | backend |
| 4 | Write-off path: `ManufacturingCostType::DeliveryLoss` + the per-line entry + `isRateDriven()` | backend |
| 5 | `TransitionFields` on `Delivered` + `orders.partial_delivery` permission + `ChangeOrderStatus` wiring and ordering | backend |
| 6 | P&L `losses` section — partial delivery **and** the existing scrap gap | backend |
| 7 | Order detail: «غير مُستلَم» per line beside «ناقص», and the loss figure | frontend |
| 8 | P&L screen: the new losses rows | frontend |
| 9 | Seeder grant for the new permission + `openapi.json` regen | both |

**The status-change form itself needs no Dart at all** — the app renders server-described `number`
fields already. Slices 7 and 8 are display only.

### Tests to write

- `billableQuantity()` with shortage and undelivered together, and the floor at zero.
- A mixed order: one سادة line restocked, one printed line written off, in one move.
- The restock lands on the **original** cost layers (assert `material_cost`, not an average).
- Cancel, then delete, then restore an order that was partially delivered — the movement pointer
  and the loss entries survive the round trip.
- Investor split on a partially delivered order: slice falls, purchase for returned goods unwound.
- The permission: a driver without `orders.partial_delivery` is offered the move and not the fields.
- P&L: revenue falls, COGS does not, the loss line reports and does not subtract.

### Rough size

Backend slices 1–6 are the bulk of it, and slice 3 is the one with real risk (FIFO). Frontend 7–8
are small. Slice 3 should be built and tested before 5 is wired, so that a half-finished restock
can never be reachable from a screen.

---

## 7. Open questions for the owner

1. **Decision 1** — confirm the customer is not billed for what they leave, on printed lines too.
2. **Decision 3** — the loss is valued at cost. Confirm, or say it should be at selling price.
3. **Decision 5** — should recording a partial delivery need its own permission, or is
   `orders.status.delivered` enough?
4. Should a partially delivered order be visibly **flagged** in the orders list (a chip, like
   «نواقص»), or is the line-level figure on the detail screen enough?
5. Should `ScrapLoss` join the new P&L losses section in this change, or be left as it is?
