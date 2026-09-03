# Nawris Integration — Design

> **Status: built. All ten steps of [§10](#10-build-order) are implemented and green.**
>
> This document is the design and the reasoning. Two companions live beside it:
> **[NAWRIS-CHANGES.md](NAWRIS-CHANGES.md)** — everything that changed in the backend, and the
> deployment checklist. **[NAWRIS-FRONTEND-INTEGRATION.md](NAWRIS-FRONTEND-INTEGRATION.md)** — how
> to wire the Flutter app up to it.
>
> Built on branch `nawris_integration`. **Nothing has ever spoken to Nawris** — every test uses
> `Http::fake()`, and §11 lists what stays unverified until a real call.
>
> Source: the *Nawris Integration Contract* (compiled from the Primula codebase, not from carrier
> documentation). This document is that contract re-read against **this** system, with the parts
> that do not fit us replaced rather than copied.
>
> Nawris is a Libyan last-mile carrier. Two directions, no polling: we `POST` shipments to their
> REST API, they `POST` status changes back to one webhook.

---

## 0. The short version

**It fits, and it fits better here than it did where the contract came from.** Primula's ugliest
problems — a webhook that moves an order straight to *paid* and releases money, a return that can
only be recorded as a cancellation, a COD figure recomputed differently in three places — are
problems we do not have, because [`OrderStatus`](../../backend/app/Domain/Order/Enums/OrderStatus.php)
already separates «تم الاستلام» from «تم التسوية», already has all three return statuses, and
[`Order::remainingAmount()`](../../backend/app/Domain/Order/Models/Order.php) is already the one COD
function the contract begs for.

Five things need real decisions before code:

1. **The state machine will refuse some of their transitions, and we should let it.** Our return
   chain is walked one link at a time on purpose. Nawris jumps. → [§3](#3-the-status-map)
2. **The delivery fee comes off the COD before we send it — decided.** That keeps the contract's
   second guard load-bearing, and the residual it opens is closed by a bookkeeping entry that never
   touches the invoice. → [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive)
3. **The webhook records a payment; it never settles an order.** → [§5.1](#51-the-webhook-records-a-payment-it-never-settles-an-order)
4. **Their geography is mapped onto our cities and regions**, not filled in by an operator.
   → [§4](#4-geography)
5. **A new `Carrier` context**, because Delivery may not import Order. → [§2](#2-where-the-code-goes)

---

## 1. What we already have that the contract assumes we don't

The contract was written for a system that had none of this. Reading it straight would have us
build five things twice.

| The contract asks for | We already have it |
|---|---|
| A COD function called from create, group-create and edit alike | `Order::remainingAmount()` — `grand_total − paid_amount − written_off_amount`, one definition |
| A payment ledger the collection lands in | `order_payments`, `RecordOrderPayment`, with a row lock, a remainder ceiling and a receipt rule |
| Somewhere to keep the courier's phone | `orders.courier_phone` — added for exactly this, "the man, not the company" |
| A carrier record to hang the parcel off | `shipping_companies` + `orders.shipping_company_id` with the name snapshotted beside it |
| A customer-visible history row per event | `order_status_transitions`, written by `RecordStatusTransition` |
| An audit trail attributed to a non-human actor | `spatie/laravel-activitylog` via the `Auditable` concern |
| Terminal return states so codes 6 and 12 aren't a bug | «راجع مكتب» and «إلغاء تام», already distinct |

**And two things we do not have, which change the shape of the work:**

- **No consolidated parcels.** Primula lets many orders share one Nawris code, and *most* of the
  contract's awkwardness follows from that: `receiver` is a `+`-joined list of order ids, the COD
  is a sum, and an edit must rebuild the whole parcel or it silently overwrites its siblings. We
  ship one order per parcel. → [§6](#6-schema)
- **No jobs, no notifications, and no `try`/`catch` anywhere in `app/`** —
  `ErrorHandlingTest` walks the tree and fails the build on either keyword. This integration
  introduces the first queued job in the codebase, and has to translate HTTP failures into typed
  domain exceptions without a catch block. → [§7.3](#73-the-trycatch-ban)

---

## 2. Where the code goes

**A new context: `app/Domain/Carrier/`.**

Not inside `Delivery`. The rule in [RULES.md §3](../../backend/RULES.md#3-architecture) is that
dependencies run one way and `Order` may depend on `Delivery`, so `Delivery` must never import
`Order`. This integration writes order statuses and order payments — it depends on Order *and* on
Delivery. It therefore has to sit above both, and nothing may depend on it.

```
app/Domain/Carrier/
├── CarrierService.php              the door — the only thing Application/ and Order/ call
├── Models/
│   ├── NawrisParcel.php
│   ├── NawrisParcelOrder.php       the link
│   └── NawrisWebhookEvent.php
├── Actions/
│   ├── DispatchToNawris.php        add-order
│   ├── EditNawrisParcel.php        edit-order
│   ├── CancelNawrisParcel.php      canceled
│   ├── DeleteNawrisParcel.php      delete-order
│   ├── ResendNawrisParcel.php      resend-request
│   ├── BuildNawrisPayload.php      the 24 fields, in one place
│   ├── RecordNawrisWebhook.php     the request-cycle half: log, queue, 200
│   ├── ResolveNawrisTarget.php     the three-tier order resolver
│   └── ApplyNawrisStatus.php       the guards and the transition — the whole risk surface
├── Jobs/ProcessNawrisWebhook.php   the first job in this repo
├── DTOs/  NawrisOrderPayload · NawrisWebhookPayload · NawrisResponse
├── Enums/ NawrisStatusCode · NawrisOperation
├── Exceptions/ NawrisRequestFailed · NawrisRejectedRequest · OrderAlreadyDispatched · …
└── Support/NawrisClient.php        HTTP only, no business rules
```

`Order` does **not** import `Carrier`. The dispatch call is wired from the Application layer
(`OrderController::changeStatus` → `CarrierService`) *after* `ChangeOrderStatus` succeeds, not from
inside the action — see [§8](#8-when-we-call-them).

---

## 3. The status map

Nine codes are mapped. Anything else updates the stored raw label and is logged unmapped, which is
the correct default: an unknown code must never guess at a state change.

| Code | Their meaning | Our target | Notes |
|---|---|---|---|
| `3` | Out for delivery | `OutForDelivery` «جاري التوصيل» | Almost always already there — a no-op note |
| `4` | Ambiguous | → treat as `15` **only** when `return_reason` is present; otherwise ignore | Straight from the contract |
| `5` | Delivery cancelled | `ReturnedCourier` «راجع لدى المندوب» | **See the conflict below — not `Cancelled`** |
| `6` | Return received back | `ReturnedOffice` «راجع مكتب» | Primula had to cancel here. We have the exact status |
| `7` | Delivered and collected | `Delivered` «تم الاستلام» **+ a payment row** | All three guards apply. **Never `Settled`** |
| `10` | Return sent out again | `Resend` «إعادة إرسال» | Contract says note-only; we have the status, so apply it when legal |
| `12` | Return written off | `Cancelled` «إلغاء تام» | Legal only from «راجع مكتب» |
| `15` | Coming back with the courier | `ReturnedCourier` «راجع لدى المندوب» | |
| `19` | Return sitting at the branch | `ReturnedCarrier` «راجع لدى شركة التوصيل» | |

### 3.1 The conflict, and the recommendation

**Our machine is stricter than their event stream, deliberately.** `OutForDelivery` allows only
`[Delivered, ReturnedCourier]`; `ReturnedCarrier` allows only `[ReturnedOffice, Resend]`. The
`OrderStatus` docblock says why in as many words:

> Allowing «جاري التوصيل» to jump straight to «راجع مكتب» would let the system record a parcel as
> being on our shelf while it is still in somebody's van.

Nawris does not walk that chain. A parcel can go from *out for delivery* to code `6` — sitting back
at their branch — with nothing in between. Three ways to handle it:

| Option | What it does | Verdict |
|---|---|---|
| **Auto-walk** the shortest legal path, recording each intermediate | Order always tracks the carrier | ❌ **Rejected.** It fabricates hand-overs nobody made — precisely the lie the chain exists to prevent |
| **Relax the machine** for carrier-driven moves | Simple | ❌ **Rejected.** A second opinion about what follows what, and it is the copy guarding the write |
| **Apply legal single transitions; park the rest** | Truthful; a human resolves the gap | ✅ **Recommended** |

So: `ApplyNawrisStatus` asks `canMoveTo($target, $order->production_flow)`. If it answers no, the
event row is stored with `error` set and `processed_at` left null, the raw label still lands on the
parcel, and it surfaces on the unmatched-events screen. **Received but never processed is the
failure mode that otherwise goes unnoticed for weeks** — so that screen is not optional, and it is
step 7 of [§10](#10-build-order).

**Code `5` needs a business answer.** «إلغاء تام» is unreachable from «جاري التوصيل» by design — an
order is not written off while it is physically outside the building. Mapping code 5 to
`ReturnedCourier` is the honest reading (the parcel is with the courier and is coming back), and the
carrier's own label is stored verbatim beside it. Confirm with operations before building.

---

### 3.2 What actually lands, and from where

The table in §3 is what each code *means*. This is what each code can actually **do**, which is a
different question — the target is applied only if `allowedNext()` permits it from where the order
already stands. Read down the column the order is in.

| Order is in… | Codes that land | Codes that park |
|---|---|---|
| «جاري التوصيل» — the normal dispatch state | `7` → «تم الاستلام» · `15`/`5`/`4` → «راجع لدى المندوب» · `3` → no-op, already there | `19` `6` `10` `12` |
| «راجع لدى المندوب» | `19` → «راجع لدى شركة التوصيل» | `6` `7` `10` `12` |
| «راجع لدى شركة التوصيل» | `6` → «راجع مكتب» · `10` → «إعادة إرسال» | `7` `12` `15` |
| «راجع مكتب» | `7` → «تم الاستلام» · `10` → «إعادة إرسال» · `12` → «إلغاء تام» | `19` `15` |
| «إعادة إرسال» | `3` → «جاري التوصيل» · `12` → «إلغاء تام» | `7` `6` `15` `19` |
| «تم الاستلام» | *none* | everything — `allowedNext()` is `[Settled]`, which no carrier code maps to |

**The happy path is clean.** Dispatch → `7` → delivered is one legal move, and it is the overwhelming
majority of traffic. The full return chain also walks correctly *if* Nawris emits each link.

**The parked column is the operational cost of [§3.1](#31-the-conflict-and-the-recommendation), and
it should be sized before building.** If Nawris skips intermediates — announcing `19` while we still
have the order in «جاري التوصيل», never having sent `15` — that parcel parks and a human has to move
it. Whether that is a handful a month or a daily queue depends on how chatty their webhook is, which
is one of the things nobody can know until real traffic arrives ([§7](#7-the-outbound-client)).

Two mitigations, neither of which weakens the machine:

- **The unmatched-events screen shows parked events with a one-tap "apply the intermediate"** — a
  human records the hand-over that genuinely happened, and the carrier's event then applies on top.
  The person confirms the physical fact; the system does not invent it.
- **Measure before optimising.** If one skip dominates, that is a conversation with Nawris about
  their event stream, not a reason to loosen `allowedNext()`.

**Once «تم الاستلام» is reached the carrier is locked out**, which is deliberate: the last row of the
table is what stops a late or duplicated webhook from disturbing a closed sale.

---

## 4. Geography

Nawris has `government` and `area`; we have `cities` and `regions`. Do **not** put a Nawris address
form in front of an operator — our order already knows where it is going.

- Add `nawris_government_id` to `cities` and `nawris_area_id` to `regions`. There is precedent:
  `cities.darb_branch` is already a carrier's own vocabulary parked on our row.
- `get-government` / `get-area` become **admin-only** endpoints, used once to populate that mapping.
  The contract's advice to expose them unauthenticated as a front-end proxy does not apply to us —
  no client of ours needs to pick a Nawris area.
- **Freeze both onto the parcel row at creation** and replay those exact values on every edit.
  Re-deriving the destination at edit time drifts, and an edit carrying a different area *moves the
  parcel*.
- A delivery city with no `nawris_government_id` refuses dispatch by name
  (`CityHasNoNawrisMapping`) rather than sending a null.
- Only `FulfilmentType::Delivery` cities go to a carrier at all. «استلام مكتب» never leaves.

---

## 5. Money

### 5.1 The webhook records a payment. It never settles an order.

This is the single most important modification, and it deletes an entire class of incident.

In Primula, code 7 moves the order to *paid* and releases merchant profit — one unauthenticated
HTTP call from the state of "money is owed" to "money is gone". Here:

```
code 7  →  ChangeOrderStatus(order, Delivered, actor: carrier system user)
        →  RecordOrderPayment(order, {amount: the remitted COD, method: Cash, …}, actor: same)
```

**The amount recorded is what Nawris remits to us, not what the customer handed the courier.**
Those differ by the carrier's own fee, and — since we subtract our delivery line before sending —
the COD payment alone leaves `orders.delivery_price` outstanding. A second, non-cash entry closes
that gap in the same transaction; see [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive).

Otherwise the webhook **stops** here. «تم التسوية» stays where it is: a human decision, guarded by
`SettlementRequiresFullPayment`, taken by someone holding `orders.status.settled`. The carrier
reports that the customer took the bags and handed over cash. Agreeing that the cash came back and
the books are square is our accountant's job, and no webhook gets to do it.

Three consequences to build for:

- **`RecordOrderPayment` refuses anything over the remainder** (`PaymentExceedsRemaining`). A COD
  that overshoots must not blow up the job. **Clamp to `remainingAmount()` and raise a price
  discrepancy for the excess** — an alert, not a refusal. → [§9.3](#93-the-three-guards)
- **`PaymentMethod::Cash` requires no receipt** (only `BankTransfer` does), so this path is clean.
- **A payout idempotence flag is still needed**, even though nothing is paid out. A duplicate code 7
  would otherwise write a second payment row. Add `carrier_collection_recorded_at` to **`orders`**,
  not to the parcel or the event — the contract is right that it must survive the parcel being
  deleted, re-created, or re-dispatched under a new code.

### 5.2 The delivery fee, and the guard it keeps alive

**Decided: our delivery fee is subtracted from the COD before the payload goes out.**

```
amount_to_be_collected = max(0, Order::remainingAmount() − orders.delivery_price)

                       // remainingAmount() expanded, so nothing is hidden behind a method name:
                       = max(0, grand_total
                               − paid_amount            // every deposit and installment already taken
                               − written_off_amount     // money forgiven is not money to collect
                               − delivery_price)        // the fee, per this section

shipment_on_sender     = 0     // their default — the courier collects their own fee on top
```

**`paid_amount` coming off is the contract's field rule #1**, and the reason it insists on one COD
function: *"if create and edit disagree, an edit silently re-bills money the customer already
paid."* One function — `BuildNawrisPayload` — is called by dispatch and by every edit, and a
payment landing after dispatch is itself an `edit-order` trigger ([§8](#8-when-we-call-them)) so the
figure Nawris holds follows the ledger rather than drifting from it.

**The clamp has one edge, and it is a real double-charge.** When `remaining ≤ delivery_price` — a
prepaid order, or one paid down to less than the fee — the subtraction cannot be fully absorbed and
`max(0, …)` discards the difference. The customer has already paid us for delivery inside
`grand_total`, and `shipment_on_sender = 0` then has the courier charge them again at the door. A
fully prepaid order is the clearest case: COD is `0`, and the customer pays Nawris's fee on top of a
delivery they have already settled.

The fix is one condition in `BuildNawrisPayload`, not a new concept:

```
shipment_on_sender = (remaining ≤ delivery_price) ? 1 : 0
```

When there is no COD left to carry the fee, the fee is billed to us — which is what the customer's
own payment already covered. `0` in every ordinary case, exactly as decided above.

The customer hands the courier our COD *plus* Nawris's own city fee. Nawris keeps their fee and
remits our COD. The customer pays for delivery exactly once — at the door, to the courier — instead
of once inside our `grand_total` and again to the courier on top of it.

Three consequences. The third needs an answer before this can ship.

#### 1 · Guard #2 stays, and the frozen fee becomes load-bearing

This is the reverse of what §5.2 said in the first draft. Because the courier still adds their fee
on top, `order_price` on the way back is **collected COD + their fee** — exactly the contract's
warning, and exactly why comparing the raw figure against what we asked for would raise a false
discrepancy on every single order.

So the parcel stores `delivery_price_deducted` — **our** fee, as taken off at dispatch, frozen.
Every edit replays it. Primula looks its fee up live by city name at comparison time, which lets a
tariff change retroactively rewrite history and disables the check entirely for an unlisted city.
Ours is a snapshot on the row, like `city_name` and every money column on `orders`.

#### 2 · The comparison becomes a floor, and that is better than the contract's version

We do not hold Nawris's tariff, and we do not need to. The reconciliation is:

```
carrier_fee = collected_amount − amount_to_collect      // derived, never stored
```

Anything *above* what we asked for is their fee. Anything *below* it is money missing, and that is
the only thing worth an alert. So the check is `collected_amount >= amount_to_collect`, which:

- needs no tariff table, so it never silently disables itself for a city nobody listed;
- cannot raise a false discrepancy from a fee we guessed wrong;
- still catches the case the guard exists for — an under-collection.

The derived fee is not stored, for the reason `Order::profit()` gives about its own inputs: a third
cached number could only ever disagree with the two it is computed from.

#### 3 · The order is left owing its own `delivery_price`, and settlement will block on it

**This is the real cost of the decision, and it is not optional to resolve.** Verified against the
code:

- `RecalculateOrderTotals` puts `delivery_price` **inside** `grand_total`.
- `PaymentStatus::for()` weighs `paid_amount + written_off_amount` against `grand_total`.
- `ChangeOrderStatus` refuses «تم التسوية» while that is outstanding (`SettlementRequiresFullPayment`).

So an order dispatched this way is delivered, its COD is remitted and recorded — and it stands for
ever in «تم الاستلام» owing exactly `delivery_price`, unable to reach «تم التسوية». That is precisely
the trap `WriteOffOrderBalance`'s own docblock was written about:

> …leave it standing in «تم الاستلام» for ever because «تم التسوية» refuses a debt.

Four ways out, kept on the record so the choice below is legible later:

| | Option | Verdict |
|---|---|---|
| **A** | Record the payment at the full `remainingAmount()` | ❌ Books say we received cash we never received. Violates the ledger's own rule: *«كم قبضنا اليوم؟» must never be handed a number containing money that never arrived* |
| **B** | Record the remitted COD, then write off `delivery_price` | ❌ Mechanically works, but `written_off_amount` is explicitly *a loss*. Every Nawris order would post a loss equal to its delivery fee, straight into P&L |
| **C** | **Don't bill delivery on Nawris orders** — `delivery_price = 0` for those cities | ✅ **Cleanest.** If the customer pays the courier directly, delivery was never our receivable and does not belong in `grand_total`. The subtraction becomes a no-op, the residual disappears, settlement works, and no new concepts are needed. Cost: the invoice no longer carries a delivery line, so the customer must be told the courier charges at the door |
| **D** | A third bucket: new `OrderPaymentType` case + `carrier_settled_amount` on `orders`, weighed by `PaymentStatus::between()` | ✅ Correct, and preserves the invoice exactly as it is. Cost: it touches the payments domain — a new enum case, a migration widening the `order_payments_shape` CHECK, and `movedCash()` answering **false** so cash-drawer reports stay honest |

**Chosen: D.** The instruction was to subtract at the payload, and D keeps that surgical — `grand_total`
still carries its delivery line, the customer's invoice is untouched, and the gap the subtraction opens
is closed by a bookkeeping entry rather than by rewriting what the customer was billed. C is smaller but
edits the invoice, which is more than was asked for.

What D costs, precisely:

- A new `OrderPaymentType` case — «سُدِّدت لدى الناقل». `isCredit()` **true**, `movedCash()` **false**
  (no cash reached our drawer, so cash-drawer reports stay honest), `namesAMethod()` **false**.
- A migration widening the `order_payments_shape` CHECK, which currently states the
  `namesAMethod()` rule in SQL and would reject the row otherwise.
- `carrier_settled_amount` on `orders`, maintained by `RecalculateOrderPayments` alongside
  `paid_amount` and `written_off_amount`.
- `PaymentStatus::between()` weighs `paid + written_off + carrier_settled` against `grand_total`.
  That one change is what unblocks «تم التسوية».
- **P&L is unaffected.** `delivery_price` is already excluded from recognised revenue — see
  [`ProfitAndLossSummaryQuery`](../../backend/app/Domain/Reporting/Queries/ProfitAndLossSummaryQuery.php):
  *"`additional_cost` is deliberately absent from revenue here, as `delivery_price` and `discount`
  already are."* So this moves a receivable, never an income line.

The entry is written by the same webhook that records the COD, in the same transaction, behind the
same `carrier_collection_recorded_at` flag — **one delivery, one pair of entries**, and a duplicate
code 7 writes neither.

**That transaction takes deadlock retries** — `DB::transaction($callback, attempts: 3)`. It locks the
order row twice through `RecordOrderPayment` while a clerk may be collecting on the same order at the
counter, and the contract asks for retries here for exactly that reason. The idempotence flag is what
makes retrying safe: a transaction that replays cannot double-credit.

Both entries are reversible the ordinary way (`ReverseOrderPayment`), so a delivery recorded in
error is undone without either a discount or a write-off.

---

## 6. Schema

Three tables. The contract argues for exactly this and it is right, with one simplification.

**On the link table:** with no consolidated parcels today it is 1:1 and looks redundant. It stays
because it is what makes consolidation *additive* later instead of a migration through live parcel
data, and because the "rebuild the whole parcel on edit" rule becomes a single query rather than a
rule somebody has to remember. Keyed **`(parcel_id, order_id)`**, never uniquely on `order_id` —
that is Primula's mistake, and it means re-dispatching requires deleting the link row and the
dispatch history goes with it. "At most one *open* parcel per order" is enforced in code against
`closed_at`.

### `nawris_parcels`

| Column | Type | Why |
|---|---|---|
| `code` | string, unique | Their handle. Without it: no edit, cancel, delete, resend, or webhook fallback |
| `reference` | string, unique | Ours, sent as `remote_order_id`. Primary match key. Never changes after creation |
| `bar_code` | string, indexed | Second fallback, and what is physically scanned |
| `government` · `area` | string | Destination **as sent**. Replayed on every edit |
| `amount_to_collect` | decimal(12,2) | What we asked them to **remit** — `remaining − delivery_price`, as sent. Rewritten on every successful edit |
| `delivery_price_deducted` | decimal(12,2) | **Our** fee as taken off at dispatch, frozen and replayed on every edit. Load-bearing — see [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive) |
| `collected_amount` | decimal(12,2) null | Raw `order_price` — **includes the carrier's own fee**. The carrier fee is `collected_amount − amount_to_collect`, derived, never stored |
| `remote_status_code` | smallint null | **Their integer.** Primula stored only the label — unstable prose — and the mapping is written against the code |
| `remote_status_text` | string null | Their label verbatim, for support |
| `shipping_company_id` | fk | The Nawris row in `shipping_companies`, so existing carrier filters keep working |
| `conflict_raised_at` · `conflict_resolved_at` | timestamp null | A flag plus a resolution time; the event log explains the rest |
| `dispatched_at` · `closed_at` | timestamp | `closed_at` makes "still out there" a query, not a status list to keep in sync |

### `nawris_parcel_orders`

`parcel_id` (fk, indexed) · `order_id` (fk) · `amount_to_collect` decimal(12,2) — this order's share,
as sent. Unique on `(parcel_id, order_id)`.

### `nawris_webhook_events`

`payload` json (verbatim — **they do not re-send; anything not stored is gone permanently**) ·
`fingerprint` string unique (duplicate suppression as a database constraint, not a status comparison
that a type mismatch can silently kill) · `parcel_id` fk **nullable on purpose**, so an unmatched
webhook still gets a row that can be inspected and replayed · `code` · `reference` (copied out and
indexed, so unmatched rows are searchable) · `status_code` · `collected_amount` · `received_at` ·
`processed_at` · `error`.

### On `orders`

`carrier_collection_recorded_at` timestamp null — see [§5.1](#51-the-webhook-records-a-payment-it-never-settles-an-order).

### House rules that apply to all three

`NawrisParcel` and `NawrisParcelOrder`: `use Auditable, SoftDeletes`, a `softDeletes()->index()`
column, and a case in [`AuditSubject`](../../backend/app/Domain/Audit/Enums/AuditSubject.php) —
`nawris_parcel`, `nawris_parcel_order`. `ModelConventionsTest` fails the build otherwise, and
**every unique index is partial** (`WHERE deleted_at IS NULL`), including `code`.

**`NawrisWebhookEvent` is the exception, and there is a precedent for it.**
`ModelConventionsTest::NOT_A_BUSINESS_RECORD` already exempts `ActivityLog` from all three rules,
because *"a log entry that logged itself would recurse, and one that could be deleted — softly or
otherwise — would not be an audit trail."* The webhook log is the same kind of object: an immutable
record of what arrived. Auditing it would write an `activity_log` row for every inbound webhook to
describe a row that is already immutable, and soft-deleting it would defeat its purpose. So it joins
that constant, with the reasoning stated there — a decision, not an omission.

That makes `fingerprint` a **plain** unique index rather than a partial one, which is what we want:
there are no soft-deleted rows for it to have to ignore.

---

## 7. The outbound client

### 7.1 Their envelope is not uniform

Budget for all five of these in `NawrisClient`, not in calling code:

- **Failures arrive as HTTP 200.** A logical error is `{"success": 0, "error_msg": "…"}` with a
  successful status line. Checking the HTTP code alone treats every failure as a success.
- **The payload key varies** — `result` on some endpoints, `feed` on others. Accept either, default
  to empty.
- **Delete and cancel use a different envelope** (`success == 1`) and cannot share the create/edit
  handler.
- **`order_price` arrives as a string.** Normalise numerically before any comparison.
- **Log the whole `errors` object** on a dedicated channel. A bare "request failed" gives support
  nothing.

Credentials (`authentication_key`, `main_client_code`) are **body fields, not headers**, merged into
every request. Config in `config/services.php` under `nawris`; keys added to `.env.example`.
Timeouts explicit. **Never log the credentials** — add both keys to the logging scrubber.

### 7.2 The payload

24 fields exist; we set eleven and let the rest default. Nulls and empty arrays are stripped before
sending — **which matters on `edit-order`, where omitting a field leaves their copy untouched rather
than clearing it.**

| Field | What we send |
|---|---|
| `receiver` | The order code. Not a person's name — it is what is read off the label at handover |
| `phone1` | `recipient_phone`, else the customer's, normalised to `+218…`, falling back to `+218910000000` when blank so validation never fails |
| `government` · `area` | From the city/region mapping, frozen at creation |
| `amount_to_be_collected` | `max(0, grand_total − paid_amount − written_off_amount − delivery_price)`. **Deposits, installments and the fee all come off here** — [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive). One function, called by dispatch and by every edit |
| `remote_order_id` | `{orderCode}_{unixTime}`, stable across edits |
| `order_summary` | A fixed description string; not itemised |
| `can_open` · `is_measurable` | **Business question** — Primula sets these for locally sourced goods. Default `0` until answered |
| `shipment_on_sender` | `0` — their default; the courier collects our COD **plus their own fee** at the door. Flips to `1` when `remaining ≤ delivery_price`, or a prepaid customer pays for delivery twice — [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive) |
| `return_amount` `is_order` `pieces_count` `extra_cost_payer` `is_office_given` `is_fragile` `accept_20_plus_5_dinar` | Constants: `0.0`, `0`, `1`, `1`, `0`, `0`, `0` |
| everything else | Never sent — null or empty, therefore stripped |

### 7.3 The `try`/`catch` ban

`ErrorHandlingTest` greps `app/` for `try {` and `catch (`. Three sanctioned ways through:

- `Http::…->throw(fn ($response, $e) => throw NawrisRequestFailed::make(…))` — the callback
  translates a transport failure into a typed domain exception with no catch block.
- The HTTP-200-with-`success: 0` case needs no rescue at all: we read the body and
  `throw NawrisRejectedRequest::make($errorMsg)` ourselves.
- Inside the job, where a failure must not roll back a state change,
  `rescue(fn () => …, rescue: false, report: true)` is the sanctioned escape hatch (RULES §5).

Domain exceptions extend `DomainException`, carry Arabic user messages, and render through the
existing boundary with no registration step.

---

## 8. When we call them

Dispatch is gated on order state exactly as the contract demands, and our state machine already
expresses the gate. **The call is made from the Application layer after `ChangeOrderStatus` commits**
— not from inside the action — so `Order` never imports `Carrier` and a carrier outage can never
roll back a legitimate status change.

| Our event | Their call | What we enforce first |
|---|---|---|
| Order → «جاري التوصيل» | `add-order` | Delivery city with a Nawris mapping; no open parcel already |
| Order → «إعادة إرسال» | `resend-request` | The parcel came back; a new code arrives by webhook, often with an `N` suffix |
| Payment or write-off recorded while a parcel is open | `edit-order` | **The only edit trigger there is** — see below |
| Operator calls off a live shipment | `canceled` | A parcel-level action that **does not move the order** — see below |
| *(none)* | `delete-order` | **No legal trigger. Not built** — [§11](#11-deliberately-not-built) |

#### Three corrections the state machine forces, found by walking it

**1 · A phone or address correction cannot trigger an edit.** `Order::destinationIsEditable()` is
`false` at «جاري التوصيل», so `UpdateOrder` throws `DestinationCannotChange` and
`RecipientPhoneCannotChange` for exactly the window in which a parcel is live. `recipient_name` *is*
still editable there — but `receiver` in the payload is the **order code**, not a person's name
([§7.2](#72-the-payload)), so a name change does not alter what we would send anyway.

**So money is the only thing that can change on a live parcel, and `edit-order` has exactly one
trigger.** That is a simplification, not a loss: it is also the only edit the contract warns can
silently re-bill a customer.

**2 · `delete-order` has no trigger and is dropped.** It means "undo the dispatch", and our machine
has no such move — «جاري التوصيل» leads only to «تم الاستلام» and «راجع لدى المندوب». Adding a way
back to «جاهزة» would be a change to the state machine, which is out of scope here. The
operational need it serves is covered by `canceled` below.

**3 · `canceled` is a parcel action, not an order transition.** «إلغاء تام» is unreachable from
«جاري التوصيل» by design — *an order is not written off while it is physically outside the
building*. So calling off a shipment cannot be modelled as a status change. It is its own
permissioned endpoint that calls their `canceled`, stamps the parcel and writes a timeline note,
and **leaves the order in «جاري التوصيل»**. The goods still have to come back, and they come back
the ordinary way: codes 15 → 19 → 6.

> **Unverifiable until a real call:** the contract says `resend-request` takes `order_code` = *your
> new local order id*, because Primula mints a fresh order for a re-send. We do not — «إعادة إرسال»
> is the same order. Our `reference` is per-parcel and so is genuinely new, but whether Nawris
> accepts a repeated `order_code` is unknown. If it refuses, the fallback is a suffixed reference
> (`{code}_R2`) with `order_code` left stable.

**Wrap the write in a transaction.** Create the parcel and link rows in the same transaction as the
API call, and only when the response actually carries a `code`. *A shipment that exists at the
carrier but not in our database is invisible to every later webhook — it will arrive, fail to match,
and be logged as an error nobody reads.*

#### The mirror failure: dispatched locally, never lodged with the carrier

Because the carrier call deliberately happens **after** `ChangeOrderStatus` commits — so a Nawris
outage can never roll back a legitimate status change — the two can disagree in the other direction.
If `add-order` fails, the order stands at «جاري التوصيل» with no parcel, no code, and no webhook that
will ever arrive for it. Nothing is wrong with the order; it simply is not lodged.

Rolling the status back would be the wrong fix — the parcel is physically going out, and the machine
has no move back to «جاهزة» anyway ([§8](#8-when-we-call-them) correction 2). So treat it as a
retryable state rather than an error:

- **The query:** orders at «جاري التوصيل», in a Nawris-mapped city, with no open parcel. This is the
  outbound twin of "received but never processed", and it wants the same alert.
- **A `retry dispatch` action** on the order, so an operator or a scheduled sweep lodges it without
  touching the status.
- **The dispatch response says so.** A failed lodge returns a distinguishable message — the parcel is
  going out, the carrier does not know about it yet — rather than a generic 500 that reads as "the
  dispatch failed" when the dispatch is exactly what succeeded.

---

## 9. The inbound webhook

`POST /api/v1/webhooks/nawris`, outside `auth:sanctum`. The handler does **nothing but log, queue,
and return 200** — Nawris gets a fast acknowledgement, and our processing failures do not look like
delivery failures to them.

> **⚠️ Deployment: a queue worker has to actually be running, and today none is.**
> `QUEUE_CONNECTION=database` is already configured, but this integration introduces the repo's first
> job — so there has never been a reason to run `queue:work`, and nothing currently fails if it is
> absent. If it is not running in production, **every webhook is accepted, stored, answered `200`,
> and never processed**: orders silently stop moving while Nawris sees perfect delivery. This is the
> single most likely way for the integration to fail quietly.
>
> Two things follow: the worker belongs in the deployment checklist with a supervisor watching it,
> and the "received but never processed" query in [§10](#10-build-order) needs an alert on it rather
> than a screen somebody remembers to open.

### 9.0 The gate

The contract's own warning is the thing to fix, not copy:

> Primula has an IP-allowlist middleware written and registered, but it is **not attached to the
> webhook route** — the shared bearer token is the sole gate, and anyone holding it can move orders
> to paid and trigger payouts.

So: a `VerifyNawrisWebhook` middleware doing a constant-time `hash_equals` on the shared secret
**plus** an IP allowlist that is actually attached, plus a `throttle`. Both are config-driven.
Exclude the route from the Scramble spec — it is their contract, not ours.

### 9.1 Resolving which order it means

Three tiers, in order. **The fallbacks are not optional** — they catch traffic that would otherwise
vanish, and resend codes frequently arrive with no `remote_order_id` at all:

1. `reference` (their echo of `remote_order_id`) → our parcel.
2. Failing that, `order_code` against the stored `code`.
3. Failing that, `order_code` against the stored `bar_code`.

Both columns indexed. **A miss is a stored row with a null `parcel_id`, not a dropped log line.**

### 9.2 Idempotency

Two layers, because one is not enough:

- The unique `fingerprint` — a hash of the meaningful fields — makes duplicate suppression a
  database constraint.
- A target-state comparison in `ApplyNawrisStatus`. **The trap the contract names applies to us
  exactly:** our `status` column is a cast enum, and comparing an enum to a plain string is always
  false, which kills the guard silently. Compare `OrderStatus` to `OrderStatus`.
- **Exception: still record a price discrepancy on a skipped duplicate**, or the alert is swallowed.

### 9.3 The three guards

All three exist because of incidents. Reimplementing the mapping without them reimplements the
incidents. Order matters: **idempotency first, conflict second, price alert third.**

**Delivery conflict.** The incident: *a parcel belonging to a different customer arrived carrying our
correlation id; the order was closed as delivered and profit paid out while our goods were coming
back unsold.* On code 7, compare the incoming parcel code against the stored one. A different code
alone proves nothing — a legitimate re-send arrives under a new code — so the decision is compound:

| Situation | Action |
|---|---|
| Different code **+** amount mismatch | **Block the transition entirely.** No `Delivered`, no payment row. Raise the flag, wait for a human |
| Different code, amount matches or cannot be checked | Let it through, raise the flag for review. *Freezing an order on unproven suspicion is worse than a late review* |
| Same code, no discrepancy | Proceed — and this is the only moment trustworthy enough to auto-clear an older open conflict |

**Price discrepancy — alert, never block.** An earlier version of Primula blocked, which froze
orders indefinitely at "with the courier" while cash that had genuinely been collected sat outside
the books. Append the numbers to the timeline note so staff read one message rather than two, and
let the state machine continue.

The comparison is the floor from [§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive), at two
decimal places with a small epsilon:

```
flag when   collected_amount  <  amount_to_collect − ε
otherwise   carrier_fee = collected_amount − amount_to_collect     // theirs, expected, fine
```

`order_price` **arrives as a string** — normalise it numerically before this runs, or the
comparison is decided by PHP's string rules rather than by arithmetic.

### 9.4 Blast radius — what Nawris may write

Attributed to a synthetic carrier system account (a seeded, non-loginable `User`) so it is
distinguishable from staff in the audit trail. **Set the activity causer explicitly** — a queued job
has no signed-in user for `Auditable` to pick up.

> **The status map is the security boundary here, not the permission system.**
> `OrderStatus::permission()` is enforced in
> [`ChangeOrderStatusRequest::authorize()`](../../backend/app/Application/Api/V1/Requests/Order/ChangeOrderStatusRequest.php),
> a FormRequest — so it guards the HTTP route, not the action. The job calls `ChangeOrderStatus`
> directly and **no permission is checked on that path at all**. That is the correct architecture —
> the domain does not know about permissions — but it has two consequences worth being deliberate
> about:
>
> - **Grant the carrier account no permissions whatsoever.** It never needs any, and if some future
>   code ever routes it through HTTP, it is refused rather than quietly allowed.
> - **`NawrisStatusCode` is the only thing deciding what a webhook may reach.** Adding a case to that
>   enum widens the blast radius with no permission gate to stop it, so it is reviewed as a
>   security change, not as configuration.

#### On `orders`

| Field | Written when | Note |
|---|---|---|
| `status` | any mapped code that is legal from where the order stands | **Seven reachable values** — «جاري التوصيل» · «راجع لدى المندوب» · «راجع لدى شركة التوصيل» · «راجع مكتب» · «إعادة إرسال» · «تم الاستلام» · «إلغاء تام». Always through `ChangeOrderStatus`, never by assignment. See [§3.2](#32-what-actually-lands-and-from-where) |
| `dispatched_at` `delivered_at` `returned_at` `cancelled_at` | whichever the new status stamps | `OrderStatus::timestampColumn()` decides. «إعادة إرسال» stamps nothing — an order can visit it twice, and one column would lose the first visit |
| `cancellation_reason` | code `12` | **Required, not optional** — see the trap below |
| `courier_phone` | any webhook carrying `captain_phone` | Overwrites. Last courier wins |
| `carrier_collection_recorded_at` | code `7` | The idempotence flag. Guards **both** money entries |
| `paid_amount` · `carrier_settled_amount` | code `7` | **Not written directly.** `RecalculateOrderPayments` re-derives both from the entries below — neither column is fillable |

#### Rows created

| Table | When | Contents |
|---|---|---|
| `order_payments` | code `7` | **Two rows in one transaction** — the COD payment and the carrier-settled entry ([§5.2](#52-the-delivery-fee-and-the-guard-it-keeps-alive)) |
| `order_status_transitions` | every applied move | `from_status`, `to_status`, `reason`, `user_id` = the carrier account |
| `nawris_webhook_events` | **every webhook, processed or parked** | Payload verbatim + fingerprint |
| `activity_log` | every write above | Causer set explicitly to the carrier account |

#### On `nawris_parcels`

| Field | Written when | Note |
|---|---|---|
| `remote_status_code` · `remote_status_text` | every webhook carrying a label, **mapped or not** | Raw and verbatim, for support to read |
| `collected_amount` | code `7` | Raw `order_price`, normalised from string first |
| `conflict_raised_at` · `conflict_resolved_at` | code `7` | Guard #2 — raised, or auto-cleared on a clean delivery |
| `closed_at` | a terminal outcome — `6`, `7`, `12` | Makes "still out there" a query rather than a status list to keep in sync |

**Most of this lands even when the status move is parked.** A refused transition still stores the
event row, the raw carrier label, the courier's phone and the collected amount — parking a move
discards the *state change*, never the information. That is what makes a parked event resolvable
later instead of merely lost.

> **⚠️ Trap: «إلغاء تام» demands a reason, and the webhook has none.**
> `OrderStatus::Cancelled->requiresReason()` is true, and `ChangeOrderStatus` throws
> `TransitionRequiresReason` when it is null — so **every code `12` would fail** unless one is
> supplied. Use `return_reason` from the payload, falling back to a synthetic Arabic line naming the
> carrier and the code when they send none. The same applies to any future code mapped to a status
> that requires a reason.

**May never write:** prices, discounts, order contents, customers, deposits, installments,
write-offs, **settlement**, or the deletion of anything. The carrier reports on a parcel's journey;
it does not get write access to the commercial record.

---

## 10. Build order

Dependency order. 1–5 get parcels moving; 6–9 are what keep the money right.

1. **The carrier-settled entry** — the `OrderPaymentType` case, the CHECK-widening migration, `carrier_settled_amount`, and `PaymentStatus::between()`. Built **first** because step 8 writes through it, and because it is the only step that touches an existing domain. Two small business answers can be gathered in parallel and are not blocking: [§3.1](#31-the-conflict-and-the-recommendation) (what code 5 means) and `can_open`.
2. **Geography mapping** — two columns, admin endpoints, the two cached lookups.
3. **Schema** — three tables, one order column, three `AuditSubject` cases, partial unique indexes.
4. **`NawrisClient` + config** — credentials in the body, split response handlers, typed exceptions, a dedicated log channel, scrubbed secrets.
5. **`DispatchToNawris`**, wired from the Application layer at «جاري التوصيل», in one transaction, refusing anything unmapped or already linked.
6. **Webhook endpoint** — constant-time bearer, IP allowlist actually attached, throttle, log, queue, 200. No business logic in the request cycle.
7. **The three-tier resolver + the unmatched-events screen.** Build them together; a resolver whose misses nobody can see is a resolver nobody trusts.
8. **The status map and the three guards**, in order, with the legal-transition check from [§3.1](#31-the-conflict-and-the-recommendation).
9. **`edit` / `cancel` / `delete` / `resend`**, each triggered from its own existing event.
10. **Permissions, and the frontend.**

### Testing

PHPUnit, AAA, real PostgreSQL, `Http::fake()` throughout — **no test may reach the carrier**. Every
incident in the contract becomes a named regression test:

- a duplicate code 7 writes exactly one payment row;
- a code 7 under a different code with a mismatched amount leaves the order untouched and flagged;
- **a collection that exceeds `amount_to_collect` by the carrier's fee raises no discrepancy** — the false-positive-on-every-order case guard #2 exists to prevent;
- **an order dispatched via Nawris reaches «تم التسوية» without a write-off** — COD plus the carrier-settled entry together cover `grand_total`;
- **a cash-drawer report for that day does not contain the carrier-settled amount** — `movedCash()` is false, and this is the assertion that keeps «كم قبضنا اليوم؟» honest;
- a duplicate code 7 writes **neither** entry a second time;
- **a deposit taken before dispatch is off the COD, and one taken after dispatch triggers an `edit-order` that lowers it** — the re-billing case the contract's field rule #1 exists for;
- **a fully prepaid order sends COD `0` and `shipment_on_sender = 1`**, so the customer is not charged for delivery twice;
- `delivery_price` changing after dispatch does not rewrite what an earlier parcel deducted;
- a price discrepancy alerts and does **not** block;
- codes 6 and 12 reach a terminal state rather than falling through as unmapped;
- an illegal transition parks the event with `processed_at` null and changes nothing;
- an unmatched webhook stores a row with a null `parcel_id`;
- **a failed `add-order` leaves the order dispatched and retryable**, not rolled back, and it shows up in the not-lodged query;
- **`canceled` leaves the order in «جاري التوصيل»** — calling off a shipment is not writing off an order;
- **a code `12` carrying no `return_reason` still cancels**, with the synthetic reason — the `TransitionRequiresReason` trap in [§9.4](#94-blast-radius--what-nawris-may-write);
- **a parked transition still stores the event, the raw label, the courier phone and the collected amount** — only the state change is withheld;
- an enum-vs-string comparison cannot silently disable the idempotency guard.

### Frontend (Flutter) touch points

The dispatch sheet gains a Nawris option on delivery cities; the order screen shows the parcel code,
barcode and the carrier's own label beside our status; a small admin screen lists unmatched and
unprocessed webhook events and lets someone with the right permission resolve a delivery conflict.

---

## 11. Deliberately not built

**`delete-order`.** It means "undo the dispatch", and the state machine has no such move — see
[§8](#8-when-we-call-them). Building it would require either a new transition out of «جاري التوصيل»
or a carrier call with no local event behind it. `canceled` covers the real need.

**A local "cancel while out for delivery" transition.** Tempting, and wrong for the reason
`OrderStatus` already gives: an order is not written off while it is physically outside the
building. It comes home first.

Also: consolidated parcels (until the business asks for them — the link table is what keeps that
additive); an invoice-number column; courier name as anything but an event field; a reconciliation
or polling job — *everything after dispatch arrives by webhook*, which is exactly why the webhook
handler is where all the risk lives; parcel dimensions, weight, piece count, fragile and can-open
flags, all currently constants; and any second copy of the order's own status — the order owns that,
and a copy will drift.

---

*Compiled against the running Printing codebase and the Primula-derived contract. Their status codes
and envelope shapes are what an observed system reports, not what Nawris documents. **Verify against
Nawris before relying on any of it.***
