# Additional cost on an order — connecting the Flutter app

> **Status: not started.** The backend is built and green (see
> [ORDER-ADDITIONAL-COST-BACKEND-CHANGES.md](ORDER-ADDITIONAL-COST-BACKEND-CHANGES.md)); nothing
> in `frontend/` has been touched. This doc is the plan for wiring the app up, written against
> the shipped API.

---

## 0. Where the app stands today, and the one thing that is already broken

The app has no notion of an additional cost. `Order` does not parse the four new keys, `NewOrder`
does not send the three new ones, and neither form has a control for them.

**Nothing is broken at runtime by that** — the API's new request fields are all optional, and
`json_serializable` ignores response keys it was not told about. An order carrying a charge will
open, pay, settle and print correctly; the total is already right, because `grand_total` is the
server's arithmetic and this app never re-derives it. What the clerk will not see is *why* the
total is what it is: the charge is silently inside «الإجمالي» with no line naming it.

**One test does fail, and it is the one designed to.**
`test/features/orders/order_resource_contract_test.dart` compares every key
`OrderResource` publishes against every key the generated `fromJson` parsers read, and fails when
the server publishes something the app drops. It will now name four:

```
additional_cost, additional_cost_reason, additional_cost_reason_label, additional_cost_note
```

That is the guard doing its job — «the failure that has no symptom», in its own words. It goes
green with §2 below and needs no change of its own.

---

## 1. What the server expects and returns

**Request** — `POST /api/v1/orders`, `PUT /api/v1/orders/{order}`. Three optional fields beside
`discount`:

```jsonc
{
  "additional_cost": "10.00",
  "additional_cost_reason": "special_packaging",
  "additional_cost_note": "علبة كرتون مزدوجة"
}
```

| Field | Rule |
|---|---|
| `additional_cost` | optional, numeric, `>= 0`. **ASCII digits** — `'١٠'` is refused |
| `additional_cost_reason` | one of five codes; **required once the amount is above zero** |
| `additional_cost_note` | optional, ≤ 500 chars; **required when the reason is `other`** |

The five codes, with the Arabic the server labels them with:

| Code | Label |
|---|---|
| `special_packaging` | تغليف خاص |
| `extra_service` | خدمة إضافية |
| `modification` | تعديل |
| `transport` | نقل |
| `other` | أخرى |

**Response** — four keys beside `discount`:

```jsonc
{
  "additional_cost": "10.00",
  "additional_cost_reason": "special_packaging",
  "additional_cost_reason_label": "تغليف خاص",
  "additional_cost_note": "علبة كرتون مزدوجة",
  "grand_total": "130.00"
}
```

`additional_cost` is always present (`"0.00"` when nothing is charged); the other three are null
on an order with no charge.

**Refusals:** `403` when the signed-in user lacks `orders.additional_cost`; `422` with
`errors.additional_cost`, `errors.additional_cost_reason` or `errors.additional_cost_note`.

**`PUT` replaces the whole order.** The existing `updateInvoice` already re-sends `city_id`,
`design_fee` and `discount` for exactly this reason; the three new fields must join that list, or
an address correction will clear the charge off the order.

---

## 2. Models

**`lib/features/orders/models/additional_cost_reason.dart` (new)** — the mirror enum, shaped like
`OrderStatus`: a `wire`, a `label`, an `unknown` case with no counterpart in the PHP, a `choices`
list excluding it, and a `needsNote` getter true for `other` alone.

Why an enum here at all, when a single order carries its own `..._label`: the **take-order form**
has to draw five chips before anything has been saved, so it needs the list and the Arabic with
no order in hand. That is the same reason `OrderStatus.label` exists for the filter sheet.

**`order.dart`** — four fields:

```dart
@JsonKey(name: 'additional_cost') @Default('0.00') String additionalCost,
@JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown)
AdditionalCostReason? additionalCostReason,
@JsonKey(name: 'additional_cost_reason_label') String? additionalCostReasonLabel,
@JsonKey(name: 'additional_cost_note') String? additionalCostNote,
```

`@Default('0.00')` for the reason `paidAmount` has one: an order from a server that predates this
was never charged, and zero is exactly what such a server means. `unknownEnumValue` so a reason
added to the backend after a build ships does not fail the whole order — it still shows the
label the server sent.

Plus two getters, and **the caption belongs here and nowhere else**:

```dart
bool get hasAdditionalCost => additionalCost != '0.00';

/// «تغليف خاص — علبة كرتون مزدوجة», or the note alone under «أخرى», or null.
String? get additionalCostCaption;
```

Three surfaces show this line — the order screen, the PDF and the WhatsApp message. Each one
deciding for itself how a label and a note go together is how «تغليف خاص» ends up on the invoice
and «علبة كرتون مزدوجة» in the message for the same order.

Under «أخرى» the caption is the note, not the label: the word names no category to a customer,
and the server guarantees a note is there.

**`new_order.dart`** — three fields, all `includeIfNull: false`, keyed
`additional_cost` / `additional_cost_reason` / `additional_cost_note`.

Then `dart run build_runner build --delete-conflicting-outputs`.

---

## 3. Use cases and repository

**`take_order.dart`** — three parameters, and one rule that must not live in a widget: **an
amount of nothing takes its reason with it.** The chips can be tapped before the box is filled,
and a reason on its own would be a category for money nobody is charging — which the server
would then refuse.

```dart
final charge = _number(additionalCost);            // Arabic-Indic → ASCII, '' → null
final isCharging = charge != null && (double.tryParse(charge) ?? 0) > 0;
// ...
additionalCost: isCharging ? charge : null,
additionalCostReason: isCharging ? additionalCostReason?.wire : null,
additionalCostNote: isCharging ? _text(additionalCostNote) : null,
```

The existing `_number` already handles «٣٠٠» and the comma decimal separator; the charge goes
through it like every other numeric field on the form.

**`order_repository.dart` / `_impl.dart` / `update_order_invoice.dart`** — three optional
parameters on `updateInvoice`, echoed back from the order when absent:

```dart
'additional_cost': additionalCost ?? order.additionalCost,
'additional_cost_reason': ?(additionalCost == null
    ? order.additionalCostReason?.wire
    : additionalCostReason?.wire),
'additional_cost_note': ?(additionalCost == null ? order.additionalCostNote : additionalCostNote),
```

The reason must travel with the amount in both directions — sending an amount without one is a
422, and sending the amount back unchanged without its reason is the same 422 on an edit that
was only about the address.

---

## 4. The two forms

**`new_order_page.dart`** — a «التكلفة الإضافية» section after «الخصم», behind
`sl<Session>().can(AppPermission.addOrderAdditionalCost)` (a new case on `AppPermission`;
`permission_contract_test.dart` will fail until it is added, which is the point of it).

Three controls: the amount, a `Wrap` of five `ChoiceChip`s, and the note. **Chips, not a
`SegmentedButton`** — unlike «مصدر التصميم» above it, five Arabic labels do not fit one row at
430 wide, and a segment squeezed to three characters names nothing. Tapping the selected chip
again clears it, so a reason picked by mistake on an order that is not being charged can be
removed. The note's label switches to «السبب» (from «السبب (اختياري)») under «أخرى».

A clerk without the grant sends **no key at all**, exactly as with the discount: the hidden field
is the suggestion, the 403 is the rule.

**`order_edit_page.dart`** — the same three controls in an `_AdditionalCostField` shaped like the
existing `_DiscountField`, shown under `mayAddCost && mayEditItems`. The second condition is the
discount's: past «جاهزة» that sheet is open for the address alone.

**`order_invoice_cubit.dart` / `_state.dart`** — three fields seeded from the order, three
setters, and two things worth getting right:

- `estimatedTotal` adds the charge **before** subtracting the discount, the order the server
  works in.
- `isValid` gains `additionalCostIsValid` — a reason is required once there is an amount, and
  «أخرى» needs words. The server's own two rules, checked locally so the refusal is instant
  rather than a 422 about a field the clerk thought they had filled in.
- `setAdditionalCostReason` must **not** clear the note. Somebody correcting «تعديل» to «خدمة
  إضافية» has not stopped meaning the sentence they typed underneath.

**`take_order_state.dart`** — `additionalCostError`, `additionalCostReasonError` and
`additionalCostNoteError`, and all three keys added to `_renderedKey`, so each complaint is
painted under its own control instead of shouted in a snackbar.

---

## 5. The three places it is shown

| Surface | Where |
|---|---|
| `order_totals.dart` | A line **before** «الخصم» — `+ 10.00` — with `additionalCostCaption` as a small second line under the label. Hidden when zero, like the fee lines |
| `order_invoice_pdf.dart` | A totals line before «الخصم», **without** the danger colour: this is a charge, not a deduction, and red beside a figure the customer owes warns about the wrong thing |
| `order_message.dart` | A line between «التوصيل» and «الخصم» — «التكلفة الإضافية (تغليف خاص): ١٠٫٠٠» |

**The charge is named on the customer's copy, unlike delivery.** «التوصيل» is off the invoice by
the owner's instruction; this is not the same case. A charge the customer is being asked to pay
and cannot see a name for is the line that gets telephoned about.

The order screen's «الحساب» section needs nothing else — «الإجمالي», «المدفوع» and «المتبقي» are
the server's numbers and already include the charge.

---

## 6. Tests to add

- **`additional_cost_reason_contract_test.dart` (new)** — reads
  `backend/app/Domain/Order/Enums/AdditionalCostReason.php` and pins the codes, the Arabic, and
  which reason needs a note; skips when the backend is not checked out beside the app. The same
  arrangement as `order_status_contract_test.dart`, and it matters more here: a chip posting
  `packaging` where the server says `special_packaging` is a 422 about a field the clerk did fill
  in.
- `take_order_cubit_test` / `new_order_page_test` — the section is hidden without the grant and
  no key is sent; a reason with no amount sends neither.
- `order_invoice_cubit_test` — the running estimate, and `isValid` false for an amount with no
  reason and for «أخرى» with no words.
- A file for `additionalCostCaption`'s four cases (label only, label + note, «أخرى» + note, none).
- `order_message_test`, `order_invoice_pdf_test`, and a widget test for `OrderTotals`.

`order_resource_contract_test.dart` and `permission_contract_test.dart` need no changes — they
are the two guards that will tell you when this work is complete.

---

## 7. Checklist

- [ ] `AppPermission.addOrderAdditionalCost`
- [ ] `additional_cost_reason.dart` + its contract test
- [ ] `Order` — four fields, `hasAdditionalCost`, `additionalCostCaption`
- [ ] `NewOrder` — three fields
- [ ] `build_runner`
- [ ] `TakeOrder` — the amount-carries-the-reason rule
- [ ] `OrderRepository` / `_impl` / `UpdateOrderInvoice` — echo the charge back on `PUT`
- [ ] `TakeOrderCubit` + `TakeOrderState` — three field errors, `_renderedKey`
- [ ] `NewOrderPage` — the section, behind the grant
- [ ] `OrderInvoiceCubit` + state — setters, `estimatedTotal`, `additionalCostIsValid`
- [ ] `OrderEditPage` — `_AdditionalCostField`
- [ ] `OrderTotals`, `order_invoice_pdf.dart`, `order_message.dart`
- [ ] `flutter analyze` clean, `flutter test` green

> **Note on the current tree:** `flutter analyze` already reports one pre-existing error —
> `order_status_chip.dart:64`, a switch not covering `OrderStatus.readyToPrint`, left by the
> `ready_to_print` status work. It is unrelated to this feature but will need fixing before the
> analyzer is clean.
