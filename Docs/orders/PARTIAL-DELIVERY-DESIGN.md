# Partial delivery — التسليم الجزئي

> **Status: approved, not yet built.** Branch `feat/partial-delivery`.
> Written in English by request; the shipped code and UI strings stay Arabic like the rest.
> Answers the BACKLOG item **«تعديل البنود عند الاستلام»**, whose open question was explicitly
> accounting rather than technical.
>
> **Every decision in §3 is settled** — all eight were answered on 14 September 2026. The
> options are kept beside each answer rather than deleted: a decision is only readable next to
> the ones it beat, and two of these went against the recommendation.

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

## 3. The decisions — settled, with the options they beat

| # | Question | Answer |
|---|---|---|
| 1 | Billed for what they left? | **No** — the invoice follows what was taken, printed lines included |
| 2 | Loss added to COGS? | **No** — reported beside `write_offs`, never subtracted |
| 3 | Loss valued at? | **Cost** of the goods |
| 4 | Where recorded, given the item lock? | **A new derived column**, written by its own action |
| 5 | Permission? | **No new one** — `orders.status.delivered` is enough *(against the recommendation)* |
| 6 | Restocked quantity when units differ? | **Ask**, pre-filled with the pro-rata |
| 7 | Flag in the orders list? | **Yes, a chip**, like «نواقص» *(against the recommendation)* |
| 8 | Fix the `ScrapLoss` P&L gap here? | **Yes** — both losses in one section |


### Decision 1 — Is the customer billed for what they left?

| | Option | Consequence |
|---|---|---|
| **A** ✅ **chosen** | **No. The invoice follows what was handed over.** | Revenue falls. For a printed line, COGS stays whole, so the shop eats the full cost — which is precisely "a loss in the P&L". |
| B | Yes for printed lines (it was made to their artwork, their problem), no for plain ones. | Then there is **no loss to report** on printed lines — the question the owner asked would have no answer. Also splits the rule across two branches for no gain. |
| C | Ask per line at the counter. | Maximum flexibility, maximum arguing at the till, and an invoice nobody can reconstruct later. |

**Settled: A**, as recommended. It is what makes the requested P&L loss exist at all, and it
is the rule the codebase already committed to for نواقص — «النقص ذنبنا لا ذنب العميل». If the shop later
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
| **A** ✅ **chosen** | The `delivery_loss` entry is a **named, non-additive memo** — a new reported line on the P&L beside `write_offs`, not a new subtrahend. | Correct arithmetic. Follows `ScrapLoss`, which is deliberately excluded from `labor_cost`/`overhead_cost` for this exact reason. |
| B | Add it to COGS. | **Double-counts.** The 100 undelivered bags' cost would be charged twice: once inside the frozen `material_cost`, once as the loss row. Gross profit goes wrong. |

**Settled: A**, as recommended. And a note that follows from it: **`ScrapLoss` is invisible on
the P&L today** for the same structural reason — so a new section called «الخسائر» carrying only
partial delivery would name one kind of loss and stay silent about the other. **That is Decision
8, and it was taken: scrap joins the same section.** See §4.7.

### Decision 3 — What is the loss *valued* at?

| | Option | Reads as |
|---|---|---|
| **A** ✅ **chosen** | Its share of the line's COGS: `cogs × undelivered ÷ quantity` | «قيمة البضاعة التي صنعناها ولم تُبَع» — what the goods cost us. |
| B | Its foregone revenue: `unit_price × undelivered` | The margin we didn't earn. Already visible as the revenue drop; reporting it again as a "loss" double-tells the same story. |

**Settled: A**, as recommended — cost, not price. A loss line on a cost statement is a cost.

### Decision 4 — Where is it recorded, given the item lock?

`Order::itemsAreEditable()` is false from «جاهزة» onward, and must stay so.

| | Option | |
|---|---|---|
| **A** ✅ **chosen** | **A new derived column, written by its own action** — exactly how `warehouse_quantity` is written onto locked lines at «جاهزة», and how `shortage_quantity` moves money without `quantity` ever being touched. | The lock is not in the way; it guards `UpdateOrder`, not every write. |
| B | Open the lock at delivery and edit `quantity`. | Destroys the record of what the customer ordered — the very question a partial delivery is the answer to. Also makes the invoice unreconstructable. |
| C | Leave the lines alone, post a credit note in the payment ledger. | The other half of the BACKLOG question. Rejected: it hides the *quantity* fact in a money row, and the goods still have to be restocked or written off, which needs a per-line quantity anyway. |

**Settled: A**, as recommended. It is the pattern this codebase already uses twice, and it keeps the whole
thing reversible by construction: clear `undelivered_quantity` and the invoice returns to what it
was, because nothing was ever subtracted in place.

### Decision 5 — Who is allowed to do it?

Recording a partial delivery **moves money** (it shrinks the invoice). `orders.status.delivered`
is held by anyone who can hand a parcel over, including a driver.

| | Option | |
|---|---|---|
| **A** ✅ **chosen** | **`orders.status.delivered` is enough.** Whoever may hand the parcel over may record what was handed over. | No new grant to hand out, nothing to seed, one less thing on the roles screen. |
| B | *(was recommended)* A new `orders.partial_delivery`, withholding the **fields** and not the move — the precedent `TransitionFields::money()` sets for the payment box. | A driver could not shrink an invoice. Costs a permission, a seeder grant and a role-screen row. |

**Settled: A.** The recommendation was B and it lost, for a defensible reason: the person holding
the parcel is the only person who *knows* what was taken, and a form that withholds the question
from them just moves the fiction one desk along — the order gets marked delivered in full and the
correction never happens.

**What that costs, recorded here so it is not discovered later.** A driver can now reduce what a
customer owes, from the phone, with no second pair of eyes. Three things already in the codebase
make that survivable, and they are the reason this is acceptable rather than merely cheaper:

- **`order_item` is audited.** Every movement of `undelivered_quantity` writes a row saying who
  and when, readable from the order's own history screen.
- **Nothing is destroyed.** `quantity` never moves; the figure is derived, so an invoice wrongly
  shrunk is put back by clearing one field — no reversing entry, no correction of a correction.
- **The money box is still separately guarded.** `orders.payments.record` is unchanged, so the
  driver who records a partial delivery still cannot take the payment against it.

If abuse ever shows up in the audit log, B is a one-line addition to `TransitionFields::for()` —
the field list is built in one place precisely so that this stays a small change.

### Decision 6 — The restocked quantity, when the units differ

A line sold by the piece and stocked by the kilo has no meaningful per-piece weight —
`DeductOrderStock` says so at length and refuses to multiply one out.

**Settled: ask.** The delivered quantity is asked in the **pricing** unit (the number the
clerk has). For a restocked line whose `isStockedInAnotherUnit()` is true, a **second** box asks
the returned amount in the **stock** unit, pre-filled with the pro-rata as a *suggestion* the
storekeeper can correct on the scale. Where the units agree, nothing extra is asked and the
return is exact arithmetic.

### Decision 7 — Is a partially delivered order flagged in the orders list?

| | Option | |
|---|---|---|
| **A** ✅ **chosen** | **A chip in the list**, beside «نواقص» and the payment chips. | Spotted while scrolling. Cheaper than it looks — see below. |
| B | *(was recommended)* Detail screen only. | Less noise in a list that already carries status, urgency and payment chips. |
| C | Chip plus a dedicated filter. | The most reviewable; a new query, API parameter and app control on top of the chip. |

**Settled: A**, and the recommendation against it was wrong on the facts. B was recommended on
the assumption the chip would cost a query per row — it does not. `OrderListQuery` **already
eager-loads `items`** for the line count and the product cards, so the flag is a derived boolean
over a collection already in memory:

```php
// OrderResource — no new column, no new query, no N+1
'is_partially_delivered' => $this->items->contains(
    fn (OrderItem $item) => $item->undelivered_quantity !== null
        && bccomp((string) $item->undelivered_quantity, '0', 3) > 0,
),
```

Derived rather than cached, for the reason `Order::grossProfit()` gives about itself: both inputs
are already loaded, and a third column to keep in step could only ever disagree with them.

**No filter, for now.** C was not chosen and should not be smuggled in: a filter is a query, an
API parameter and a control on the list screen, and the P&L losses section (§4.7) already answers
«كم يكلّفنا هذا؟» — which is the question a filter would mostly be used to ask.

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

Added to `TransitionFields::for()` on the move into `Delivered`. **Ungated** — Decision 5: anyone
who may make the move is asked the question, driver included.

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

A new reported section, beside `write_offs` and on the same reconciliation shelf — **reported,
never subtracted** (Decision 2):

```
'losses' => [
    'partial_delivery' => …,   // sum of active delivery_loss entries in the window
    'scrap'            => …,   // the existing gap, closed here — Decision 8
    'total'            => …,
],
```

Summed over active (non-reversed, non-reversing) entries on orders recognised in the window, which
is the query `RecalculateOrderItemManufacturingCost::activeEntriesFor()` already writes.

**`scrap` joins it in the same change** (Decision 8). `RecordScrapLoss` has been writing
`ScrapLoss` entries since manufacturing costs landed, and `ProfitAndLossSummaryQuery` has never
read them: the report sums the cached item columns, and `RecalculateOrderItemManufacturingCost`
deliberately folds `ScrapLoss` into neither `labor_cost` nor `overhead_cost`. So spoiled bags are
recorded, auditable, chargeable to an investor — and invisible on the one statement that asks
what the month cost. Shipping `partial_delivery` alone under a heading called «الخسائر» would have
made that silence worse by looking like an answer.

Both rows read the same table with the same active-entry rule and differ only in `cost_type`, so
this is one query with a `CASE`, not two.

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
| 5 | `TransitionFields` on `Delivered` + `ChangeOrderStatus` wiring and ordering | backend |
| 6 | P&L `losses` section — partial delivery **and** the existing scrap gap | backend |
| 7 | `is_partially_delivered` on `OrderResource` — derived, no new query | backend |
| 8 | Order detail: «غير مُستلَم» per line beside «ناقص», and the loss figure | frontend |
| 9 | The orders-list chip | frontend |
| 10 | P&L screen: the new losses rows | frontend |
| 11 | `openapi.json` regen | backend |

**No permission slice** — Decision 5 reuses `orders.status.delivered`, so there is nothing to
define, nothing to seed and nothing to add to the roles screen.

**The status-change form itself needs no Dart at all** — the app renders server-described `number`
fields already. Slices 8–10 are display only.

### Tests to write

- `billableQuantity()` with shortage and undelivered together, and the floor at zero.
- A mixed order: one سادة line restocked, one printed line written off, in one move.
- The restock lands on the **original** cost layers (assert `material_cost`, not an average).
- Cancel, then delete, then restore an order that was partially delivered — the movement pointer
  and the loss entries survive the round trip.
- Investor split on a partially delivered order: slice falls, purchase for returned goods unwound.
- **A driver with only `orders.status.delivered` is offered the per-line boxes** and the write
  stands — Decision 5 is a rule, so it gets a test rather than a sentence.
- The audit trail: moving `undelivered_quantity` writes an `order_item` entry naming who and when.
- P&L: revenue falls, COGS does not, the loss lines report and do not subtract.
- P&L: an order carrying **both** a scrap loss and a partial-delivery loss reports them on their
  own rows and in `total`, and gross profit is untouched by either.
- `is_partially_delivered` is false for a fully delivered order and for one whose
  `undelivered_quantity` is zero rather than null — and the list renders it **without a query per
  row** (assert the query count, which is the whole reason the chip was affordable).

### Rough size

Backend slices 1–6 are the bulk of it, and slice 3 is the one with real risk (FIFO). Frontend 7–8
are small. Slice 3 should be built and tested before 5 is wired, so that a half-finished restock
can never be reachable from a screen.

---

## 7. Nothing is open

All eight decisions in §3 are answered. What is left is building it, in the order §6 gives.

**The two that went against the recommendation are worth re-reading before anyone changes them
back**, because both were argued and both have a reason that outlives this document:

- **No permission (5).** The person holding the parcel is the only one who knows what was taken.
  Withholding the question from them does not prevent a wrong invoice — it just moves the fiction
  one desk along. The audit trail and the derived, clearable column are what make that safe.
- **A chip in the list (7).** Recommended against on a cost that turned out not to exist:
  `OrderListQuery` already eager-loads `items`, so the flag is free.

**One thing deliberately still deferred:** the return policy *after* delivery — a customer coming
back tomorrow. «تم الاستلام» stays final, and that remains its own BACKLOG item needing a
credit-note design. Partial delivery is about the moment of handover and nothing after it.
