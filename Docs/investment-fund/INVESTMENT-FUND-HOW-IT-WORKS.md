# صناديق الاستثمار — how it works, with worked numbers

The companion to [INVESTMENT-FUND-DESIGN.md](INVESTMENT-FUND-DESIGN.md). That document says **why**
the system is shaped this way; this one walks through **what actually happens**, with figures you
can follow on a calculator.

Every number below is what the code produces. Where a figure looks surprising, the reason is given.

---

## The one-paragraph version

A **صندوق** is a continuous pot of money for **one material**. Partners put capital in; the pool
buys lorries of that material; the press and the customers buy from the shelf; and at the end of
every **فترة** — one month by default — whatever the pool made is worked out, divided by how much
capital each person had, and paid into their wallets. The pool never ends. Only its periods do.

The old **صفقة** was the opposite: one lorry, partners frozen on the day it was funded, closed when
the goods ran out.

---

## 1. Opening a صندوق

**Where:** «صناديق الاستثمار» in the side menu → **صندوق جديد**.

You give it a name, the shelves it buys, and optionally the investors' profit share. Nothing else —
**a pool is born empty**. No partners, no money, no purchase order.

> **Example.** You open «أكياس الشحن» over four shelves: 25×35, 35×40, 45×50, 50×60. You leave the
> profit share blank, so it takes the company default of **50%**. The pool gets the code **D2** and
> its first period opens immediately: **2026-09-20 → 2026-10-19**.

**Two refusals you may meet, and what they mean:**

| Message | Why |
|---|---|
| «المادة تتبع صندوقاً آخر» | Each shelf belongs to **exactly one** pool. This is what makes «من موّل هذه البضاعة؟» a question with one answer, and it is why nobody is ever asked to choose a pool when buying. |
| «المادة غير قابلة للاستثمار» | A product standing on that shelf is outside the investable headings. Fix the heading in «التصنيفات», not here. |

**حصة المستثمرين is asked once and frozen.** It is the term the partners were shown. Changing the
company default next year must not quietly re-cut a pool they are already in — so the field is not
offered when you edit a pool.

---

## 2. Putting capital in

**Where:** the pool's screen → **حركة رأس مال** → «إدخال رأس مال».

The money must already be in the investor's wallet as a deposit. This moves it from his wallet into
the pool.

**The grace window decides whether it works this month or next.** The default is **3 days**.

> **Example A — inside the window.** The period started on the 1st. On the **2nd**, أحمد puts in
> 60,000 and علي puts in 40,000. Both are inside the 3-day window, so the money is taken **now** and
> works for the whole month. The form says so before you press anything:
>
> ```
> داخل مهلة الدخول: المال يُحتسب من بداية الفترة الجارية (تنتهي المهلة 2026-10-03)
> ```

> **Example B — outside it.** On the **9th**, خالد offers 50,000. The window shut on the 3rd, so the
> request is **queued**:
>
> ```
> انتهت مهلة الدخول لهذه الفترة. المال يبقى في محفظة المستثمر ويبدأ عمله في 2026-11-01
> ```
>
> **His money has not moved.** It is still in his wallet, he can cancel, and he can spend it
> elsewhere. It joins the pool when the next period opens.

**Putting money in is also what makes him a partner.** The roster row — his name on «الشركاء»,
with «منذ» — is written the moment his capital lands, and never before: while a queued request sits
waiting, the money is in his own wallet and he is not in the pool. Topping up later does not move
that date; he has been in since the first time.

**Why the window exists at all:** ownership is a plain capital ratio, and a ratio is only exact if
capital does not move inside the period it is measured over. Let خالد in on the 9th and there is no
single honest weight for his month.

---

## 3. Buying a lorry with pool money

**Where:** the purchase order screen → **الشراء من مال الصناديق**.

**Nobody picks a pool.** Each material belongs to exactly one, so the only decision per line is
*pool money or the company's*. The storekeeper is asked nothing at receipt.

> **Example.** A purchase order has two lines: 6,000 units of 25×35 at 10 each (60,000), and 2,000
> units of a material no pool owns. You mark the first line for pool money and leave the second.
>
> - The 60,000 line is bought with D2's money. Its cost layers carry D2 for ever.
> - The other line is the company's, exactly as before.
>
> D2's position afterwards: **capital 100,000 · stock at cost 60,000 · قابل للصرف 40,000**.

**Refused if the pool cannot cover its whole share of the lorry** — «الصندوق لا يكفي». And refused
once a line has been received, because the cost layer is stamped at the gate and can never be
stamped afterwards.

### سعر السادة, per lorry

When you mark a line you may set **سعر السادة** — what the press pays the pool for a unit of its
plain stock.

> **Set to 32.** The moment a printed order draws 100 units of 25×35, the press buys them from the
> pool at 32 each. Cost was 10, so the pool earns **(32 − 10) × 100 = 2,200** there and then —
> before the customer has seen anything, and whatever happens to the order afterwards.

> **Left blank.** Those goods ride the sale instead: the pool is paid a share of the delivered
> order's profit, at «تم الاستلام».

**One pool may hold both at once.** The road is a property of the **layer**, not of the container —
a lorry bought with a price and the next one without it behave differently, correctly, side by side.

---

## 4. A normal month — the close

**Where:** the pool → **الفترات** → **أقفل الفترة**.

The screen prints the arithmetic **before** you press the button, and it is the same arithmetic the
button then performs.

> **Example.** September for D2. Capital: أحمد 60,000, علي 40,000, الشركة 0. Profit share 50%.
>
> ```
> مجمل الربح المحقق        12,000
> مصاريف مخصومة           − 1,000    (تخزين ونقل داخلي)
> تالف                     −   500
> نقص                      −     0
> ─────────────────────────────────
> صافي الربح                10,500
>
> محسوبة مسبقاً: 3,400      ← شحن وجمارك، داخلة أصلاً في تكلفة البضاعة
> ```
>
> **The 3,400 is shown and not subtracted.** It is already inside the cost of the layers that
> arrived; subtracting it again would charge the partners for one customs invoice twice.
>
> **The division.** Investors hold 100,000 of 100,000 capital, so their weight is 100%:
>
> ```
> حصة المستثمرين = 10,500 × 100% × 50%  =  5,250
> حصة الشركة     = 10,500 − 5,250        =  5,250   ← the remainder, never a second multiplication
>
>   أحمد  5,250 × (60,000 / 100,000)  =  3,150
>   علي   5,250 × (40,000 / 100,000)  =  2,100
> ```
>
> Those amounts are released into their **wallets**, where they can be withdrawn. The next period
> opens in the same breath: **2026-10-01 → 2026-10-31**.

### Does the period close itself when the date comes? **No.**

Nothing closes a period but a person. The date is not a deadline the system enforces; it is one it
**reports**.

A period past its end stays open and goes on accruing — October's sales land in September's period
until somebody presses the button. **The arithmetic stays correct**; what stops being true is only
that the dates describe the contents. So the screen says so:

```
⚠ 2026-09-01 — 2026-09-30
  مفتوحة · متأخرة 12 يوماً
  فيها بضاعة راجعة لم تُفحص — أجب عنها من شاشة الصندوق قبل الإقفال
                                          [أقفل الفترة]
```

> **Why there is no nightly job.** A close divides profit, writes losses against capital, releases
> money into wallets it can be withdrawn from that afternoon, and pays out exits — and it is
> legitimately refused while a returned-goods question is unanswered. A schedule doing that at
> three in the morning, or failing silently every night with nobody watching, is worse than a mark
> on a screen. The blocker is named **where the button is**, so it is cleared rather than
> discovered by pressing.

**Undrawn profit is never working capital.** Once it is in a wallet it is that person's money. The
pool's screen shows «قابل للصرف» and «ربح غير موزَّع» **side by side and never as a total**.

---

## 4b. Entering an expense

**Where:** the pool's screen → **المصاريف** → «سجّل مصروفة».

Five kinds — تخزين, نقل, شحن, جمارك, أخرى — with an amount, a date and a description.

**The date is for the record; the deduction lands on the period that is open now.** A closed period
is immutable, so an invoice bearing last month's date is charged to this month and keeps its true
`incurred_on` with a note saying where it was meant for. Back-dating into a closed month would
rewrite a division that has already been paid into wallets.

> **The warning that matters.** Pick **شحن** or **جمارك** and the form says so before you type a
> figure:
>
> ```
> إن كان الشحن أو الجمارك مكتوباً على أمر الشراء فهو داخل أصلاً في تكلفة البضاعة،
> ويُسجَّل هنا دون أن يُخصم مرة ثانية.
> ```
>
> Freight typed on a purchase order is **landed** — already inside the cost of the layers that
> arrived. Recording it again does not charge it twice (the server refuses to deduct it), but it
> does put a figure on the close screen under «محسوبة مسبقاً» that somebody will ask about.
>
> **Whether a cost is deducted is the server's decision, never the form's.**

---

## 4c. «كم حصتي؟» — two different numbers, and they are not interchangeable

**On the pool's screen, beside each partner** — his weight *as it stands today*:

```
أحمد    60٪    60,000
علي     40٪    40,000
```

Derived on every read and stored nowhere. It moves the moment anybody's capital moves, and it is
what the **next** close would apply if it happened now.

**On a closed period — «الفترات» → «من أخذ ماذا»** — the weight that *was* applied and the amount
that *was* paid:

```
أحمد        3,000
   رأس ماله 60,000 · نسبته 60٪ من حصة المستثمرين
علي         2,000
   رأس ماله 40,000 · نسبته 40٪ من حصة المستثمرين
الشركة      5,000
   حصة الشركة — الباقي بعد حصة المستثمرين
```

Frozen the day the period closed, and **never recomputed**.

> **Why they must stay apart.** «لماذا أخذت هذا المبلغ في سبتمبر؟» asked in December, after three
> more months of capital moving — answering it with December's weights would answer a different
> question. The first number tells you where you stand; the second tells you what happened.

**The company's percentage reads 100 and that is correct**: its take is the *residual* of the
division, not a slice of the investors' half. The figure that means something for it is the amount.

---

## 5. A losing month

> **Example.** October: the pool realized 2,000 but a damaged pallet cost 6,000.
>
> ```
> مجمل الربح المحقق         2,000
> تالف                     − 6,000
> ─────────────────────────────────
> صافي الربح                −4,000
> ```
>
> The loss is **written down against capital in this pool, and nothing else**:
>
> ```
>   أحمد   −4,000 × 50% × (60,000/100,000)  =  −1,200  → capital becomes 58,800
>   علي    −4,000 × 50% × (40,000/100,000)  =    −800  → capital becomes 39,200
>   الشركة  the remaining −2,000                         → its own capital
> ```

**Three rules the code holds to:**

1. **Capped at what he put in.** Nobody ever owes more than his capital. A shortfall beyond it is
   written off to the company as a named line — «خسارة تحمّلتها الشركة» — so it appears on his
   statement instead of vanishing into a difference nobody can name.
2. **Never carried forward.** November starts clean. A loss is settled in the period it happened.
3. **Never crosses pools.** A loss in «الحبر» cannot touch his capital in «أكياس الشحن».

---

## 6. A cancelled printed order — «صالحة أم تالفة؟»

This is the one fact the system **cannot** work out for itself, and the one place it stops and asks.

> **Example.** Order 1290 was printed on 300 units of 25×35 drawn from D2, then the customer
> cancelled. The material is credited back to the shelf — **as good stock**, because a stock movement
> records a quantity and not whether there is ink on it.
>
> The pool's screen shows, above everything else:
>
> ```
> ⚠ بضاعة راجعة تنتظر الفحص — لن تُقفَل الفترة قبل الإجابة عنها
>    أكياس الشحن 25*35 · طلبية 1290 · 300.000 · بتكلفة 3,000     [افحص]
> ```
>
> - **«صالحة»** → nothing is written. The goods really are back and really are usable; all that
>   changed is that somebody looked.
> - **«تالفة»** → 300 units leave the shelf as a damage adjustment, and the 3,000 lands in the
>   period's «تالف» by the ordinary road.

**Why «تالفة» posts a stock movement and not an expense:** booked as a cost alone, the pool would go
on counting goods it does not have, its «قابل للصرف» would be overstated by 3,000, and the next lorry
would be bought with money that was never there.

**The question is only raised where it is real.** Not for سادة (sold off the shelf as it stands,
never printed), not for وسيط (never touched a shelf of ours), and not for priced material (paid for
the day it left — its cancellation hands those goods to the company). A prompt with one possible
answer is noise, and noise is what teaches people to click through the prompts that matter.

---

## 7. An investor wants to leave

**Where:** the pool → **حركة رأس مال** → «سحب رأس مال».

**Two gates, and they are different things.**

### Gate 1 — the minimum term (الحد الأدنى للبقاء), currently **6 months**

> **Example.** أحمد's first capital went in on **2026-03-15**. On **2026-06-01** he asks to leave:
>
> ```
> رأس المال في «أكياس الشحن» لا يُسحب قبل 6 شهراً من دخوله —
> يمكن طلب السحب ابتداءً من 2026-09-15
> ```
>
> The same date is shown on the pool's «الشركاء» list before he ever asks.

- Counted from his **first** money in. A top-up does **not** restart the clock — otherwise paying
  more in would be a reason to be locked in longer.
- Money he took out **entirely** and later put back starts again. It is new money.
- **The company is exempt.** It is the operator, it absorbs the losses that run past a partner's
  capital, and its money in the pool is working capital it has to be able to move.
- Set to **0** and there is no term at all.

### Gate 2 — he is paid out of the **cash**, and only his **own slice** of it

An exit is **always queued**, never immediate, and executes at the close **after** that period's
profit has been divided — so a man who says in September that he wants out is still paid his
September share.

> **Example.** D2 holds 100,000 capital: 60,000 in stock, **40,000 in cash**. أحمد owns 60%, علي 40%.
> Both ask to withdraw everything.
>
> ```
> أحمد's ceiling  = min( 60,000 , 40,000 × 60% )  =  24,000
> علي's ceiling   = min( 40,000 , 40,000 × 40% )  =  16,000
> ```
>
> Both asked for more than their ceiling, so **neither is paid** and both requests roll to the next
> close. If أحمد had asked for 20,000 he would have been paid it, and علي's 16,000 would still be
> waiting there for him.

**Why the slice and not the pool's whole cash:** without it, whoever queued first could take all
40,000 and leave the other waiting on a lorry selling. Same pool, same month, same right to leave —
and the only thing deciding it was the order they walked in. The weights are taken **once, before
anybody is paid**, so the split does not depend on the queue.

> **«لا يسحب حتى لا يبقى له شيء في البضاعة» was considered and rejected.** Taken literally it means
> an investor may leave only when the pool holds **zero** stock — and a working pool always holds
> stock. Nobody would ever be able to leave. The cash ceiling above is what that instinct was
> reaching for.

---

## 8. The settlement — «هل الدفاتر تطابق البضاعة؟»

**Where:** the pool → **التسويات**.

A settlement **moves no money**. It does not close the pool, does not liquidate stock, and does not
touch a period. It is a dated, signed statement of where the money is — and the **فرق**.

**The «فرق» is the only figure on that screen you cannot read anywhere else**, because it is a
comparison of two derivations that never consult each other:

```
من الدفاتر   =  رأس المال + الربح غير الموزَّع              ← the wallet ledger and the periods
من الحركات   =  ما دخل − ما خرج + الأرباح − الموزَّع
                − المصاريف − ثمن كل بضاعة اشتُريت
                + ثمن كل بضاعة بِيعت + البضاعة على الرف     ← the cost layers and the draw ledger

الفرق        =  الأول − الثاني
```

In a healthy pool they agree **to the fils**.

> **Example of a real finding.** Somebody wrote 500 units off the shelf through «تسويات المخزون» in
> a period that has since closed. The goods left, but no loss was ever charged to anybody — the
> period that would have charged it is immutable.
>
> ```
> ⚠ يوجد فرق غير مفسَّر              5,000
> أرقام الدفاتر لا تساوي ما تعطيه الحركات. الغالب أن بضاعة خرجت من الرف
> بتسوية مخزنية لم تُحمَّل على أحد. الفرق يُسجَّل ولا يُعالَج تلقائياً.
> ```
>
> **Nothing else in the system would ever have mentioned it.**

**The drift is written down and left standing.** There is a strong pull towards posting an
adjustment that makes it zero — and that would destroy the only thing the record is for. A drift is
a question about goods on a shelf; it is answered by somebody going and looking.

Three named lines beside it that are **not** drift:

| Line | What it is |
|---|---|
| ربح الفترة الجارية غير الموزَّع | Real money the pool is holding that «قابل للصرف» does **not** count as spendable. Shown beside it, never added to it. |
| مستحقات على الزبائن | Booked as earned, not yet collected. Profit is recognised at delivery, so an order sold on credit counts as cash everywhere else — this is the size of that assumption. |
| أرباح مستحقة لم تُسحب | Money the company holds and does not own. Never working capital. |

---

## 9. Where the company stands

The company is **a partner in each pool like any other** — one reserved investor row — *and* it takes
the operator's cut out of every pool.

That is why the division in §4 has two steps rather than one: the investors' weight decides their
half, and the company takes the remainder. It needs no new machinery at all — the company's money
flows through the same ledger, takes the same capital weight, and appears on the same period share
table.

**If there is no company investor row, its cut is computed and has nowhere to go** — and the
settlement will report exactly that amount as drift. Every live pool should have one.

---

## 10. What the old صفقة does now

**Nothing was destroyed.** Every existing deal keeps its rows, its wallet entries, its expenses, its
stock tags and its audit trail, and every deal screen still opens.

- A **closed** صفقة is history and reads exactly as it always did.
- An **open** one goes on running: its layers keep selling, and its partner keeps earning from them.
- **All new money goes through a صندوق.**

> **What we actually did with D1.** It held 579 units and had 7 orders in flight. Rather than
> migrate it, we opened **D2 «أكياس الشحن»** over the same four shelves and left D1 alone. New
> lorries open D2 layers; FIFO keeps drawing D1's **older** layers first, so D1 drains while its
> partner goes on earning from it. When it is empty and those seven have delivered, it closes the
> ordinary way and his capital returns to his wallet — from where he can put it into the pool.
>
> No migration script ever runs on live money.

---

## The settings that govern all of it

«إعدادات الاستثمار» in the side menu. **Global — one calendar for every pool**, so a close is one
action rather than a date remembered per pool.

| Setting | Now | What it does |
|---|---|---|
| حصة المستثمرين من الربح | 50% | Copied into a pool the day it opens and **frozen there**. Changing it does not touch an existing pool. |
| مدة فترة الأرباح | 1 شهر | How long a period runs before it is closed and divided. |
| مدة التسوية | 6 أشهر | The review cycle. Drives «التسوية القادمة» and the overdue mark. |
| مهلة دخول رأس المال | 3 أيام | How long into a period capital may still join **that** period. `0` = strict boundary. |
| الحد الأدنى للبقاء | 6 أشهر | Before an investor may **ask** to withdraw. `0` = no term. The company is exempt. |

**A change here can only ever affect the future.** «Next close» and «next settlement» are derived,
never stored — so a closed period is unreachable from this screen by construction rather than by a
guard somebody has to remember.
