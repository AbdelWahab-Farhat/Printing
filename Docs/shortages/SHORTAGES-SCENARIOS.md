# النواقص — every scenario, worked

> One concrete example per scenario in [SHORTAGES-FLOW.md §٢](SHORTAGES-FLOW.md). Request in,
> response out, and what the database holds afterwards.
>
> Every status code, field key and Arabic sentence below is what the built endpoints actually
> answer — each has a test behind it in `backend/tests/Feature/Shortages/`.
>
> **Updated 2026-09-13:** recording a supply now posts the goods onto a shelf. Groups A–K are
> unchanged; **D11–D15** and **L** at the end are what the change adds.

---

## Conventions used throughout

**The envelope.** Success is `{ "status": true, "message": "…", "data": … }`. A refusal is
`{ "status": false, "message": "…", "data": null, "errors": { "<field>": ["…"] } }` — `errors`
only when the failure is field-level.

**The running example.** Order **1204** for محل النور, one line `3310` — كيس شحن ٢٥*٣٥, 300 كجم.
Users: **محمد** (id 6, the chaser), **أحمد** (id 2, the supervisor).

**Shortened payloads.** Responses below show only the keys that matter to the scenario. The full
shape is in [SHORTAGES-FRONTEND-INTEGRATION.md §١٫٣](SHORTAGES-FRONTEND-INTEGRATION.md).

---

# A — Creating

## A1 · Manual, with a catalogue product

```http
POST /api/v1/shortages
{
  "name": "كيس شحن — 25*35",
  "unit": "kilogram",
  "required_quantity": "50",
  "product_id": 12,
  "product_variant_id": 45,
  "description": "نفد من الرف الثالث"
}
```

**201**

```jsonc
{ "id": 42, "code": "N42", "source": "manual", "source_label": "يدوي",
  "status": "new", "status_label": "جديد",
  "required_quantity": "50.000", "supplied_quantity": "0.000",
  "remaining_quantity": "50.000", "total_paid": "0.00",
  "is_editable": true,
  "order_id": null, "order_item_id": null, "customer_id": null,
  "assigned_to_user_id": null, "created_by_user_id": 2,
  "available_transitions": [
    { "value": "searching",   "label": "جاري البحث" },
    { "value": "unavailable", "label": "غير متوفر" }
  ] }
```

> `code` is `N` + the row's id — a letter, unlike an order number, because a shortage is almost
> always said next to the order it came from and «نقص ٤ على طلبية ٤» is two bare fours.

## A2 · Manual, free text — not in the catalogue

```http
POST /api/v1/shortages
{ "name": "شريط لاصق عريض", "unit": "piece", "required_quantity": "12" }
```

**201** — `product_id: null`, `product_variant_id: null`, everything else as A1.

> The product link is **optional on purpose**. What gets written down by hand is very often what
> the catalogue has never heard of, and a required link makes an employee pick the nearest wrong
> row to get past the field.

## A3 · Manual, assigned at creation

```http
POST /api/v1/shortages
{ "name": "شريط لاصق عريض", "unit": "piece", "required_quantity": "12",
  "assigned_to_user_id": 6 }
```

**201** — `assigned_to_user_id: 6`, but **`status: "new"`**.

> Creating and assigning are one form here for convenience; they are still two facts. The status
> advances only through `PATCH .../assignee` (C1). Somebody writing a shortage down usually knows
> who will chase it — often themselves — and making them save then assign is two screens for one
> thought.

## A4 · Manual, quantity zero

```http
POST /api/v1/shortages
{ "name": "أكياس شحن", "unit": "kilogram", "required_quantity": "0" }
```

**422**

```jsonc
{ "status": false, "data": null,
  "errors": { "required_quantity": ["الكمية الناقصة يجب أن تكون أكبر من صفر"] } }
```

Nothing is written. The same rule is enforced three times — the form, the DTO, and a CHECK
constraint — so a console command cannot write a row the API refuses.

## A5 · Order enters «نواقص», one line short

```http
PATCH /api/v1/orders/1204/status
{ "status": "shortage", "shortage_3310": "30" }
```

**200** — the order comes back on «نواقص», and its invoice has already dropped:

```jsonc
{ "id": 1204, "status": "shortage",
  "items": [ { "id": 3310, "quantity": "300.000", "shortage_quantity": "30.000",
               "line_total": "418.50" } ] }
```

Then, off a queued listener:

```
shortages
  N41 · كيس شحن — 25*35 · required 30.000 · supplied 0.000 · جديد
      · source من طلبية · order 1204 · line 3310 · customer محل النور · assignee —
```

> **Not instant.** The reconciliation runs after the transaction commits, on the queue. A screen
> that re-reads `/shortages` in the same breath as this response may not see N41 yet.

## A6 · Three lines — two short, one fine

The brief's own example. Order 1204 now carries three lines:

```http
PATCH /api/v1/orders/1204/status
{ "status": "shortage",
  "shortage_3310": "20",      // أكياس شحن
  "shortage_3311": "",        // أكياس يد   — available
  "shortage_3312": "10" }     // أكياس شفافة
```

Two records, never one:

```
N41 · أكياس شحن — 25*35   · required 20.000 · line 3310
N43 · أكياس شفافة — 30*40 · required 10.000 · line 3312
```

Line 3311 produces nothing. Each record carries its own line, its own product and the same
order and customer.

> «كم الناقص؟» asked of a whole order has no answer — it is a question about a size.

## A7 · Trying to create an order-born shortage by hand

```http
POST /api/v1/shortages
{ "name": "…", "unit": "kilogram", "required_quantity": "30", "order_id": 1204 }
```

**201, and `order_id` is ignored** — the record is created as `source: "manual"` with
`order_id: null`. The field is not in the request's rules, so validation drops it.

> There is no endpoint that can write an order-born shortage. One that could would create a row
> no order knows about, which the next reconciliation would delete as an orphan.

---

# B — The duplicate guard (§١٠ of the brief)

## B1 · The order is moved to «نواقص» twice

```
Before   N41 · required 30.000 · supplied 0.000
```

```http
PATCH /api/v1/orders/1204/status   { "status": "ready_to_print", "received_3310": "0" }
PATCH /api/v1/orders/1204/status   { "status": "shortage", "shortage_3310": "30" }
```

```
After    N41 · required 30.000 · supplied 0.000     ← same row, same number
```

**One record. Not two, and not 60.** The reconciliation updates rather than inserts, and a partial
unique index on `order_item_id` refuses a second live row for line 3310 even under a race.

## B2 · The clerk corrects 30 → 40 on the order

```http
PATCH /api/v1/orders/1204/shortages
{ "shortages": { "3310": "40" } }
```

```
N41 · required 30.000 → 40.000 · supplied 0.000 · remaining 40.000
```

The record grows. A second one is not created.

## B3 · The clerk corrects 30 → 20

```
N41 · required 30.000 → 20.000 · remaining 20.000
```

## B4 · Two requests race

Two clerks move the order to «نواقص» at the same instant. Both reconciliations run; the second's
`INSERT` violates `shortages_order_item_id_unique`. One row exists.

> A check in PHP loses to two requests that both pass it before either commits. The index does
> not.

---

# C — Assignment

## C1 · Assigning a «جديد» shortage

```http
PATCH /api/v1/shortages/41/assignee
{ "assigned_to_user_id": 6 }
```

**200**

```jsonc
{ "id": 41, "assigned_to_user_id": 6,
  "assignee": { "id": 6, "name": "محمد", "employee_code": "E6" },
  "status": "searching", "status_label": "جاري البحث" }
```

And محمد's phone:

```
نقص مُسنَد إليك
كيس شحن — 25*35 — 30.000 كجم
```

> The status moves because «لم تبدأ متابعته بعد» stopped being true. This is the one place a
> status changes without anybody choosing it — which is why it is deliberately not on the
> transition map: the map governs what a *person* may pick.

## C2 · Reassigning one already «جاري البحث»

```http
PATCH /api/v1/shortages/41/assignee
{ "assigned_to_user_id": 9 }
```

**200** — `assigned_to_user_id: 9`, **`status` unchanged** (`searching`). علي (id 9) is notified;
محمد is not told his work was taken.

## C3 · Assigning to yourself

محمد (id 6) sends `{ "assigned_to_user_id": 6 }` with his own token.

**200**, assignee set, **no notification** — the audience is one person, and that person is the
causer, so `notifiesCauser: false` empties it. He watched it happen on his own screen.

## C4 · Unassigning

```http
PATCH /api/v1/shortages/41/assignee
{ "assigned_to_user_id": null }
```

**200**

```jsonc
{ "assigned_to_user_id": null, "assignee": null,
  "status": "searching" }          // ← unchanged
```

No notification. The chase started, so it goes back into the pool **open**, rather than pretending
nobody ever picked it up.

## C5 · Omitting the field

```http
PATCH /api/v1/shortages/41/assignee
{ }
```

**422**

```jsonc
{ "errors": { "assigned_to_user_id":
    ["حقل الموظف المسؤول مطلوب — أرسل قيمة فارغة لإلغاء الإسناد"] } }
```

> `present` rather than `required`: an omitted field is a bug, an explicit null is a decision, and
> `required` would refuse them both alike.

## C6 · Assigning without the grant

A user holding `shortages.view` and `shortages.manage` but not `shortages.assign`:

**403** «ليس لديك صلاحية لتنفيذ هذا الإجراء»

> Routing work and doing it are different jobs. A supervisor hands a shortage over without being
> trusted to spend money on it; a clerk who writes shortages down all day does not thereby move
> other people's queues.

---

# D — Supplying

## D1 · The whole amount in one go

```
Before   N41 · required 30.000 · supplied 0.000 · remaining 30.000 · paid 0.00 · جاري البحث
         order_items[3310].shortage_quantity = 30.000
```

```http
POST /api/v1/shortages/41/supplies
{ "quantity": "30", "amount": "760", "method": "bank_transfer", "reference": "TR-5521" }
```

**201**

```jsonc
{ "id": 77, "shortage_id": 41, "kind": "purchased", "kind_label": "شراء",
  "quantity": "30.000", "amount": "760.00",
  "method": "bank_transfer", "method_label": "حوالة",
  "reference": "TR-5521", "occurred_on": "2026-09-12",
  "is_reversal": false, "is_reversed": false, "is_reversible": true,
  "recorder": { "id": 6, "name": "محمد", "employee_code": "E6" } }
```

```
After    N41 · supplied 30.000 · remaining 0.000 · paid 760.00 · مكتمل
         order_items[3310].shortage_quantity = null      ← the invoice is whole again
```

## D2 · Partial, twice — the brief's §٥

```http
POST /api/v1/shortages/41/supplies   { "quantity": "20", "amount": "500", "method": "cash" }
```

```
N41 · supplied 20.000 · remaining 10.000 · paid 500.00 · جاري البحث   ← still open
order_items[3310].shortage_quantity  30.000 → 10.000
```

```http
POST /api/v1/shortages/41/supplies   { "quantity": "10", "amount": "260", "method": "bank_transfer" }
```

```
N41 · supplied 30.000 · remaining 0.000 · paid 760.00 · مكتمل
order_items[3310].shortage_quantity  10.000 → null
```

Final ledger:

| الكمية | القيمة | طريقة الدفع | الموظف |
| --- | --- | --- | --- |
| ٢٠٫٠٠٠ كجم | ٥٠٠٫٠٠ د.ل | نقدي | محمد |
| ١٠٫٠٠٠ كجم | ٢٦٠٫٠٠ د.ل | حوالة | محمد |

**المطلوب ٣٠ · المتوفر ٣٠ · المتبقي ٠ · المدفوع ٧٦٠٫٠٠**

## D3 · More than is left

```
Before   N41 · required 30.000 · supplied 0.000 · remaining 30.000
```

```http
POST /api/v1/shortages/41/supplies   { "quantity": "31", "amount": "800", "method": "cash" }
```

**422**

```jsonc
{ "errors": { "quantity": ["الكمية (31.000) أكبر من المتبقي من النقص (30.000)"] } }
```

Nothing is written; `supplied` stays `0.000`.

> Buying thirty to cover a shortage of twenty is a real thing — it is a purchase for the **shelf**,
> and its door is a purchase order, where it becomes stock with a cost layer. Letting it in here
> would put ten kilos inside an order's shortage that no order was ever short of.

## D4 · Against a «غير متوفر» shortage — the sack that turned up

```
Before   N41 · required 30.000 · supplied 0.000 · غير متوفر
```

```http
POST /api/v1/shortages/41/supplies   { "quantity": "10", "amount": "250", "method": "cash" }
```

**201**

```
After    N41 · supplied 10.000 · remaining 20.000 · paid 250.00 · جاري البحث
```

Reopened. Had the 10 completed it, it would have gone straight to «مكتمل» instead — the
reopen is applied first and the arithmetic wins.

> Refusing this would send the employee to open a **second** shortage for the same sack, which is
> the shortest road to exactly the duplication §١٠ exists to prevent.

## D5 · Against a «مكتمل» shortage

```http
POST /api/v1/shortages/41/supplies   { "quantity": "1", "amount": "20", "method": "cash" }
```

**422** `{ "message": "النقص مكتمل — لا يمكن تسجيل توفير جديد عليه" }`

The way back is a reversal of whichever entry closed it (G2), which re-runs the totals.

## D6 · Quantity without money

```http
POST /api/v1/shortages/41/supplies   { "quantity": "10" }
```

**422**

```jsonc
{ "errors": {
    "amount": ["القيمة المدفوعة مطلوبة"],
    "method": ["طريقة الدفع مطلوبة"] } }
```

> «الكمية + القيمة + طريقة الدفع» holds in three layers: the form gives this readable 422, the
> DTO's non-nullable types stop a console command, and a CHECK constraint is the guarantee.

## D7 · On a manual shortage

N42 — «شريط لاصق عريض», no order behind it.

```http
POST /api/v1/shortages/42/supplies   { "quantity": "12", "amount": "45", "method": "cash" }
```

**201**, `N42` completes, **and no order is touched** — there is no line to credit, and nobody is
being billed for tape bought for the workshop.

## D8 · When the order has reached «جاهزة»

```
Before   order 1204 · status جاهزة        ← its lines are closed; stock has left the warehouse
         N41 · required 30.000 · remaining 30.000
```

```http
POST /api/v1/shortages/41/supplies   { "quantity": "30", "amount": "760", "method": "cash" }
```

**201**

```
After    N41 · supplied 30.000 · paid 760.00 · مكتمل
         order_items[3310].shortage_quantity   — unchanged
```

> The purchase is recorded; the invoice stands. Calling `setShortages` here would have been
> refused with a 422 about order lines — the employee would be told they may not write down a
> purchase they have already made, by a rule about a screen they are not on. And a shortage still
> open after its order shipped was, by definition, not billed for.

## D9 · When the order has been archived

```
Before   order 1204 · deleted_at set
```

Same call, same **201**, same outcome as D8: recorded, invoice untouched. The order's own money
was already reversed by the delete; the money spent chasing the sack was not, and is not.

## D10 · Two clerks record the last 10 kg at once

Both read `remaining: 10.000`. The first request takes the row lock, writes, and leaves
`remaining: 0.000`. The second acquires the lock afterwards, re-reads, and gets **D3's 422**.

> The ceiling is read **under the lock**, never from the model the request was bound to — that one
> holds what was true when the request started.

---

# E — The other door: the order screen

## E1 · 20 of 30 arrived with the delivery

```
Before   N41 · required 30.000 · supplied 0.000 · remaining 30.000
```

The order leaves «نواقص» and the clerk types what arrived:

```http
PATCH /api/v1/orders/1204/status
{ "status": "ready_to_print", "warehouse_id": 1, "received_3310": "20" }
```

```
order_items[3310].shortage_quantity   30.000 → 10.000
```

The reconciliation writes a row nobody in this section created:

```jsonc
{ "id": 78, "kind": "resolved_externally", "kind_label": "وصلت من الطلبية",
  "quantity": "20.000",
  "amount": null, "method": null, "method_label": null,
  "is_reversible": false }
```

```
After    N41 · required 30.000 · supplied 20.000 · remaining 10.000 · paid 0.00
```

> **No money on the row, and not a zero.** Goods that arrived from the order were paid for on a
> purchase order; a `0.00` here would read as a free purchase and sit wrongly in «كم صرفنا على
> النواقص؟».

## E2 · All 30 arrived

```http
PATCH /api/v1/orders/1204/status
{ "status": "ready_to_print", "warehouse_id": 1, "received_3310": "30" }
```

```
order_items[3310].shortage_quantity → null
N41 · supplied 30.000 · remaining 0.000 · paid 0.00 · مكتمل
```

Completed with nothing spent — a perfectly ordinary ending, and the log says how.

## E3 · Both doors on one shortage

```
1. bought here          20 kg · 500 د.ل · نقدي
2. arrived via order    10 kg · —       · —
```

```
N41 · required 30.000 · supplied 30.000 · remaining 0.000 · paid 500.00 · مكتمل
```

| الكمية | القيمة | طريقة الدفع | النوع |
| --- | --- | --- | --- |
| ٢٠٫٠٠٠ كجم | ٥٠٠٫٠٠ د.ل | نقدي | شراء |
| ١٠٫٠٠٠ كجم | — | — | وصلت من الطلبية |

## E4 · Trying to reverse an arrival

```http
POST /api/v1/shortages/41/supplies/78/reversal   { "reason": "خطأ" }
```

**422** `{ "message": "لا تُعكس كمية وصلت من الطلبية — تُصحَّح من شاشة الطلبية" }`

> That row is not an entry somebody made — it is the reconciliation's record of what the order
> said. Reversing it here would leave this table disagreeing with the line it came from, and the
> next sync would write it again.

---

# F — Withdrawing the claim

All three reach the server as the same write — the line goes to zero. They are told apart by the
**reason** the caller passes (`declared` · `received` · `corrected`), never inferred.

## F1 · A slip: nobody chased it, nothing was spent

```
Before   N41 · required 30.000 · supplied 0.000 · جديد · assignee —
```

The clerk realises the 30 was a typo and clears it on the order screen:

```http
PATCH /api/v1/orders/1204/shortages
{ "shortages": { "3310": null } }
```

```
After    N41 is soft-deleted.   shortages WHERE id = 41 → (empty)
         withTrashed()          → still there, for the audit trail
```

> Three conditions must all hold: still «جديد», in nobody's queue, nothing recorded against it.
> A row nobody treated as real work is noise on the board rather than history worth keeping — and
> recording an "arrival" for a slip would put «مكتمل ٣٠ كجم» on the screen for goods nobody
> procured.

## F2 · The same correction, but somebody was on it

```
Before   N41 · required 30.000 · supplied 0.000 · جاري البحث · assignee محمد
```

Same request as F1.

```
After    N41 · supplied 30.000 · remaining 0.000 · مكتمل
         + { resolved_externally · 30.000 · no money }
```

**Kept and completed.** The chaser's work is not thrown away on an inference — any one of the
three conditions failing means a person has had their hands on it.

The same holds if money was spent: a shortage with a 20 kg purchase against it is kept, the
remaining 10 is recorded as arrived, and the ledger still shows the 500 د.ل.

## F3 · The order leaves «نواقص» with everything received

Reason `received` — identical outcome to F2, and identical to **E2**. Recorded, completed, kept.

> This is where inference broke. The first implementation read the order's *status* to tell F1
> from F3, and whether the status had moved by the time the listener ran depended on the queue
> driver — `sync` in tests, `database` on the server. The same event meant different things on a
> laptop and in production. The three callers know which it is, so they say so.

---

# G — Reversing a supply

## G1 · Undoing a purchase entered twice

```
Before   N41 · supplied 20.000 · remaining 10.000 · paid 500.00 · جاري البحث
         supply 77 · purchased · 20.000 · 500.00 · نقدي
```

```http
POST /api/v1/shortages/41/supplies/77/reversal
{ "reason": "أُدخلت مرتين" }
```

**201** — a *second* row, not an edit:

```jsonc
{ "id": 79, "kind": "purchased",
  "quantity": "20.000", "amount": "500.00", "method": "cash",
  "reverses_supply_id": 77,
  "notes": "أُدخلت مرتين",
  "occurred_on": "2026-09-12",        // today, not the day of the entry being undone
  "is_reversal": true, "is_reversible": false }
```

```
After    N41 · supplied 0.000 · remaining 30.000 · paid 0.00 · جاري البحث
         ledger holds BOTH rows — the mistake and its correction, one row apart
```

Row 77 now reads `is_reversed: true, is_reversible: false`. Render it struck through; do not hide
it.

> The amount is **copied verbatim** so the pair nets to zero in any sum that ignores the pairing,
> and so the CHECK demanding money on a purchase is satisfied rather than worked around.

## G2 · Reversing the entry that completed it

```
Before   N41 · supplied 30.000 · remaining 0.000 · paid 760.00 · مكتمل
```

Reverse the 10 kg / 260 د.ل entry:

```
After    N41 · supplied 20.000 · remaining 10.000 · paid 500.00 · جاري البحث
```

**Reopened to «جاري البحث», not «جديد».** The chase demonstrably started; sending it back to
«جديد» would tell the board nobody has touched it.

> A shortage left reading «مكتمل» with ten kilos outstanding is worse than one that never closed,
> because nobody is looking at it any more.

## G3 · Reversing the same row twice

```http
POST /api/v1/shortages/41/supplies/77/reversal   { "reason": "مرة أخرى" }
```

**422** `{ "message": "عملية التوفير معكوسة أصلاً" }`

The partial unique index on `reverses_supply_id` is the guarantee; this check under the same lock
is what turns it into a readable refusal instead of a raw 500.

## G4 · Reversing a reversal

```http
POST /api/v1/shortages/41/supplies/79/reversal   { "reason": "تراجع" }
```

**422** `{ "message": "لا يُعكس قيدٌ عكسي — تُسجَّل العملية من جديد إن كان الشراء قد تمّ فعلاً" }`

> Undoing an undo is a third financial event nobody asked for.

## G5 · Reversing without a reason

```http
POST /api/v1/shortages/41/supplies/77/reversal   { }
```

**422** `{ "errors": { "reason": ["سبب العكس مطلوب"] } }`

> «عُكست» with no sentence beside it answers nothing six months later.

## G6 · Does the invoice get re-cut?

```
Before   supply of 20 recorded → order_items[3310].shortage_quantity = 10.000
Reverse that supply
After    order_items[3310].shortage_quantity = 10.000      ← unchanged
```

**No.** A reversal means the *entry* was wrong — typed twice, wrong shortage, wrong amount — not
that sacks were taken back off a customer. An order whose goods really did not arrive is corrected
on the order screen, where the person doing it can see the invoice change.

## G7 · A supply belonging to another shortage

```http
POST /api/v1/shortages/41/supplies/78/reversal      # 78 belongs to N43
```

**404.** The route scopes `{supply}` within `{shortage}`, so another shortage's entry does not
resolve. The domain refuses it too — belt and braces on a route that moves money.

---

# H — The order's lifecycle

## H1 · «إلغاء تام» with money spent

```
Before   N41 · supplied 10.000 · remaining 20.000 · paid 250.00 · جاري البحث
```

```http
PATCH /api/v1/orders/1204/status   { "status": "cancelled", "reason": "تراجع الزبون" }
```

```
After    N41 · غير متوفر · supplied 10.000 · paid 250.00
         ledger unchanged — 1 row, no reversal written
```

> The cash left the till and the goods exist, whatever became of the order. Reversing inside a
> cancel button would be an accounting entry nobody chose to make.

## H2 · «إلغاء تام» with nothing spent

```
Before   N41 · supplied 0.000 · جديد
After    soft-deleted
```

## H3 · «إلغاء تام» on a completed shortage

```
Before   N41 · supplied 30.000 · paid 760.00 · مكتمل
After    N41 · supplied 30.000 · paid 760.00 · مكتمل      ← untouched
```

«الاحتفاظ بالنواقص المكتملة كسجلٍّ تاريخي.»

## H4 · Deleting the order (the archive)

```http
DELETE /api/v1/orders/1204
```

Identical to H1–H3, row for row. A cancellation says the order happened and then stopped; a delete
says it should never have been written — a distinction that matters a great deal to the order and
not at all to a sack nobody is going to buy now.

**And the order's own payments *are* reversed by this while the shortage's are not.** That is not
an inconsistency: the P&L reads revenue through the soft-delete scope and cash outside it, so an
untreated paid order makes one report describe two sets of orders. No such asymmetry exists here.

## H5 · Restoring the order

```http
POST /api/v1/orders/1204/restore
```

```
Before   N41 soft-deleted (H2), order archived
After    N41 recreated · required 30.000 · جديد
```

The order's lines still carry the `shortage_quantity` they were archived with, so the same
reconciliation produces exactly the rows that should exist. One kept as «غير متوفر» (H1) has its
requirement restated and is reopened by the arithmetic if it grew.

> **The quantity comes back; the price does not have to.** A restore re-draws stock at *today's*
> cost layers, so the order returns costed differently. A shortage quantity is a physical fact
> about sacks that are not on a shelf — it carries no cost layer and returns as it was.

## H6 · A line is deleted off the order

```http
PUT /api/v1/orders/1204        # items no longer include line 3310
```

| N41's state | Result |
| --- | --- |
| nothing supplied | soft-deleted |
| something supplied | kept · `order_item_id` → null · `name` still «كيس شحن — 25*35» · closed |

The snapshotted name is what carries the record once the line is gone.

## H7 · A manual shortage while all this happens

N42 («شريط لاصق عريض») is **untouched by every row of H1–H6.** It belongs to no order, so no
order's ending sweeps it.

---

# I — Editing

## I1 · Correcting a manual shortage

```http
PUT /api/v1/shortages/42
{ "name": "شريط لاصق عريض 5سم", "unit": "piece", "required_quantity": "20" }
```

**200** — updated, and the totals are restated in case the change closed or reopened it.

## I2 · Editing an order-born one

```http
PUT /api/v1/shortages/41
{ "name": "شيء آخر", "unit": "piece", "required_quantity": "5" }
```

**422** `{ "message": "نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا من هنا" }`

`N41.required_quantity` is unchanged at `30.000`.

> Refusing is kinder than accepting. The name, unit and requirement are copied off the line and
> rewritten on every sync, so an edit here would survive until the next time anybody touched that
> order and then vanish — and the employee would have no way of finding out why.
>
> The app should not offer it either: `is_editable: false` is on the payload.

## I3 · Cutting a requirement below what was bought

```
Before   N42 · required 30.000 · supplied 20.000 · paid 500.00
```

```http
PUT /api/v1/shortages/42
{ "name": "…", "unit": "kilogram", "required_quantity": "10" }
```

**422**

```
الكمية المطلوبة (10.000) أقل مما تم توفيره فعلاً (20.000) — اعكس عملية التوفير أولاً
```

> Accepting it would leave the shortage owing minus ten, which floors at zero and reads as
> complete — so the correction would quietly close a shortage by making its own history
> impossible.

---

# J — Who can see what

## J1 · A reader without `orders.archive.view`

```
Given    order 1204 is archived; N41 hangs off it. N42 is manual.
         The reader holds shortages.view only.
```

```http
GET /api/v1/shortages
```

**200** — N42 only. N41 is filtered out **in SQL**, so the page is not short by one.

```http
GET /api/v1/shortages/summary
```

**200** — `{ "counts": { "new": 1, … }, "total": 1 }`. N41 is not counted either.

```http
GET /api/v1/shortages/41
```

**403** `هذا النقص يخصّ طلبية في الأرشيف، وعرضه يحتاج صلاحية عرض أرشيف الطلبات`

Same 403 on `PUT`, both `PATCH`es, both supply routes and `/logs`.

> **The counts matter as much as the list.** A chip row that counted rows the list would not show
> leaks the archive through a number that moves — the exact failure the orders archive documented
> once already, which is why both queries share one filter trait.
>
> And the message is its own sentence, not the blanket «ليس لديك صلاحية»: the reader *holds* the
> grant this endpoint asks for and is being refused by a fact about this one row.

## J2 · A reader with the grant

Same requests, holding `shortages.view` + `orders.archive.view`:

```jsonc
// GET /api/v1/shortages   →   both rows
{ "id": 41, "order": { "id": 1204, "code": "1204", "status": "cancelled",
                       "is_archived": true } }
```

`is_archived` is published deliberately — a reader who got this far is allowed to see it, and
hiding the flag would only stop the app explaining why the order's link leads somewhere unusual.

## J3 · A manual shortage, no grant

Always visible. It has no order at all, and "no order" must not be read as "an archived one".

---

# K — Two flows end to end

## K1 · The happy road

```
1. order 1204 → «نواقص», short 30 kg      N41 created · جديد · unassigned
2. supervisor assigns محمد                جاري البحث · محمد notified
3. محمد buys 20 kg for 500 نقدي           supplied 20 · remaining 10 · invoice +20
4. محمد buys 10 kg for 260 حوالة          supplied 30 · remaining 0 · مكتمل · invoice whole
```

**المطلوب ٣٠ · المتوفر ٣٠ · المتبقي ٠ · المدفوع ٧٦٠٫٠٠**

## K2 · The road that ends in «غير متوفر», then does not

```
1. order 1204 → «نواقص», short 30 kg      N41 · جديد
2. assigned to محمد                       جاري البحث
3. محمد cannot find it anywhere           غير متوفر            ← the brief's other ending
4. three weeks later a supplier has 30    POST .../supplies    → جاري البحث, then مكتمل
```

Step 4 is the path the brief does not mention and the shop will need. Refusing it would send the
employee to open a second shortage for the same sack — the shortest road to exactly the
duplication §١٠ exists to prevent.

---

# D11–D14 · The supply moves stock

> Added 2026-09-13. Recording a supply now posts the goods onto a shelf — see
> [SHORTAGES-DESIGN §٧٫٥](SHORTAGES-DESIGN.md). Everything in groups A–K above still holds; these
> are the cases the change adds.

## D11 · A purchase lands on a shelf and opens a cost layer

```
Before   N41 · required 30.000 · remaining 30.000 · جاري البحث
         warehouse #3 · shelf «كيس شحن 25*35» · 0.000
```

```http
POST /api/v1/shortages/41/supplies
{ "quantity": "30", "amount": "760", "method": "bank_transfer",
  "reference": "TR-5521", "warehouse_id": 3 }
```

**201**

```jsonc
{ "id": 77, "kind": "purchased",
  "quantity": "30.000", "amount": "760.00", "method": "bank_transfer",
  "warehouse_id": 3, "warehouse": { "id": 3, "name": "المخزن الرئيسي" },
  "stock_movement_id": 912, "moved_stock": true,
  "is_reversible": true }
```

```
After    stock_movements  + PurchaseArrival · 30.000 · to warehouse #3 · ref order 1204
         stock_batches    + layer · unit_cost 25.333 · received 30.000 · remaining 30.000
         warehouse_stocks   shelf 0.000 → 30.000
         N41                supplied 30.000 · remaining 0.000 · paid 760.00 · مكتمل
         order line 3310    shortage_quantity → null
```

> **760 ÷ 30 = 25.333, derived and never accepted.** A person knows what they handed over, not
> what one kilo worked out at — the same direction `PurchaseOrderItem` takes with
> `base_total_cost`. Asking for a unit price invites a figure that multiplies back to a different
> total.

## D12 · …and the order can then actually be made

The case the whole change exists for.

```
Before   order 1204 wants 300 · shelf holds 270 · N41 short 30
```

```http
POST /api/v1/shortages/41/supplies
{ "quantity": "30", "amount": "760", "method": "cash", "warehouse_id": 3 }
```

```
After    shelf 270.000 → 300.000
         producedQuantity() = 300.000      ← what «جاهزة» will ask for
         shortage_quantity  = null          ← and the invoice is whole again
```

The order moves on and `DeductOrderStock` finds the full 300 waiting.

> **Before this change the same sequence ended in a refusal.** The shortage closed, the line
> cleared, and the order was then rejected at «جاهزة» with `OrderStockShortfall` — a message
> about a balance that said nothing about the purchase made a week earlier.

## D13 · A stockable shortage without a warehouse

```http
POST /api/v1/shortages/41/supplies
{ "quantity": "30", "amount": "760", "method": "cash" }
```

**422**

```jsonc
{ "errors": { "warehouse_id":
    ["المخزن مطلوب — البضاعة المشتراة تدخل المخزون لتُخصم منه الطلبية"] } }
```

Nothing is written: no money row, no movement, `supplied_quantity` still `0.000`.

> This is D12's failure moved to the moment somebody can still fix it. The alternative is a
> refusal a week later, on a different screen, about a balance.

## D14 · A free-text shortage — money, no stock

```
N42 · «شريط لاصق عريض» · 12 قطعة · no product, so no shelf
```

```http
POST /api/v1/shortages/42/supplies
{ "quantity": "12", "amount": "45", "method": "cash" }
```

**201**

```jsonc
{ "quantity": "12.000", "amount": "45.00",
  "warehouse_id": null, "stock_movement_id": null, "moved_stock": false }
```

```
After    N42 · supplied 12.000 · paid 45.00 · مكتمل
         stock_movements  — nothing
```

And sending a warehouse on one of these is refused, rather than ignored:

```http
POST /api/v1/shortages/42/supplies   { …, "warehouse_id": 3 }
```

**422** «هذا النقص ليس صنفاً في المخزون — تُسجَّل قيمته بلا إدخال مخزني»

> A misunderstanding worth naming: the caller believes goods are about to move. Accepting it
> silently would leave the money row claiming an arrival that never happened.

## D15 · Reversing a purchase takes the goods back off the shelf

```
Before   N41 · supplied 30.000 · paid 760.00 · مكتمل
         shelf 30.000 · layer remaining 30.000
```

```http
POST /api/v1/shortages/41/supplies/77/reversal
{ "reason": "أُدخلت مرتين" }
```

```
After    stock_movements  + ArrivalReversal · 30.000 · from warehouse #3
         warehouse_stocks   shelf 30.000 → 0.000
         N41                supplied 0.000 · paid 0.00 · جاري البحث
         ledger             both rows kept — the mistake and its correction
```

**And it can be refused, by Inventory rather than by shortages:**

```
422   the layer has already been drawn on by an order
422   the layer was repriced by hand
```

> Those are the ledger's own guards, inherited unchanged. Nothing in Inventory was altered to
> accommodate shortages — the reversal uses the same `arrivalReversal` the vendor screen uses.
> If the sacks are already inside a customer's order, they cannot be un-bought.

---

# L · Filling the «نواقص» form from the shelves

> Two reads on the **order** side. Neither changes how a status move behaves: the deduction
> refuses exactly what it always refused.

## L1 · The hint on the shortage form

```http
GET /api/v1/orders/1204
```

Inside `available_transitions` → `shortage` → `fields`:

```jsonc
{ "key": "shortage_3310",
  "label": "الناقص من 25*35 (كجم)",
  "max": 300,
  "hint": "من أصل 300.000 — المتوفر في كل المخازن 270.000 كجم — يُخصم من الفاتورة" }
```

Render it as sent. **The box stays empty** — the balance is a record, the shortage is an
observation, and they disagree exactly when this screen matters.

## L2 · A size the warehouse does not carry

```jsonc
{ "key": "shortage_3311",
  "hint": "من أصل 300.000 — يُخصم من الفاتورة" }
```

No stock clause at all. «المتوفر ٠» about something that was never stocked is a fact about the
catalogue, not about today.

## L3 · Asking what a warehouse is short of

```http
GET /api/v1/orders/1204/stock-shortfall?warehouse_id=3
```

**200**

```jsonc
{ "warehouse_id": 3,
  "available_scope": "warehouse",
  "is_short": true,
  "lines": [
    { "line_id": 3310, "name": "كيس شحن — 25*35", "variant_label": "25*35",
      "unit": "piece", "unit_label": "قطعة",
      "required": "300.000", "available": "270.000",
      "suggested_shortage": "30.000" }
  ] }
```

`suggested_shortage` is what goes in that line's box. The app offers «سجّلها كنواقص», prefills,
and posts the **existing** `PATCH /orders/1204/status` — there is no new write path.

## L4 · Without naming a warehouse

```http
GET /api/v1/orders/1204/stock-shortfall
```

```jsonc
{ "warehouse_id": null, "available_scope": "all_warehouses",
  "lines": [ { "available": "270.000", "suggested_shortage": "30.000" } ] }
```

150 in one site plus 120 in another is 270 — and **not** 270 anybody can pick from one shelf.
`available_scope` exists so the screen can say so.

## L5 · Two lines drawing on one shelf

```
shelf holds 250 · line A wants 200 (sort 0) · line B wants 100 (sort 1)
```

```jsonc
{ "is_short": true,
  "lines": [
    { "line_id": 3310, "required": "200.000", "suggested_shortage": "0.000" },
    { "line_id": 3311, "required": "100.000", "suggested_shortage": "50.000" }
  ] }
```

The earlier line fills first; the later one absorbs the whole 50.

> **The only real difficulty in either read.** A shortfall is a fact about a *pile*, a shortage is
> recorded against a *line*, and two lines can draw on one pile — which is why `StockShortfall`
> names the shelf rather than a product. Whichever way the 50 is split the order is short by 50,
> so the server picks a rule that is **predictable** and lets a person move it between lines
> before saving. The split is a suggestion; the total is the fact.

## L6 · Reading it without the shortage grant

A user holding `orders.view` but not `orders.status.shortage`:

**403**

> The one thing this read is for is declaring a shortage. Whoever may not do that has no use for
> the suggestion.

## L7 · An order the shelf covers

```jsonc
{ "is_short": false,
  "lines": [ { "required": "300.000", "available": "500.000",
               "suggested_shortage": "0.000" } ] }
```

Every line reported, zeros included — a line missing from the answer would read as «this one is
fine», which is the same sentence said less clearly.
