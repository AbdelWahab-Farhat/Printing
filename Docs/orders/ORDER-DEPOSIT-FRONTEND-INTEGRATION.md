# العربون — connecting the Flutter app

> **Status: done.** The backend was built, tested and merged; the app has now been wired to it,
> on this same branch. The three contract tests in §0 are green, the card in §6 is built and the
> whole checklist in §9 is ticked. What follows is the record of what was built and why — read
> §6 and §10 if you are picking this up.
>
> One thing changed outside the plan, and it is recorded in §10: the two new statuses pushed the
> filter sheet past the height ceiling it is allowed, which cost a test its old claim.
>
> The feature adds two order statuses — **«انتظار العربون»** and **«عربون مدفوع»** — an agreed
> deposit figure recorded when the order is parked, and a boolean an employee ticks afterwards to
> confirm the money actually arrived.
>
> Why it is shaped the way it is: [ORDER-DEPOSIT.md](ORDER-DEPOSIT.md) (Arabic, the permanent
> record) and [ORDER-DEPOSIT-PLAN.md](ORDER-DEPOSIT-PLAN.md) (the decisions and the options that
> were rejected).

---

## 0. What is already broken, and what merely looks empty

**Three contract tests in this repository fail right now**, and all three are doing exactly the job
they were written for. They go green as you work through §2–§4; none of them needs a change of its
own.

| Test | Why it fails | Fixed by |
|---|---|---|
| `test/features/orders/order_status_contract_test.dart` | It reads `OrderStatus.php` and compares every wire value and every Arabic label against this app's enum. Two statuses are now missing here. | §2 |
| `test/core/permissions/permission_contract_test.dart` | Same arrangement against `PermissionName.php`. Three permissions are missing. | §3 |
| `test/features/orders/order_resource_contract_test.dart` | It compares every key `OrderResource` publishes against every key the generated `fromJson` parsers read — «the failure that has no symptom». Ten new keys are published and dropped. | §4 |

**Nothing is broken at runtime.** An order that walks the deposit road opens, pays, prints and
settles correctly today:

- The status chip falls back to `OrderStatus.unknown` — a neutral chip wearing the **server's own**
  `status_label`, so the word on screen is right even in the current build. That fallback is why
  the whole list does not fail to parse; see the note on `unknown` in `order_status.dart`.
- The status screen already draws the two new moves and every field they ask for, **with no app
  change at all** — see §5. All three field types they use are ones this app already renders.
- The deposit figure, the claim and the confirmation are silently dropped from `Order`, so nothing
  on the order screen says a deposit was ever asked for.

So the order of work is: §2 makes the statuses read correctly, §4 makes the figures visible, and
§6 is the only genuinely new screen element.

---

## 1. What the server now sends and accepts

### 1.1 Two statuses

| Wire | Arabic (copy exactly — the contract test compares it) |
|---|---|
| `awaiting_deposit` | `انتظار العربون` |
| `deposit_paid` | `عربون مدفوع` |

They sit **third in `OrderStatus::cases()`**, after `new`/`shortage` and before `designing` — which
is the order the home board draws its cards in, two to a row. The board is built from
`cases()` server-side, so «انتظار العربون»/«عربون مدفوع» already appear on `/home/summary` as their
own row with their own counts, with no app change.

The road, for context (the app never holds a copy of it — `available_transitions` is the source):

```
جديدة ──┬──→ the usual road
        └──→ انتظار العربون ──→ عربون مدفوع ──→ where «جديدة» leads on this order's flow
                   ↑                  │
                   └──────────────────┘
```

### 1.2 Ten new keys on the order

Published by `OrderResource` on every order, deposit or not:

```jsonc
{
  // The arrangement. NOT money that has moved — `paid_amount` is where a real deposit appears.
  "deposit_expected_amount": "250.00",        // null on an order nobody asked a deposit of;
                                             // "0.00" on a zero-invoice order — §10
  "deposit_expected_method": "cash",
  "deposit_expected_method_label": "كاش",

  // The claim: when the order was *said* to have been paid. Cleared if the claim is walked back.
  "deposit_paid_at": "2026-09-13T10:04:00+02:00",

  // The confirmation — an employee's tick, and nothing derives it.
  "is_deposit_received": false,
  "deposit_confirmed_at": null,

  // Whether THIS user may tick it. See §6 — do not try to derive this.
  "can_confirm_deposit": true,

  // A deposit declared paid that nobody has confirmed — the accountant's queue.
  "awaits_deposit_confirmation": true,

  // Only on the single-order payload, absent from list rows (like `ready_message_sent_by`).
  "deposit_claimed_by":   { "id": 3, "name": "عبدالوهاب" },
  "deposit_confirmed_by": null
}
```

### 1.3 One new endpoint

```
PATCH /api/v1/orders/{order}/deposit-receipt      body: { "received": true|false }
```

Grant: **`orders.deposit.confirm`**. Answers with the whole order, exactly as
`PATCH /orders/{order}/ready-message` does, so the row redraws from the response rather than from
the tap. Messages: `تم تأكيد استلام العربون` / `أُلغي تأكيد استلام العربون`.

Refusals, both 422 with the envelope's `message`:

- `لا يمكن لمن نقل الطلبية إلى «عربون مدفوع» أن يؤكّد استلام العربون — يلزم شخص آخر`
- `لا يوجد عربون على هذه الطلبية لتأكيد استلامه`

Neither should ever be reached from a correct screen — `can_confirm_deposit` and
`deposit_expected_amount` answer both in advance.

### 1.4 Three new permissions

| Value | Arabic |
|---|---|
| `orders.status.awaiting_deposit` | `تحويل الطلبية إلى انتظار العربون` |
| `orders.status.deposit_paid` | `تحويل الطلبية إلى عربون مدفوع` |
| `orders.deposit.confirm` | `تأكيد استلام العربون` |

The first two are in the «حالات الطلبيات» group on the roles screen; the third is in «مدفوعات
الطلبيات», because it is a check on the books rather than a move on the map.

---

## 2. `OrderStatus` — two cases

`lib/features/orders/models/order_status.dart`. Declaration order matters: the filter sheet reads
down in `cases()` order, so put them after `shortage` and before `designing`.

```dart
@JsonValue('awaiting_deposit')
awaitingDeposit('awaiting_deposit', 'انتظار العربون'),

@JsonValue('deposit_paid')
depositPaid('deposit_paid', 'عربون مدفوع'),
```

Then the two `switch`es that are exhaustive over the enum:

- **`tone`** — suggestion: `attention` for `awaitingDeposit` (the same family «نواقص» draws from:
  both answer «لا يمكن البدء بعد»), and `fresh` for `depositPaid` (money in, nothing started —
  «جديدة» one step later).
- **`order_status_chip.dart`'s icon switch** — two new arms. The pair is read side by side in a
  list, so give them shapes that differ at a glance: an hourglass for waiting, notes or a
  price-check for paid. Deliberately **not** a tick for `depositPaid` — a tick says «تأكّدنا», and
  confirming the money is a separate control (§6).

`isFinished` needs no arm: both are unfinished, which is what the `_ => false` default already
says, and they join «الطلبات الجارية» automatically.

---

## 3. `AppPermission` — three cases

`lib/core/permissions/app_permission.dart`, values and Arabic copied from §1.4. Only
`confirmDepositReceipt` is read by any screen, and even it is **not** what gates the switch — see
§6.

---

## 4. `Order` — the ten keys

`lib/features/orders/models/order.dart`, then `dart run build_runner build --delete-conflicting-outputs`.

```dart
@JsonKey(name: 'deposit_expected_amount') String? depositExpectedAmount,
@JsonKey(name: 'deposit_expected_method') String? depositExpectedMethod,
@JsonKey(name: 'deposit_expected_method_label') String? depositExpectedMethodLabel,
@JsonKey(name: 'deposit_paid_at') DateTime? depositPaidAt,
@JsonKey(name: 'is_deposit_received') @Default(false) bool isDepositReceived,
@JsonKey(name: 'deposit_confirmed_at') DateTime? depositConfirmedAt,
@JsonKey(name: 'can_confirm_deposit') @Default(false) bool canConfirmDeposit,
@JsonKey(name: 'awaits_deposit_confirmation') @Default(false) bool awaitsDepositConfirmation,
@JsonKey(name: 'deposit_claimed_by') OrderActor? depositClaimedBy,
@JsonKey(name: 'deposit_confirmed_by') OrderActor? depositConfirmedBy,
```

**Default `canConfirmDeposit` to `false`, not `true`.** A build talking to an older API then greys
the switch, which is the safe way round.

`OrderActor` already exists — it is what `ready_message_sent_by` parses into.

---

## 5. The status screen — nothing to do

This is worth stating explicitly so nobody builds a deposit form: **both moves already work in the
current build.** `TransitionFields` describes them and the screen draws whatever it is told.

| Move | Fields the server sends |
|---|---|
| «انتظار العربون» | `deposit_amount` (`number`, **required**, min 0.01, max = the invoice, opens on what was agreed last time) · `deposit_method` (`payment_method`, `required_with: deposit_amount`) · `reason` |
| «عربون مدفوع» | `payment_amount` · `payment_method` · `payment_receipt` — **the existing money block**, all optional, the amount pre-filled with the agreed figure (or the remainder, whichever is smaller) and the method pre-filled from what the order says · `reason` |

All three types — `number`, `payment_method`, `file` — are already implemented in
`TransitionFieldInput`. No new `TransitionFieldType`, so no release is needed on the server's
account for the fields themselves.

Two behaviours worth knowing while testing:

- **The money block is withheld from a user without `orders.payments.record`, and the move is
  not.** A clerk who may not touch the till still moves the order; they simply get no money box.
- **Moving to «عربون مدفوع» never requires a payment.** The claim is made on the customer's word so
  the job can start; the money may be recorded later from the payments screen.

---

## 6. The one new screen element — the confirmation switch

A card on the order screen, drawn **only when `order.depositExpectedAmount != null`**. Read that
rather than the status: a deposit is confirmed long after the order has moved on, often after it
has shipped.

```
┌────────────────────────────────────────────────┐
│ ⏳  العربون 250.00 · كاش                        │
│ ───────────────────────────────────────────────│
│ تأكيد استلام العربون                    ( ●—— )│
│ يؤكّد استلامَ العربون موظفٌ غير مَن نقل الطلبية    │
└────────────────────────────────────────────────┘
```

`SwitchListTile.adaptive`, the same shape as `OrderReadyMessageSwitch` — and that widget is the one
to copy: the whole row taps, the green `scheme.paid` track means «انتهى هذا» here as everywhere
else, and who/when prints underneath once it is on.

### The rule that makes this different from every other switch

**`onChanged` is gated by `order.canConfirmDeposit`, never by the permission alone.** The server
folds two things into that boolean: the grant, *and* the rule that whoever moved the order to
«عربون مدفوع» may not confirm it. The app cannot evaluate the second — it does not know who made
the claim until `deposit_claimed_by` arrives, and on a list row it never does.

So: `onConfirm: order.canConfirmDeposit && !order.isArchived && !state.isWorking ? _confirm : null`.

**And write the reason under a greyed switch.** A grey switch with nothing under it reads as a
broken screen, and this particular rule is not one a person standing in front of it can guess:

| State | Subtitle |
|---|---|
| Confirmed | `أكّده {name} · {stamp}` — the name is the record itself, not a footnote |
| Greyed, and `deposit_claimed_by` is this user | `يؤكّد استلامَ العربون موظفٌ غير مَن نقل الطلبية` |
| Greyed for any other reason | `بانتظار التأكيد` |
| Live and unticked | `لم يُؤكَّد استلامه بعد` |

### Show the one contradiction; block nothing

When `isDepositReceived` is true and `paidAmount` is `"0.00"`, print a red line —
`أُكِّد استلام العربون ولم تُسجَّل دفعة عليه` — in the same spirit as «الطلبية منتهية ولم يُسجَّل
قبض». The tick is a person's statement and the ledger is arithmetic; the gap between them is the
accountant's job, so it is surfaced and not prevented.

### Wiring

`ConfirmDepositReceipt` use case → `OrderRepository.confirmDepositReceipt(orderId, received:)` →
`OrderDetailCubit.confirmDepositReceipt`, all three modelled line for line on `ConfirmReadyMessage`.
The endpoint goes in `OrderEndpoints`:

```dart
static String depositReceipt(int orderId) => '/orders/$orderId/deposit-receipt';
```

No dialog in either direction: the undo is the same switch. Hand the updated order back to the list
(`context.handBack`) like the ready-message switch does.

---

## 7. What is deliberately **not** wired to anything

**`is_deposit_received` gates nothing, and must not start to.** No status change, no production
step, no dispatch and no settlement reads it — an order at `false` prints, ships and settles
exactly like one at `true`, and the backend has a test whose whole job is to fail if anybody wires
the flag into a guard. Do not add an app-side rule the server does not have: no greyed «تغيير
الحالة», no warning dialog before dispatch, no filter that hides unconfirmed orders from the work
queues.

What the flag feeds is a **queue**, and that is the one place it is worth reading in aggregate:
`awaits_deposit_confirmation` is «عربون أُعلن ولم يُؤكَّد». A box for it on the home screen, beside
«بانتظار رسالة الجاهزية», is the natural next step — but the server does not count it yet, so it is
a backend change first. Out of scope here.

---

## 8. Tests to add

- **`order_deposit_card_test.dart`** — the card is absent when `depositExpectedAmount` is null;
  present and live for a colleague; **greyed with its reason for the claimer**
  (`canConfirmDeposit: false` plus a `depositClaimedBy`); present but greyed for a reader without
  the grant («ليس لك» and «غير موجود» must not look alike); prints `أكّده …` once ticked; draws the
  red line when ticked against `paidAmount: '0.00'`. Copy the harness from
  `order_ready_message_test.dart`.
- **`order_status_icons_test.dart`** — the two new arms, and that no two statuses share a glyph.
- **`order_filter_sheet_test.dart`** — the two new rows.
- The three contract tests in §0 need **no** changes; they simply go green.

---

## 9. Checklist

- [x] `OrderStatus`: two cases, exact Arabic, declared after `shortage` — §2
- [x] `tone` and the chip's icon switch — §2 (an hourglass and banknotes, both new in `AppIcons`)
- [x] `AppPermission`: three cases — §3
- [x] `Order`: ten keys + `build_runner` — §4
- [x] Confirm the status screen draws both moves with no change — §5
- [x] `OrderEndpoints.depositReceipt`, repository method, use case, cubit method — §6
- [x] The deposit card, gated on `canConfirmDeposit`, with the reason under a greyed switch — §6
- [x] Widget tests — §8 (`order_deposit_card_test.dart`, ten cases)
- [x] `flutter analyze` clean, `flutter test` green (the three contract tests included)

---

## 10. What the build actually taught

**The card is drawn under the header, not beside the money.** «هل وصل العربون؟» is the question
that follows «ما حالتها؟», and the reader is already at the top of the screen when they ask it.
It is drawn on a عربون that is *money* — `deposit_expected_amount` present **and above zero**,
see `Order.asksForADeposit` — never on the status, and an order nobody asked a deposit of gets no
card at all, which is most of them. **Zero is the third state**: a طلبية whose discount swallowed
its invoice still walks the deposit road, because «عربون مدفوع» is the warehouse's own work list
and an order that cannot reach it is one nobody there ever sees — it parks with `0.00` written on
it, the server returns `can_confirm_deposit: false`, and a card headed «العربون 0» over a switch
that cannot be tapped would explain something that never happened. See ORDER-DEPOSIT.md §٤.

**`Order.hasNoRecordedPayment` parses, it does not compare.** The contradiction line needed «is
`paid_amount` zero», and `paidAmount != '0.00'` is one migration away from reading `'0.000'` as a
payment. A figure it cannot parse counts as *paid*, deliberately: the sentence it feeds is an
accusation, and the safer mistake is not making it.

**`claimedByMe` decides a sentence, never the switch.** The page computes it with
`Session.isSelf(depositClaimedBy.id)` and hands it to the card, which uses it only to choose
between «يؤكّد استلامَ العربون موظفٌ غير مَن نقل الطلبية» and «بانتظار التأكيد» under a locked
switch. What locks the switch is `canConfirmDeposit` and nothing else, exactly as §6 demands.

**Adding a required dependency to `OrderDetailCubit` touches ten test files.** Every one of them
builds the cubit by hand. Mechanical, but worth knowing before starting: `ConfirmDepositReceipt`
had to be threaded through all of them.

**And the filter sheet outgrew its ceiling.** Seventeen status chips no longer fit inside the 80%
of the screen `_FilterSheet` may take, so the sheet now opens at that ceiling and scrolls.
`order_filter_sheet_test`'s old claim — «as tall as its content, not a fraction of the phone» —
was proved by putting the sheet on a very tall screen and watching it come back *under* the
fraction; it had already been grown twice for the same reason. It cannot be grown again: every
dimension in the sheet is a ScreenUtil dimension, so the content is the same *fraction* of any
phone, and at 3200, 3600 and 4000 it comes back pinned at exactly 80%. The widget is unchanged
and still measures its content; the test now asserts what remains observable — it never exceeds
the ceiling, and the overflow scrolls rather than clips. **Raising the ceiling to 90% and
trimming the status list were both considered and rejected**: the first takes nine tenths of the
phone for a filter, and the second changes what the filter means, on a screen that is not this
feature's.
