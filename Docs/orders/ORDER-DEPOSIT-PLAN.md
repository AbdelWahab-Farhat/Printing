# Deposit statuses — «انتظار العربون» and «عربون مدفوع» — implementation plan

> **Status: the backend is implemented and tested. The app is deliberately untouched** — its
> work is specified in
> [ORDER-DEPOSIT-FRONTEND-INTEGRATION.md](ORDER-DEPOSIT-FRONTEND-INTEGRATION.md), which
> supersedes §4.3 below. The permanent Arabic record of what shipped is
> [ORDER-DEPOSIT.md](ORDER-DEPOSIT.md).
> Branch: `feature/order-deposit-statuses`. Detected environment: **local development**
> (`APP_ENV=local`, `APP_URL=http://localhost:8000`, `DB_DATABASE=printing`).
> Written in English by request; the user-facing strings it specifies stay Arabic, and the
> permanent documentation that ships with the feature should be Arabic like the rest of `Docs/`.

---

## 1. Goal, as stated

1. Add two order statuses: **«انتظار العربون»** (awaiting deposit) and **«عربون مدفوع»** (deposit paid).
2. Moving an order **into «انتظار العربون»** captures an **estimated deposit amount** and the
   **method the deposit is expected to arrive by**.
3. That expectation is *treated as a payment*: when the order moves to **«عربون مدفوع»** the payment
   is recorded in the ledger like any other payment, and if the move is walked back the payment is
   **reversed**.
4. Add a boolean **`is_deposit_received`** on the order so accounting can check it later.

**Settled since the first draft** (each is written into the section it governs):

- The flag is **not derived from the ledger**. It starts `false` and an employee ticks it — §3.5.
- It is **never asked for during the status change**, and may be ticked any time afterwards — §3.5.
- **Two different people**: whoever moved the order to «عربون مدفوع» may not confirm it — §3.5.
- **The flag blocks nothing.** No status, no production step, no dispatch and no settlement reads
  it; an order at `false` walks the whole road normally — §3.5, and test 17 pins it.

---

## 2. What already exists, and what this plugs into

Everything this feature needs already has a home. Nothing here invents a new mechanism.

| Concern | Where it lives today |
|---|---|
| The state machine | [`OrderStatus`](../../backend/app/Domain/Order/Enums/OrderStatus.php) — cases, labels, `allowedNext()` per `OrderFlow`, `permission()`, `timestampColumn()`, `mainLine()` |
| Fields a move asks for | [`TransitionFields::for()`](../../backend/app/Domain/Order/Support/TransitionFields.php) + [`TransitionField`](../../backend/app/Domain/Order/DTOs/TransitionField.php) — the description **and** the validation are one object |
| Money asked for during a move | `TransitionFields::money()` — `payment_amount` · `payment_method` · `payment_receipt`, today only on «تم الاستلام» / «تم التسوية» ([PAYMENT-AT-STATUS-CHANGE.md](../payments/PAYMENT-AT-STATUS-CHANGE.md)) |
| Recording a payment | [`RecordOrderPayment`](../../backend/app/Domain/Order/Actions/RecordOrderPayment.php) — locks the order, refuses more than the remaining, stores the receipt |
| Reversing one | [`ReverseOrderPayment`](../../backend/app/Domain/Order/Actions/ReverseOrderPayment.php) — writes a `reversal` entry pointing at the original |
| The only writer of `paid_amount` | [`RecalculateOrderPayments`](../../backend/app/Domain/Order/Actions/RecalculateOrderPayments.php) — sums the live ledger |
| Status-change orchestration | [`ChangeOrderStatus`](../../backend/app/Domain/Order/Actions/ChangeOrderStatus.php) — one transaction per move, already records a payment mid-move |

Two consequences worth stating up front:

- **The three field types the deposit screen needs — `number`, `payment_method`, `file` — already
  exist on both sides.** So the *fields* need no app release. Only the two new *statuses* do
  (label, tone, icon), and an app that has not been updated degrades gracefully: `OrderStatus.unknown`
  + the server's `status_label` + a neutral chip.
- **`orders.status` is `string(30)`** — `awaiting_deposit` (16) and `deposit_paid` (12) fit. No
  migration is needed for the status column itself.

---

## 3. The decisions — recommendation and options

Six decisions carry the design. Each gives the recommendation first, then what was rejected and why.

### 3.1 Where the two statuses sit in the map

**Recommendation — an optional detour off «جديدة» that rejoins the road it left.**

```
جديدة ──┬──→ (the existing arms: جاهزة للطباعة / قيد التصميم / قيد التصنيع / جاهزة / نواقص)
        └──→ انتظار العربون ──→ عربون مدفوع ──→ (exactly the arms جديدة offers for this flow)
                   ↑                  │
                   └──────────────────┘   (walking it back — see §3.4)
```

Concretely, per `OrderFlow`:

| Flow | `New` gains | `AwaitingDeposit` → | `DepositPaid` → |
|---|---|---|---|
| `Standard` | `AwaitingDeposit` | `DepositPaid`, `Cancelled` | `ReadyToPrint`, `Shortage`, `Cancelled` |
| `NoProduction` | `AwaitingDeposit` | `DepositPaid`, `Cancelled` | `Ready`, `Shortage`, `Cancelled` |
| `Outsourced` | `AwaitingDeposit` | `DepositPaid`, `Cancelled` | `Designing`, `Manufacturing`, `Cancelled` |

Why: a deposit is a **commercial** gate, not a production step — the shop wants the money before it
spends material. Putting it between «جديدة» and the first work status is the only place where it
gates anything. Cancelling *is* offered from both (unlike «جديدة»), because by then the customer has
either been asked for money or handed it over, and calling it off is a real decision rather than a
stray tap.

`DepositPaid` deliberately repeats `New`'s arms rather than inventing its own, so the day a road
gains a step the deposit detour gains it too.

**Options considered**

| Option | Why not |
|---|---|
| **B. Deposit as a flag, no statuses** (`deposit_required` boolean + the existing payments screen) | Cheapest by far — no state-machine change, no app release. But the shop cannot *see* «which orders are waiting on a deposit» on the home board or in the filter, which is the whole ask. Rejected because the user asked for statuses. |
| **C. Reachable from every pre-production status** | A deposit demanded halfway through printing is a different conversation, and every extra arm is a button on a screen. Can be added later from one place if the business asks. |
| **D. A mandatory gate — every order must pass through it** | The business takes plenty of orders with no deposit at all. Making the detour compulsory would force a zero-deposit hop on all of them. |

---

### 3.2 Is the estimated deposit a ledger entry?

**Recommendation — no. The expectation lives on `orders`; only the real deposit reaches the ledger.**

- Entering «انتظار العربون» writes `deposit_expected_amount` and `deposit_expected_method` on the
  order. **No `order_payments` row.**
- Entering «عربون مدفوع» calls the existing `RecordOrderPayment` → an ordinary
  `OrderPaymentType::Payment` row, which `RecalculateOrderPayments` folds into `paid_amount` like
  every other payment. "تنحسب الدفعة عادي" — literally.

Why: [PAYMENTS-DESIGN.md §10](../payments/PAYMENTS-DESIGN.md) settles this already — *«لا يُسجَّل الدفع
إلا بيد موظف… قيدٌ يخترعه الخادم نيابةً عن موظف هو أول كذبة في سجل بُني كلّه ليُصدَّق»*. An expected
deposit is money that has **not** moved; a ledger row for it would show up in the payment log, in
«المدفوع», and in every report that sums the ledger. The naming matters for the same reason: the
column is `deposit_**expected**_amount`, never `deposit_amount`, so no screen can read it as
"received" — that is exactly the trap `collected_amount` fell into
([PAYMENT-AT-STATUS-CHANGE.md §2](../payments/PAYMENT-AT-STATUS-CHANGE.md)).

**Options considered**

| Option | Why not |
|---|---|
| **B. A new `OrderPaymentType::DepositExpected`, not a credit** | Puts a row that moved no cash into the ledger. Needs a migration on the `order_payments.type` check constraint, new arms in `isCredit`/`movedCash`/`namesAMethod`, and a new "is it real?" question in every reader of the log. Buys nothing the two columns don't. |
| **C. A pending payment with a `state` column** | Same objection, plus it forks `OrderPayment` into two kinds of thing. |

---

### 3.3 What «عربون مدفوع» demands before it will accept the move

**Recommendation — nothing. The move may be made before the money is in the ledger.**

- The move asks for `payment_amount` / `payment_method` / `payment_receipt` through the *existing*
  `TransitionFields::money()` machinery (extended to fire on this status), pre-filled with
  `deposit_expected_amount` and `deposit_expected_method` — **all of it optional**, exactly as on
  «تم الاستلام» today.
- Leaving the box empty moves the order and records nothing. The deposit can then be entered from
  the payments screen an hour or three days later, and `is_deposit_received` flips itself when it
  is — see §3.5.

**Why no guard, on reflection.** The two things are different claims by different people. The status
is the **sales desk's** claim — «العميل دفع العربون» — and it has to be settable the moment the
customer says so, because the order cannot enter production until it is. The boolean is the
**accountant's** confirmation that the money actually landed, which for a حوالة is genuinely a day
or two later. A guard would collapse the two into one, and force the clerk either to wait or to
invent a ledger entry for money they have not seen. That is the thing the whole payments design
refuses.

**Options**

| Option | Trade-off |
|---|---|
| **B. Require a live payment (`paid > 0`)** | The status can never lie about money — but it also cannot be set before the accountant has posted the entry, which blocks production on a bank transfer clearing. Choose this only if the shop never moves the order on the customer's word alone. |
| **C. Strict — `paid ≥ deposit_expected_amount`** | Everything in B, plus it treats عربون as an agreed figure rather than an estimate. The business called the figure **تقديرية**, and a customer who hands over 200 against an estimate of 250 has still paid a deposit. |

Under the recommendation, "which orders claim a deposit that accounting has not confirmed?" is the
query `status != 'awaiting_deposit' AND deposit_expected_amount IS NOT NULL AND is_deposit_received = false`
— which is precisely the list the accountant was asking for. A guard would make that list always
empty and move the problem off-screen.

**Permission note:** the money fields are gated by `orders.payments.record` and the *move* by
`orders.status.deposit_paid`. A salesperson holding the second but not the first simply sees no money
box and moves the order without one — which, with no guard, is a supported path rather than a dead
end.

---

### 3.4 What "if they walk it back" reverses, and what it doesn't

**Recommendation — only «عربون مدفوع» → «انتظار العربون» reverses the deposit automatically.**

- That move calls `ReverseOrderPayment` on the entry **this feature's own move created**
  (`deposit_payment_id`), with the reason carried by the move.
- **If the move recorded nothing** — the status was set on the customer's word and the money never
  came, which under §3.3 is a normal path — there is nothing to reverse and nothing is reversed.
  Walking back changes only the status.
- **If the deposit was entered later from the payments screen**, `deposit_payment_id` is null and
  that entry is *not* auto-reversed. Deliberate: the status change did not create it, so the status
  change does not get to delete it. Whoever decides that money was never received reverses it where
  it was recorded. *(Option: have `RecordOrderPayment` claim `deposit_payment_id` for the first
  payment recorded while the order sits in a deposit status — it makes walk-back always have a
  target, at the cost of teaching a general action about deposits.)*
- **`is_deposit_received` is not touched by any of this** — it is an employee's attestation and only
  an employee clears it (§3.5). Walking back while it is still `true` is exactly the contradiction
  the warning row in §3.5 is there to show.
- **Cancelling does nothing to the money at all** — no reversal, and **no refund**. A عربون is in
  many agreements precisely the thing that is *not* returned when the customer backs out; that is
  why it was taken. The entry stays live, `paid_amount` is unchanged, and the order is cancelled
  on top of it. If the shop decides to return some of it, that is a separate human act on the
  payments screen (`orders.payments.reverse`), decided case by case — never a side effect of a
  status change. Pinned by `test_cancelling_leaves_the_deposit_exactly_where_it_is`.
- Reversal from the payments screen keeps working unchanged, and **does not touch the boolean** —
  it is a person's attestation, not a reading of the ledger (§3.5).

**Options**

| Option | Why not |
|---|---|
| **B. Manual reversal only** | The clerk who taps "back to انتظار العربون" has said the money is not there; making them find a second screen to say it again is exactly the two-places problem [PAYMENT-AT-STATUS-CHANGE.md](../payments/PAYMENT-AT-STATUS-CHANGE.md) was written to remove. |
| **C. Any backward move reverses, cancellation included** | Turns a refund into a silent correction and loses the fact that cash left the till. |

---

### 3.5 `is_deposit_received` — a tick an employee makes, never a derived value

**Decided by the business: the column starts `false` and stays `false` until an employee confirms
it.** Nothing computes it, no status change sets it, and `RecalculateOrderPayments` does not touch
it. It is a human attestation — «رأيتُ المال» — and that is precisely what makes it worth having
beside a ledger that already knows the arithmetic.

**Never filled in during the status change.** Answering your question directly: it is not a field on
the «عربون مدفوع» screen, and the move neither requires nor sets it. The order moves; the tick
happens whenever the person who checks the bank app gets to it — an hour later, three days later, or
after the bags have already shipped.

```
move to «عربون مدفوع»            →  is_deposit_received = false   (the sales desk's claim)
   ... the حوالة lands, someone checks the account ...
employee taps «تأكيد استلام العربون»  →  is_deposit_received = true + who + when
```

#### What the flag does **not** do — it gates nothing

**No transition, anywhere, reads `is_deposit_received`.** An order sitting at `false` moves to «جاهزة
للطباعة», gets printed, ships, is delivered and is settled exactly as it would at `true`. Nothing
about production, dispatch, invoicing or settlement consults it, and no code outside
`ConfirmDepositReceipt` writes it.

That is deliberate and it is the point of the whole design: the flag is the **accountant's record of
having checked**, added after the fact. A flag that also blocked the workshop would turn one person's
unfinished paperwork into a stopped production line — and it would be unfixable at 9pm when the only
colleague who may tick it (§3.5, four eyes) has gone home. Work must not wait on bookkeeping.

The only thing in this feature that gates anything is the **status**, and only in the ordinary way
the machine always works: an order standing in «انتظار العربون» goes forward by moving to «عربون
مدفوع», because that is the map (§3.1). Even that is opt-in — the deposit detour is optional, and an
order that never enters it is untouched by any of this. And the move to «عربون مدفوع» itself is
unguarded (§3.3), so nothing about the deposit can ever leave an order stuck.

Money still has exactly one gate, and it is the one that already existed:
`SettlementRequiresFullPayment` refuses «تم التسوية» while anything is owed. That reads the **ledger**,
not this flag, and this feature does not change it.

`test_an_unconfirmed_deposit_stops_nothing` (§5, item 17) pins this so nobody wires the flag into a
guard later.

#### How it is written

A dedicated endpoint, not a field on the order update — `PATCH /orders/{order}` must never be able
to set it, or any client with edit rights becomes an accountant.

| | |
|---|---|
| Endpoint | `POST /api/v1/orders/{order}/deposit-receipt` → `{ "received": true｜false }` |
| Permission | new `PermissionName::ConfirmDepositReceipt = 'orders.deposit.confirm'` — «تأكيد استلام العربون». Its own grant: the person who checks the bank account is not the person who takes the order |
| Action | `Domain/Order/Actions/ConfirmDepositReceipt` — sets the flag, stamps `deposit_confirmed_at` and `deposit_confirmed_by` |
| Undo | the same endpoint with `received: false` — a mis-tap has to be correctable, and `Auditable` records both directions with the causer, so "who said the money was in?" always has an answer |
| Never fillable | the column is server-assigned, so it stays out of `#[Fillable]` (RULES §9.4) |

#### Separation of duties — the tick is refused to whoever made the claim

**Decided by the business: two different people.** The employee who moved the order to «عربون مدفوع»
may not be the employee who confirms the money arrived. This is enforced **per order, on the record**
— not by hoping the roles were configured carefully:

```php
// ConfirmDepositReceipt, before it writes anything
if ($actor->getKey() === $order->deposit_claimed_by) {
    throw DepositConfirmationNeedsASecondPerson::make();
}
```

| | |
|---|---|
| New column | `deposit_claimed_by` — the user who moved the order into «عربون مدفوع», stamped by `ChangeOrderStatus` |
| New failure | `Domain/Order/Exceptions/DepositConfirmationNeedsASecondPerson` — «لا يمكن لمن نقل الطلبية إلى «عربون مدفوع» أن يؤكّد استلام العربون — يلزم شخص آخر» |
| Applies to | Setting the flag **`true`** only. Clearing it is allowed to anyone holding the permission: un-ticking makes the record stricter, not looser, and refusing it would strand a mistake |
| Null claimer | A move made by a console command or a seeder stamps nobody, so there is nobody to conflict with and the tick is allowed |
| Re-entry | Walking back and re-entering «عربون مدفوع» overwrites `deposit_claimed_by` with whoever made the *new* claim — the rule always guards the current claim |

**Why a column rather than reading `order_status_transitions.user_id`.** The transitions table does
hold it (`user_id`, nullable), so the rule *could* be a query for the latest row into `DepositPaid`.
A column is better for one concrete reason: it lets `OrderResource` publish **`can_confirm_deposit`**,
so the app greys the checkbox with a hint — «نقلتَ أنت هذه الطلبية؛ يؤكّدها زميل» — instead of
letting the person tap and collect a 422. Enforcement stays on the server either way; this only
decides whether the screen can tell the truth before the tap.

**Note the interaction with §3.3.** Because no guard blocks the move, a salesperson can claim a
deposit that never arrived — and this rule is what stops them also certifying it. The two decisions
work as a pair: the move is cheap and reversible, the confirmation is not, and they belong to
different hands.

**Options**

| Option | Trade-off |
|---|---|
| **B. Role configuration only — never grant both permissions to one role** | No code, no new column. But a manager or owner role holding everything silently bypasses it, and nothing in the system records that the rule was meant to exist. |
| **C. Also bar whoever recorded the deposit payment** | Tighter. Probably too tight: an accountant who posts the entry *is* the natural person to certify it, and they are already not the salesperson. |
| **D. Bar the tick only when the claim is recent (say, under an hour)** | Answers the one-person-on-shift problem below without dropping the rule entirely. More machinery than it is worth unless the shop hits the problem. |

#### The one risk, and how it is handled

A manual tick is a **second source of truth about whether money arrived**, free to disagree with the
ledger: someone can tick it with no payment recorded, or tick it and then have the payment reversed.
That is inherent to the decision, not a flaw in it — the tick answers *«هل وصل المال فعلاً؟»*, the
ledger answers *«هل سُجِّل؟»*, and the gap between those two questions is the accountant's actual job.

**The answer is to show the disagreement, not to prevent it** — the pattern the system already uses
for «الطلبية منتهية ولم يُسجَّل قبض ٣٠٠» ([PAYMENTS-DESIGN §8](../payments/PAYMENTS-DESIGN.md)):

- Confirmed, but the ledger holds nothing against the expected deposit → a warning row on the order:
  «أُكِّد استلام العربون ولم تُسجَّل دفعة».
- The reverse — paid in the ledger but never confirmed → the accountant's worklist (§3.3).

Neither is blocked; both are visible. **Recommendation: do not auto-reset the flag when a payment is
reversed.** A flag the server flips behind the employee's back is no longer their attestation, and
the warning row already says what happened.

**Options**

| Option | Trade-off |
|---|---|
| **B. Auto-reset to `false` when the live credits fall below the expected deposit** | Keeps flag and ledger from ever contradicting each other, at the cost of overwriting a person's statement without asking. Choose it if the business would rather the flag never lie than that it never be overwritten. |
| **C. Refuse the tick unless a payment is recorded** | Makes the flag redundant with the ledger — if a payment must exist first, the ledger already answers the question. |
| **D. A `bool` transition-field type, ticked during the move to «عربون مدفوع»** | Would need a new `TransitionFieldType` on both sides ([ORDERS-STATUS-FLOW.md §3](ORDERS-STATUS-FLOW.md) lists `bool` as "تُضاف يوم تُطلب") — and it contradicts the requirement anyway, since the point is that confirmation comes *later*. |
| **E. Derived from the ledger total** | Was the previous recommendation in this plan, overruled by the business: nobody ticks anything, the flag cannot disagree with the ledger — but it also cannot record a confirmation the ledger does not yet have, and it takes the check out of a person's hands. |

---

### 3.6 Timestamps and notifications

**Timestamps.** `DepositPaid` stamps `deposit_received_at`; `AwaitingDeposit` stamps **nothing**.
Both statuses are re-enterable (reverse → ask again → pay again), and a single column silently keeps
the last visit — which is right for "when was the deposit received" (the earlier one was reversed)
and misleading for "when was it first asked for". `order_status_transitions` holds the full history
either way, exactly as it does for «إعادة إرسال» and «نواقص» today.

**Notifications.** `NotifyWhenOrderStatusChanges::isWorthABell()` is an exhaustive `match` with no
`default` — it will raise `UnhandledMatchError` until both statuses are answered, on purpose.
**Recommendation: `false` for both.** The audience is everyone with `orders.view`, and the current
line is "what changes where the goods are, or ends the order". A deposit changes neither.
**Option B:** `true` for `DepositPaid`, if the business wants a cash bell — better served later by a
dedicated definition aimed at whoever holds `orders.payments.record`, rather than by widening this one.

---

## 4. The work

### 4.1 Database — one migration

`backend/database/migrations/<ts>_add_deposit_to_orders_table.php`

| Column | Type | Notes |
|---|---|---|
| `deposit_expected_amount` | `decimal(12,2)` nullable | The estimate. Never read as money received — §3.2. Match the precision of the other money columns on `orders`. |
| `deposit_expected_method` | `string(30)` nullable | `PaymentMethod` value. |
| `deposit_payment_id` | `foreignId` nullable, `nullOnDelete`, indexed | The entry the status change itself created, if any — what §3.4 reverses on a walk-back. Unrelated to the tick. |
| `deposit_paid_at` | `timestamp` nullable | Stamped by the **status** reaching «عربون مدفوع» — `OrderStatus::timestampColumn()`, §3.6. |
| `deposit_claimed_by` | `foreignId` → `users`, nullable, `nullOnDelete` | Who moved the order into «عربون مدفوع». The other half of the four-eyes rule — §3.5. |
| `is_deposit_received` | `boolean` default `false`, **not null** | The employee's tick. Indexed — accounting filters on it. |
| `deposit_confirmed_at` | `timestamp` nullable | When the tick was made. Null again when it is cleared. |
| `deposit_confirmed_by` | `foreignId` → `users`, nullable, `nullOnDelete` | Who ticked it. The whole value of a manual attestation is that it has a name on it — and it must never equal `deposit_claimed_by`. |

**Two different moments, two different columns.** `deposit_paid_at` is when the order was *said* to
have paid; `deposit_confirmed_at` is when somebody *checked*. Sharing one column would lose which of
the two a date meant — the same reasoning `manufacturing_started_at` was given its own column for.

Forward-only, no data backfill (every existing row is honestly `false` / `null`). `--pretend` first.
Also add all seven to `Order::casts()`, and **none of them to `#[Fillable]`** — every one is
server-assigned (RULES §9.4).

### 4.2 Backend — files to modify

| File | Change |
|---|---|
| `Domain/Order/Enums/OrderStatus.php` | Two `case`s; two `label()` arms («انتظار العربون» / «عربون مدفوع»); arms in `standardNext()`, `noProductionNext()`, `outsourcedNext()` per §3.1; `permission()`; `timestampColumn()`; decide `mainLine()` — **recommendation: leave the deposit off the main line**, like «نواقص» and the returns: it is a detour a minority of orders walk, and putting it on the progress bar would claim every order passes through it |
| `Domain/Identity/Enums/PermissionName.php` | `MoveOrderToAwaitingDeposit = 'orders.status.awaiting_deposit'`, `MoveOrderToDepositPaid = 'orders.status.deposit_paid'`, **`ConfirmDepositReceipt = 'orders.deposit.confirm'`**, their Arabic descriptions, and the group list around line 365 |
| `Domain/Order/Support/TransitionFields.php` | On `AwaitingDeposit`: `deposit_amount` (`number`, required, `min` > 0) + `deposit_method` (`payment_method`, `requiredWith: deposit_amount`, opens on «كاش»). Extend `money()` to fire on `DepositPaid` too, with `value` = the outstanding part of `deposit_expected_amount` and the method pre-filled from `deposit_expected_method` |
| `Domain/Order/Actions/ChangeOrderStatus.php` | Persist the expectation on entering `AwaitingDeposit`; on entering `DepositPaid`, stamp `deposit_paid_at` and **`deposit_claimed_by = $actor`**, let the existing `recordPaymentForOrder()` run and stamp `deposit_payment_id` **only if it created an entry**; on `DepositPaid → AwaitingDeposit`, reverse that entry via `ReverseOrderPayment` if there is one. No guard — §3.3 |
| `Domain/Order/Actions/ConfirmDepositReceipt.php` | **New.** Refuses the actor who made the claim (§3.5), then sets `is_deposit_received` + `deposit_confirmed_at` + `deposit_confirmed_by`, or clears all three. One verb, one class |
| `Domain/Order/Exceptions/DepositConfirmationNeedsASecondPerson.php` | **New.** `DomainException` subclass, Arabic message |
| `Domain/Order/OrderService.php` | The door to the action, per RULES §3 |
| `Application/Api/V1/Controllers/OrderController.php` (or a small `OrderDepositController`) | `POST /orders/{order}/deposit-receipt`, `can:orders.deposit.confirm`, thin: FormRequest → service → `OrderResource` |
| `Application/Api/V1/Requests/Order/ConfirmDepositReceiptRequest.php` | **New.** `received` → `required|boolean`, Arabic messages |
| `routes/api.php` | The one route |
| `Domain/Notification/Listeners/NotifyWhenOrderStatusChanges.php` | Two arms — §3.6 |
| `Application/Api/V1/Resources/OrderResource.php` | Publish `deposit_expected_amount`, `deposit_expected_method` (+ label), `deposit_paid_at`, `is_deposit_received`, `deposit_confirmed_at`, the claimer's and confirmer's names, **`can_confirm_deposit`** (permission **and** the four-eyes rule, answered server-side so the app greys the box honestly), and the §3.5 warning condition if the app is to draw it |
| `database/factories/OrderFactory.php` | Whatever states the new tests need |

No change needed in: `ChangeOrderStatusRequest` (rules are derived from the field descriptors),
`RecalculateOrderPayments` (**the tick is not derived from the ledger — §3.5**),
`HomeSummaryResource` (walks `OrderStatus::cases()`), `PaymentStatus`, the reports, the Nawris
mapping, `RecordOrderPayment` / `ReverseOrderPayment` themselves.

### 4.3 Frontend — files to modify

| File | Change |
|---|---|
| `lib/features/orders/models/order_status.dart` | Two cases with the **exact** Arabic from the PHP enum (the contract test reads it), `tone` arms — recommendation: `attention` for awaiting, `fresh`/`ready` for paid — and declaration order matching the PHP |
| `lib/features/orders/presentation/widgets/order_status_chip.dart` | Two icon arms |
| `lib/features/orders/models/order.dart` (+ freezed/json regen) | The new deposit fields off `OrderResource` |
| The money section of `order_detail_page.dart` (a new `deposit_card.dart`) | **The tick.** A row reading «العربون — متوقَّع ٢٥٠٫٠٠ · كاش» with a checkbox «تأكيد استلام العربون», shown when `deposit_expected_amount` is present and enabled only when the server says `can_confirm_deposit`. **Disabled with a hint rather than hidden** for the person who made the claim — «نقلتَ أنت هذه الطلبية؛ يؤكّدها زميل» — so the rule is visible instead of looking like a broken button. Once ticked it shows who confirmed it and when, and can be un-ticked by anyone with the right. Plus the §3.5 warning row when it is ticked with nothing in the ledger |
| `lib/features/orders/usecases/` + `order_repository(_impl).dart` + `order_detail_cubit.dart` | A `confirmDepositReceipt(orderId, received)` call, patching the order in place like the other detail actions |
| `lib/core/permissions/app_permission.dart` | The new permission (`permission_contract_test.dart` reads the PHP enum and will fail until it is added) |

The status screen itself needs nothing: it draws whatever fields the server describes, and all three
types are already implemented. **The tick is the one piece of genuinely new UI in this feature** —
it is the part that would have been free under the derived design (§3.5 option E).

### 4.4 Docs

- New `Docs/orders/ORDER-DEPOSIT.md` in **Arabic**, matching the house style, replacing this file as
  the permanent record.
- Amend the transition table in [ORDERS-STATUS-FLOW.md §3](ORDERS-STATUS-FLOW.md) with the two new rows.
- Amend [PAYMENT-AT-STATUS-CHANGE.md §4](../payments/PAYMENT-AT-STATUS-CHANGE.md) — the money fields
  now appear on three statuses, not two.
- `composer spec` to regenerate `Docs/openapi.json`.

---

## 5. Tests

**TDD, AAA, and the existing structural sweeps do a lot of the work for free.** `OrderStatusTest`
walks every case and every pair, so a missing label, permission or route-in fails the build by name.

**Will fail until the new arms are written** (this is the feature's own checklist):
`test_the_transition_map_is_exactly_what_the_business_agreed` (data provider needs two rows),
`test_the_two_roads_differ_in_exactly_two_places`, `test_the_board_opens_on_the_seven_statuses_the_workshop_lives_in`,
`test_every_status_has_an_arabic_label`, `test_every_status_names_a_permission_that_exists`,
`test_every_status_except_the_first_can_be_reached`, `test_an_order_is_never_created_into_a_status_something_else_leads_to`,
and `NotifyWhenOrderStatusChanges` via `UnhandledMatchError`.

**New — `tests/Feature/Orders/OrderDepositTest.php`:**

1. Entering «انتظار العربون» stores the estimate and the method, and writes **no** ledger row.
2. The estimate is required; a zero or negative estimate is a 422 with an Arabic field error.
3. «عربون مدفوع» with an amount records one `payment` entry, moves `paid_amount`, stamps
   `deposit_paid_at` and `deposit_payment_id` — and leaves **`is_deposit_received = false`**.
   *The status never ticks the box.*
4. **«عربون مدفوع» with no amount at all is accepted**, records nothing, and also leaves the flag
   `false` — the sales desk's claim, nothing more.
5. **The tick, afterwards:** starting from the order in (4) — already moved on to «جاهزة للطباعة» —
   `POST /orders/{id}/deposit-receipt {received: true}` sets the flag, stamps `deposit_confirmed_at`
   and `deposit_confirmed_by`, and changes no status and no ledger row. *This is the case the whole
   design exists for; it is the one test that must not be skipped.*
6. The same endpoint with `received: false` clears all three, and the audit trail holds both
   directions with the causer's name.
7. The tick is **refused with 403** without `orders.deposit.confirm`, and **401** unauthenticated.

**Separation of duties (§3.5), its own block of tests:**

7a. The user who moved the order to «عربون مدفوع» is **refused** by
   `DepositConfirmationNeedsASecondPerson`, with the Arabic message, **even holding the permission** —
   and the order is asserted untouched afterwards.
7b. A *different* user holding the permission is accepted, and `deposit_confirmed_by` is that second
   user while `deposit_claimed_by` stays the first.
7c. `can_confirm_deposit` in `OrderResource` is `false` for the claimer and `true` for the colleague
   — the screen and the endpoint agreeing, asserted from one fixture.
7d. The claimer **may still clear** a confirmation (`received: false`) — the rule guards `true` only.
7e. A move made with no actor (console/seeder) leaves `deposit_claimed_by` null and blocks nobody.
7f. Walking back and re-entering «عربون مدفوع» with a second user **replaces** `deposit_claimed_by`,
   so the first user may now confirm and the second may not.
8. `PATCH /orders/{id}` cannot set the flag — a payload carrying `is_deposit_received` is refused or
   ignored, and the record is asserted untouched (RULES §6, invariants).
9. Recording or reversing a payment **never** moves the flag in either direction (the "not derived"
   proof, and the guard against someone re-adding it to `RecalculateOrderPayments` later).
10. Walking back to «انتظار العربون» after the move recorded a payment writes a `reversal` and
    returns `paid_amount` to zero — **and leaves a `true` flag standing**, because only a person
    clears it (§3.5).
11. The accountant's worklist query — `deposit_expected_amount IS NOT NULL AND is_deposit_received = false`
    — returns exactly the orders in (3) and (4).
12. Cancelling from «عربون مدفوع» leaves the payment standing, and refunding it still works.
13. A bank transfer without a receipt is refused, with a receipt is accepted (the existing
    `required_if` rule, asserted on the new screen).
14. Auth 401 · permission 403 for each of the two new moves · the money field is absent for a user
    without `orders.payments.record`, **and the move still succeeds without it**.
15. The deposit detour is offered on all three `OrderFlow`s and rejoins the right arms.
16. Envelope assertions on all of the above (`status` / `message` / `data`), per RULES §6.
17. **`test_an_unconfirmed_deposit_stops_nothing`** — an order with `is_deposit_received = false`
    walks «عربون مدفوع» → «جاهزة للطباعة» → «قيد الطباعة» → «جاهزة» → dispatch → «تم الاستلام» →
    «تم التسوية» without a single refusal, and the flag is still `false` at the end. *The guard
    against anyone later deciding the flag should block something.*
18. The only refusal on that road is the existing `SettlementRequiresFullPayment`, and it fires on
    an **unpaid ledger**, not on an unconfirmed flag — asserted by settling an order that is fully
    paid while the flag is still `false`.

**Also update:** `OrderTransitionFieldsTest`, `OrderTransitionPaymentTest`, `OrderStatusCountsTest`,
and on the app side `order_status_contract_test.dart` (auto-reads the PHP),
`permission_contract_test.dart` (same), `order_status_icons_test.dart`, `order_filter_sheet_test.dart`,
plus a widget test for the tick: hidden without the permission, un-ticked by default, and the
warning row drawn when it is ticked against an empty ledger.

---

## 6. Validation, rollback, risks

**Validation:** `php artisan test` (whole suite, against `printing_bags_test` — never production),
`./vendor/bin/pint`, `php artisan scramble:analyze`, `composer spec`, then `flutter test` and
`flutter analyze`. `php artisan migrate --pretend` before the migration runs anywhere shared.

**Rollback:** the migration is additive and nullable (bar one defaulted boolean), so reverting the
code leaves six unused columns and no broken rows. No data is rewritten, nothing is dropped.

**Risks and open questions**

| Risk | Handling |
|---|---|
| An order already in «جديدة» before release | Unaffected — the detour is optional and reachable from where it stands. |
| An app build older than this release | Shows both statuses as `unknown` + the server's Arabic label + a neutral chip. Degraded, not broken. Ship the backend first if you want. |
| `deposit_expected_amount` larger than `grand_total` after the invoice is edited | Harmless: it is an estimate, and the real payment is still capped at the remaining by `RecordOrderPayment`. |
| Two clerks moving one order at once | Already handled — `ChangeOrderStatus` and `RecordOrderPayment` both `lockForUpdate()`. |
| An order sits in «عربون مدفوع» with `is_deposit_received = false` and is forgotten | **By design, and the reason the column exists** — that pair *is* the accountant's worklist (§3.3, §3.5). Worth a home-board tile or a report row later; out of scope here. |
| **The tick and the ledger disagree** — ticked with no payment recorded, or a ticked deposit later reversed | Inherent to a manual attestation (§3.5). Shown as a warning row rather than prevented; never auto-cleared. §3.5 option B if the business would rather it self-correct. |
| Nobody ever ticks it, because nobody knows to | The real operational risk of a manual flag, **and the four-eyes rule sharpens it**: the one person who knows the deposit landed is now barred from recording that. A bell for `orders.deposit.confirm` holders when an order reaches «عربون مدفوع» stops being optional polish — §3.6 option B. Recommend shipping it with the feature. |
| **Only one person on shift**, or only one user holds `orders.deposit.confirm` | The tick waits — which is what separation of duties means, and is correct for an accounting control. But it must be a deliberate choice: **at least two users need the permission**, or no deposit can ever be confirmed. Worth a line in the role-setup notes, and §3.5 option D (a time window) if the shop hits it in practice. |
| **Open — for the business** | (a) Does عربون mean *estimate* or *agreed figure*? → decides whether §3.3 B/C is wanted. (b) Should reaching «عربون مدفوع» ring a bell for whoever ticks the box? → §3.6, now recommended. (c) Should «انتظار العربون» be reachable from anywhere but «جديدة»? → §3.1 C. |

---

## 7. Suggested order of work

1. Migration + `Order` casts. *(no behaviour yet)*
2. `OrderStatus` cases, labels, map, permissions, timestamps — the structural sweeps go green.
3. `PermissionName` + seeder/role wiring.
4. `TransitionFields` — the two new fields and the extended money block.
5. `ChangeOrderStatus` — persist the expectation, stamp what it recorded, reverse on walk-back.
   Written test-first, one test per §5 item.
6. `ConfirmDepositReceipt` + its endpoint, request, permission and the four-eyes rule — the tick.
   §5 items 5–9 prove "ticked later, by a person, and by nothing else"; §5 items 7a–7f prove "and
   not by the same person". Write them before the code.
7. `OrderResource` + `composer spec`.
8. Flutter enum, chip icons, order model fields, tests.
9. The deposit card and its tick — the one new screen element (§4.3), with its widget test.
10. Arabic doc, `ORDERS-STATUS-FLOW.md` and `PAYMENT-AT-STATUS-CHANGE.md` amendments.

Steps 1–7 are a shippable backend on their own. Note that under the manual-tick decision the feature
is **not** complete without step 9: until the app draws the checkbox, the flag can only be set with
an API client, so an app-only user would see «عربون مدفوع» and have no way to confirm it.
