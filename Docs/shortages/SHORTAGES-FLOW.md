# النواقص — the flow, worked end to end

> Every path the feature can take, with real numbers. The *why* behind each rule is in
> [SHORTAGES-DESIGN.md](SHORTAGES-DESIGN.md); this file is the *what happens*.
>
> Backend is built and green (70 tests). The app is not built — see
> [SHORTAGES-FRONTEND-INTEGRATION.md](SHORTAGES-FRONTEND-INTEGRATION.md).

---

## ٠. The two numbers to keep straight

Everything in this document is easier once these are distinct:

| | `order_items.shortage_quantity` | `shortages.required_quantity` |
| --- | --- | --- |
| Lives on | the order line | the shortage record |
| Means | **what is still missing right now** | **what was missing in total** |
| Effect | subtracted from the customer's invoice | none — it is a target to chase |
| Written by | `SetOrderShortages` only | the reconciliation only |

They are bound by one equation, and it holds at every moment:

```
required_quantity  =  order_item.shortage_quantity  +  Σ live supplied
```

**"Live" excludes reversals and the rows they undo.** A reversal is stored with a *positive*
quantity, so a plain sum of the ledger would count a purchase and its undoing as two arrivals.

---

## ٠٫٥. Where the goods come from — the question that shaped the rest

A shortage is not a note about missing stock; it ends with **stock actually arriving**. That is
forced by the order machine rather than chosen:

```
order in «نواقص»  ──► every shortage_quantity must reach 0 before it may leave
       │
       ▼
order at «جاهزة»  ──► DeductOrderStock takes producedQuantity() = the FULL ordered amount
                      (it knows nothing about shortages)
       │
       ▼
       shelf must cover it, or OrderStockShortfall refuses the move
```

So sacks bought to cover a shortage **have to reach a warehouse**. Recording a supply is
therefore the thing that puts them there — one purchase, one record — rather than a money note
beside a separate stock document that nothing links to it.

Three consequences run through every scenario below:

| | |
| --- | --- |
| **Cost** | The arrival opens a layer at `amount ÷ quantity`. The order draws it, so the money reaches `cost_of_goods_sold.material` in the P&L — the only road to that report before an accounting context exists. |
| **The free-text case** | «شريط لاصق عريض» has no size, so no shelf. Money is recorded, nothing moves, and it is an expense with nowhere to go until there is a ledger. Said out loud rather than pretended. |
| **Inventory itself** | Unchanged. The arrival goes through the door every other context uses, as an ordinary `PurchaseArrival`. |

---

## ١. The main road — §٥ of the brief, with numbers

An order for 300 كيس شحن. The warehouse is 30 kg short.

### Step 1 — the order enters «نواقص»

The clerk moves order **1204** to «نواقص» and types `shortage_3310 = 30`.

The form shows what the shelves hold while he types:

```
الناقص من 25*35 (كجم)
من أصل 300.000 — المتوفر في كل المخازن 270.000 كجم — يُخصم من الفاتورة
```

> **A hint, never a default.** The balance is a *record*; the shortage is an *observation*, and
> the two disagree exactly when this screen matters — a miscount, breakage, stock promised
> elsewhere. Pre-filling would turn «كم الناقص؟» into «أكّد ما يقوله النظام».
>
> «في كل المخازن» because at this moment the order has no warehouse: «نواقص» is reachable only
> from «جديد», and `fulfillment_warehouse_id` is not written until stock leaves. A cross-site sum
> is the weaker fact and is labelled as one.

```
order_items[3310].shortage_quantity  =  30.000     ← the invoice drops by 30 kg's worth
```

`SetOrderShortages` fires `OrderShortagesRecorded(1204, reason: declared, actor: 2)`.
The listener runs the reconciliation, which creates:

```
N41   كيس شحن — 25*35     required 30.000   supplied 0.000   remaining 30.000
      paid 0.00           status جديد        assignee —       source من طلبية · 1204
```

**Unassigned on purpose.** An order that lands in «نواقص» at two in the morning belongs to
nobody; quietly assigning it to whoever moved the order would put work in a queue they never
agreed to take.

### Step 2 — a supervisor assigns it

`PATCH /shortages/41/assignee  { "assigned_to_user_id": 6 }`

```
status    جديد → جاري البحث          ← «لم تبدأ متابعته بعد» stopped being true
assignee  محمد
```

محمد gets one notification. **Had محمد assigned it to himself, he would get none** — he watched
it happen on his own screen.

### Step 3 — partial supply: 20 kg for 500 د.ل, cash

`POST /shortages/41/supplies  { quantity: "20", amount: "500", method: "cash", warehouse_id: 3 }`

Four things happen in one transaction:

```
1. warehouse   + PurchaseArrival · 20.000 kg · layer at 25.000/kg   ← the sacks land on a shelf
2. ledger      + { purchased · 20.000 · 500.00 · كاش · محمد · 2026-09-11 · warehouse #1 }
3. shortage      supplied 20.000   remaining 10.000   paid 500.00   status جاري البحث
4. order         order_items[3310].shortage_quantity  30.000 → 10.000
                                                      ↑ the customer is billed for the 20 again
```

> **Step 1 is the one that makes the rest possible.** The order draws the *full* 300 off the shelf
> when it reaches «جاهزة» — `producedQuantity()` knows nothing about shortages — so sacks that
> never reached the warehouse would leave the order refused with `OrderStockShortfall`. Posting
> the arrival here also carries the money into `cost_of_goods_sold.material`, which is the only
> road to the P&L that exists before an accounting context does.

Step 3 fires the event again, which re-runs the reconciliation:

```
required = 10.000 (line) + 20.000 (supplied) = 30.000     ← unchanged. The loop terminates.
```

> **This is the whole reason the equation adds back what was supplied.** Reading `required`
> straight off the line would have made it 10, `remaining` would read 0, and the shortage would
> look finished with 10 kg still owed.

### Step 4 — the rest: 10 kg for 260 د.ل, bank transfer

```
warehouse  + PurchaseArrival · 10.000 kg · layer at 26.000/kg
ledger     + { purchased · 10.000 · 260.00 · المصرف · محمد · 2026-09-12 · warehouse #3 }
shortage     supplied 30.000   remaining 0.000   paid 760.00   status مكتمل
order        order_items[3310].shortage_quantity  10.000 → null
             the invoice is back to its original total
```

The shelf now holds the 30 that were missing, so the order can be moved on and
`DeductOrderStock` will find the full 300 waiting for it.

The detail screen now reads exactly §٩ of the brief:

```
إجمالي المطلوب ٣٠ كجم · إجمالي المتوفر ٣٠ كجم · المتبقي ٠ كجم · إجمالي المدفوع ٧٦٠ د.ل

الكمية   القيمة    طريقة الدفع   الموظف   التاريخ
٢٠ كجم   ٥٠٠ د.ل   نقدي          محمد     ٢٠٢٦-٠٩-١١
١٠ كجم   ٢٦٠ د.ل   المصرف        محمد     ٢٠٢٦-٠٩-١٢
```

**«مكتمل» was never chosen.** No API call set it and no dropdown offers it — the arithmetic wrote
it the moment `remaining` hit zero.

### The other ending

If محمد cannot find it:

`PATCH /shortages/41/status { "status": "unavailable" }` → «غير متوفر».

**That is not the end of the road.** See scenario **D4**.

---

## ٢. Every scenario

### A — Creating

| # | Scenario | Result |
| --- | --- | --- |
| **A1** | Manual, with a catalogue product | `source: يدوي`, `جديد`, `is_editable: true` |
| **A2** | Manual, free text («شريط لاصق») | Same. **The product link is optional** — what gets written by hand is often not in the catalogue |
| **A3** | Manual, assigned at creation | Allowed, and it starts on «جديد» — the status only advances through the assign endpoint |
| **A4** | Manual, quantity `0` | **422** «الكمية الناقصة يجب أن تكون أكبر من صفر» |
| **A5** | Order → «نواقص», one line short of 20 | One shortage of 20 |
| **A6** | Order → «نواقص», 3 lines: 20 short, fine, 10 short | **Two** shortages — 20 and 10. The available line produces nothing |
| **A7** | Order-born shortage created via `POST /shortages` | **Impossible.** The endpoint only ever writes manual ones |

> **A6 is the brief's own example.** «أكياس شحن ناقص ٢٠ · أكياس يد متوفرة · أكياس شفافة ناقص ١٠»
> → two records, each linked to its own line, its own customer and its own order.

### B — The duplicate guard (§١٠)

| # | Scenario | Result |
| --- | --- | --- |
| **B1** | Order moved to «نواقص» a second time, same 30 | **One** shortage, still 30. Not two, not 60 |
| **B2** | Clerk corrects the order 30 → 40 | The same record, `required` 40 |
| **B3** | Clerk corrects 30 → 20, nothing supplied | The same record, `required` 20 |
| **B4** | Two requests race to create it | The partial unique index on `order_item_id` refuses the second |

A guard in PHP is forgotten by the second code path; the index is not.

### C — Assignment

| # | Scenario | Result |
| --- | --- | --- |
| **C1** | Assign a «جديد» shortage | → «جاري البحث» + notification |
| **C2** | Assign one already «جاري البحث» | Assignee changes, status unchanged, new assignee notified |
| **C3** | Assign to yourself | Assignee set, **no notification** |
| **C4** | Unassign (`assigned_to_user_id: null`) | Assignee cleared, **status stays** — the chase started; it goes back to the pool open, not pretending it was never picked up |
| **C5** | Omit the field entirely | **422.** An omission is a bug; a null is a decision |
| **C6** | Assign with `shortages.manage` but not `.assign` | **403** — routing work is a different job from doing it |

### D — Supplying

| # | Scenario | Result |
| --- | --- | --- |
| **D1** | 30 of 30 | Completed, invoice restored in full |
| **D2** | 20 then 10 of 30 | Open at 10, then Completed. Total 760 د.ل (§١) |
| **D3** | 31 of 30 | **422** «الكمية (31) أكبر من المتبقي من النقص (30)». Buying extra for the shelf is a purchase order, not this |
| **D4** | Supply against a «غير متوفر» shortage | **Reopens to «جاري البحث»**, then the arithmetic completes it if the remainder reached zero |
| **D5** | Supply against a «مكتمل» shortage | **422** «النقص مكتمل». The way back is a reversal |
| **D6** | Quantity only, no amount/method | **422** on both fields. All three are required, in the form, in the types, and as a CHECK |
| **D7** | Supply on a **manual** shortage | Recorded. No order line to credit — nobody is billed for the tape bought for the workshop |
| **D8** | Supply when the order has reached «جاهزة» or later | **Recorded; the invoice is left alone.** The lines closed when the stock left the warehouse |
| **D9** | Supply when the order has been **archived** | **Recorded; the invoice is left alone.** The money still left the till |
| **D10** | Two clerks record the last 10 kg simultaneously | One succeeds; the other gets D3's 422. The row is locked before the ceiling is read |
| **D11** | A supply on a stockable shortage with no `warehouse_id` | **422** «المخزن مطلوب». Refused now rather than a week later at «جاهزة» |
| **D12** | A supply on a free-text shortage («شريط لاصق») | **201**, money recorded, **no stock moved** — there is no shelf for tape |
| **D13** | A `warehouse_id` sent on a free-text shortage | **422** «هذا النقص ليس صنفاً في المخزون». The caller believes goods are moving; they are not |

> **D11–D13 are new**, and they are why the feature works at all: a supply posts a
`PurchaseArrival` onto a shelf at `amount ÷ quantity`, so the order can draw the full quantity at
«جاهزة» and the cost reaches `cost_of_goods_sold.material`. Nothing in Inventory changed to allow
it — see SHORTAGES-DESIGN §٧٫٥.

**D8 and D9 are the two places the write-back silently does not happen, and both are correct.**
> A shortage still open after its order shipped was, by definition, not billed for. Re-billing it
> after the fact is a conversation with the customer, not a side effect of logging a purchase.

### E — The other door: the order screen

A colleague resolves the same shortage from the order, via `received_{itemId}` as the order
leaves «نواقص».

| # | Scenario | Result |
| --- | --- | --- |
| **E1** | 20 of 30 arrived | A `resolved_externally` row of 20 — **quantity only, no money.** Open at 10 |
| **E2** | All 30 arrived | A row of 30, → **مكتمل** |
| **E3** | 20 bought here, then the other 10 arrive via the order | Ledger holds both: a purchase of 20 (500 د.ل) and an arrival of 10 (no money). Completed, paid 500.00 |
| **E4** | Someone tries to reverse an `resolved_externally` row | **422** «لا تُعكس كمية وصلت من الطلبية — تُصحَّح من شاشة الطلبية» |

**Why the extra row exists:** without it, `required` would shrink on its own and the log would
show a shortage that closed with nothing recorded against it — «توفّر ٣٠ كجم» with no line saying
so.

### F — Withdrawing the claim

Both of these reach the server as the same write: the line goes to zero. They are told apart by
the **reason** the caller passes, not inferred.

| # | Scenario | Reason | Result |
| --- | --- | --- | --- |
| **F1** | Clerk mis-typed; corrects to «لا ينقص شيء». Nobody assigned, nothing spent, still «جديد» | `corrected` | **Soft-deleted.** A row nobody chased is noise on the board, not history |
| **F2** | Same correction, but somebody is assigned / it is «جاري البحث» / money was spent | `corrected` | **Kept.** An arrival is recorded and it completes — a person's work is not thrown away on an inference |
| **F3** | Order leaves «نواقص» with everything received | `received` | **Kept**, arrival recorded, completed (= E2) |

> **This was the one genuine gap found during the build.** The first implementation inferred it
> from the order's status, which reads one way under a `sync` queue and another under `database` —
> the same event meaning different things on a laptop and a server. The three callers already know
> which it is, so they say so.

### G — Reversing a supply

| # | Scenario | Result |
| --- | --- | --- |
| **G1** | Reverse the 20 kg / 500 د.ل purchase | A second row is written naming the first. `supplied` 20 → 0, `paid` 500 → 0. **Both rows stay in the table** |
| **G2** | The shortage was «مكتمل» | Reopens to **«جاري البحث»** — not «جديد»; the chase demonstrably started |
| **G3** | Reverse the same row twice | **422** «عملية التوفير معكوسة أصلاً» |
| **G4** | Reverse a reversal | **422** — undoing an undo is a third event nobody asked for. Record the purchase again if it really happened |
| **G5** | Reverse without a reason | **422.** «عُكست» with no sentence beside it answers nothing six months later |
| **G6** | Does the invoice get re-cut? | **No.** A reversal means the *entry* was wrong, not that sacks were taken back off a customer |
| **G7** | Reverse a row on someone else's shortage | **404** — the route scopes the binding |

### H — The order's lifecycle

| # | What happens to the order | Open, money spent | Open, nothing spent | Completed |
| --- | --- | --- | --- | --- |
| **H1** | «إلغاء تام» | → «غير متوفر», **money kept** | soft-deleted | **untouched** |
| **H2** | Deleted (archived) | → «غير متوفر», **money kept** | soft-deleted | **untouched** |
| **H3** | Restored | comes back at the same quantity | recreated by the sync | untouched |
| **H4** | A line is deleted off the order | kept, `order_item_id` cleared, snapshot name carries it | soft-deleted | untouched |

Two rules run through the whole table:

* **No supply is ever reversed by any of this.** `DeleteOrder` reverses *customer* payments
  because the P&L reads revenue and cash from different places; there is no such asymmetry here.
  The cash left the till and the goods exist.
* **Completed shortages are never touched** — «الاحتفاظ بالنواقص المكتملة كسجلٍّ تاريخي».

**H3 detail:** a restored order re-draws stock at *today's* cost layers, so it comes back priced
differently. A shortage quantity is a physical fact about sacks that are not on a shelf — it
carries no cost layer and returns exactly as it was.

**Manual shortages are untouched by every row of this table.** They belong to no order.

### I — Editing

| # | Scenario | Result |
| --- | --- | --- |
| **I1** | Edit a manual shortage's name / unit / quantity | Allowed |
| **I2** | Edit an order-born one | **422** «نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا من هنا» |
| **I3** | Cut a manual requirement from 30 to 10 after buying 20 | **422** «الكمية المطلوبة أقل مما تم توفيره فعلاً — اعكس عملية التوفير أولاً» |

I2 refuses rather than accepts because an edit there would survive until the next time anybody
touched that order and then vanish — and an employee who watches a correction disappear a day
later has no way of finding out why.

### J — Who can see what

| # | Reader | Shortage of a live order | Of an **archived** order | Manual |
| --- | --- | --- | --- | --- |
| **J1** | `shortages.view` | visible | **hidden everywhere** | visible |
| **J2** | `shortages.view` + `orders.archive.view` | visible | visible | visible |

"Hidden everywhere" means the list, **the chip-row counts**, the detail (403) and the history
(403). The counts matter as much as the list: a number that moves would leak the archive just as
surely, which is the failure mode the orders archive documented once already.

### L — Filling the form from the shelves

Two reads on the order side. Neither changes how a status move behaves — the deduction still
refuses exactly what it always refused.

| # | Scenario | Result |
| --- | --- | --- |
| **L1** | Opening the «نواقص» form | Each line's hint carries «المتوفر في كل المخازن …» beside «من أصل …» |
| **L2** | A size the warehouse does not carry | The hint has **no** stock clause — «المتوفر ٠» about something never stocked is a fact about the catalogue, not about today |
| **L3** | `GET orders/{id}/stock-shortfall?warehouse_id=3` | Per line: `required`, `available`, `suggested_shortage` |
| **L4** | The same without `warehouse_id` | Answers across every shelf; `available_scope: "all_warehouses"` |
| **L5** | Two lines drawing on one shelf | Earlier line fills first, the later one absorbs the shortfall — a **suggestion**, movable before saving |
| **L6** | Reading it without `orders.status.shortage` | **403** — the one thing it is for is declaring a shortage |

> **L5 is the only real difficulty.** A shortfall is a fact about a *pile*; a shortage is recorded
> against a *line*; two lines can draw on one pile. Whichever way it is split the order is short
> by the same total, so the server picks a predictable rule and lets a person move it.

---

## ٣. The status machine, complete

```
        ┌──────────────── assign ────────────────┐
        ▼                                        │
     جديد ──────────► جاري البحث ◄──────────► غير متوفر
        │                  │      supply/manual      │
        │                  │                         │
        └──────────────────┴─────────────────────────┘
                           │
                  remaining reaches 0
                           ▼
                        مكتمل        (arithmetic only — in no map)
                           │
                  a reversal reopens it
                           ▼
                      جاري البحث
```

| From | A person may choose |
| --- | --- |
| جديد | جاري البحث · غير متوفر |
| جاري البحث | غير متوفر |
| غير متوفر | جاري البحث |
| مكتمل | — |

Three properties worth stating plainly:

1. **«مكتمل» is in no map.** It is unrepresentable as a choice, not merely guarded.
2. **Nothing leads back to «جديد».** «لم تبدأ متابعته بعد» cannot become true again, so the
   board's first number never goes up for a reason nobody caused.
3. **«غير متوفر» is not final.** It reads like an ending and is not one.

---

## ٤. The brief's closing flow, mapped

> ظهور نقص → تسجيله تلقائيًا أو يدويًا → جديد → تعيين موظف → جاري البحث → تسجيل توفير →
> توفير جزئي عند الحاجة → مكتمل عند توفير كامل الكمية

| Brief | Where it happens |
| --- | --- |
| ظهور نقص | A5 / A1 |
| تسجيله تلقائيًا أو يدويًا | the reconciliation, or `POST /shortages` |
| جديد | the only starting status |
| تعيين موظف | C1 |
| جاري البحث | written by C1, or chosen |
| تسجيل توفير | D1 |
| توفير جزئي | D2 — and E1, from the other door |
| مكتمل | the arithmetic, never a choice |

> وفي حالة عدم إمكانية توفيره: جاري البحث → غير متوفر

Covered, plus the return journey the brief does not mention and the shop will need: **D4**, the
sack that turns up a month later.

---

## ٥. Where each acceptance criterion is satisfied

| Criterion | Where |
| --- | --- |
| قسم مستقل باسم النواقص | its own context, nine endpoints, five permissions |
| إنشاء نقص يدوي | A1–A3 |
| إنشاء تلقائي من الطلب | A5–A6 |
| على مستوى بند الطلب | A6 — one record per line |
| الحالات الأربع | §٣ |
| تعيين لموظف | C1–C6 |
| البحث والفلترة | name · code · order code · status · assignee · product · source · order · customer |
| تسجيل كمية تم توفيرها | D1 |
| إلزام الكمية + القيمة + طريقة الدفع | D6 — three layers: form, types, CHECK |
| التوفير الجزئي بأكثر من عملية | D2 |
| حساب المتبقي تلقائيًا | derived, never stored |
| التحويل لمكتمل تلقائيًا | the arithmetic is its only writer |
| سجل كامل لعمليات التوفير | the ledger, reversals included |
| ربط طريقة الدفع بالحساب المالي | **partial** — the method and amount are recorded; the ledger entry waits for `Domain/Accounting`. [BACKLOG § المحاسبة](../BACKLOG.md) |
| منع تكرار الخصم المالي | append-only + one reversal per entry, by index |
| منع تكرار النواقص | B1–B4, by index |
| الاحتفاظ بالمكتملة كسجل | H1–H4, right-hand column |
| تعديل/إلغاء الطلب ينعكس صحيحًا | B2 · F1–F3 · H1–H4 |

**One criterion is partially met and it is named as such.** «ربط طريقة الدفع بالحساب المالي عند
توفر نظام الحسابات» — the accounting context does not exist yet, so the condition in that sentence
is not met. The method and the amount are recorded against every purchase; the posting rule is one
call site the day the ledger lands.
