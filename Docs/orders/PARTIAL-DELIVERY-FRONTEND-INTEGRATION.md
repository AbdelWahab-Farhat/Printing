# التسليم الجزئي — connecting the Flutter app

> How to wire `frontend/` up to the backend described in
> [PARTIAL-DELIVERY-DESIGN.md](PARTIAL-DELIVERY-DESIGN.md). Follows the recipe in
> [frontend/RULES.md §12](../../frontend/RULES.md) — this doc applies it to this feature rather
> than repeating the general rules.
>
> **The backend is merged and no app release is required to use the feature.** The form that
> records a partial delivery is built from server-described fields, so it already renders in
> every build that is out there. What the app cannot yet do is *show* what happened afterwards.
>
> **Two contract tests are red right now.** §1 is not optional and is not a feature — it is two
> enum entries and four JSON keys the suite already fails without. Everything from §3 on is what
> makes the feature legible.
>
> Written for whoever picks up the app side. Backend status: merged on `feat/partial-delivery`,
> 13 tests passing.
>
> ---
>
> **Done, on the same branch** — every item of §8 but the one that is a pair of eyes. The two
> red contract tests are green, the line card, the list badge and the report card are built, and
> 22 tests were written for them. §8 carries what was done and the one place this document sent
> the work somewhere it did not belong. **What is left is item 3**: nobody has looked at the
> delivery form on a real multi-line order, and nobody can — see §3 for the only question it
> asks.

---

## 0. What the feature is, in one paragraph

A customer at the counter takes **part** of an order — 300 of the 500 bags that were made — and
leaves the rest. On the way into «تم الاستلام» the person handing the parcel over is now asked,
per line, **«المُستلَم من …»**, pre-filled with the whole quantity so agreeing is one tap. What
they did not take comes off the invoice, and what happens to it depends on the line: **سادة**
goods go back on the shelf, **مطبوعة** and **وسيط** goods become a recorded loss, because nobody
else can buy bags carrying this customer's artwork. The order's own totals fall, the customer may
end up **overpaid** (already a solved state), and the loss shows up on the profit-and-loss report
in a new «الخسائر» section.

---

## 1. The changes that are already overdue

### 1.1 One permission

[lib/core/permissions/app_permission.dart](../../frontend/lib/core/permissions/app_permission.dart)
— `permission_contract_test.dart` reads `PermissionName.php` case for case and is red until this
lands, **in the position PHP declares it**: immediately after `markOrdersDelivered`.

```dart
  markOrdersDelivered('orders.status.delivered', 'تأكيد استلام العميل للطلبية'),

  /// Recording that the customer took only part of the order — which shrinks the invoice.
  ///
  /// Its own grant rather than a ride on [markOrdersDelivered], and not out of distrust:
  /// folding it in would have widened a permission everybody already holds, silently, and
  /// welded the two together so that stopping one person shrinking invoices meant stopping them
  /// marking anything delivered. It is granted to the delivery roles on day one — see the
  /// migration — so in practice the same people do the same work.
  ///
  /// **The app never checks this.** The server withholds the *fields* from anybody lacking it,
  /// so a screen that renders what it is handed is correct either way. It is here because the
  /// roles screen lists every permission by name.
  recordPartialDelivery('orders.partial_delivery', 'تسجيل تسليم جزئي — يُنقص الفاتورة'),

  settleOrders('orders.status.settled', 'تسوية مبلغ الطلبية'),
```

### 1.2 Five JSON keys

`order_resource_contract_test.dart` reads the **generated** parsers against every key the PHP
resources publish. Four on the line, one on the order.

[lib/features/orders/models/order.dart](../../frontend/lib/features/orders/models/order.dart) —
in `OrderItem`, beside `shortageQuantity`:

```dart
    @JsonKey(name: 'shortage_quantity') String? shortageQuantity,

    /// What the customer left on the counter, in this line's own unit. Null on every line of
    /// every order delivered whole, which is nearly all of them — «nothing recorded» rather
    /// than «nothing left», the distinction [shortageQuantity] already makes.
    @JsonKey(name: 'undelivered_quantity') String? undeliveredQuantity,

    /// What became of it: `restocked` or `written_off`. Read off the line rather than worked
    /// out from the product's heading — re-filing a product must not rewrite a delivery
    /// recorded last March.
    @JsonKey(name: 'undelivered_disposition') String? undeliveredDisposition,

    /// The same thing in Arabic, ready to print — «أُعيد إلى المخزن» or «خسارة». Sent beside
    /// the value for the reason `pricingUnitLabel` is: the app branches on one and shows the
    /// other, and never owns the dictionary.
    @JsonKey(name: 'undelivered_disposition_label') String? undeliveredDispositionLabel,

    /// What the goods left behind cost us — **null unless they were a loss**. Bags back on the
    /// shelf cost the shop nothing, so a restocked line has no figure here at all.
    @JsonKey(name: 'delivery_loss') String? deliveryLoss,
```

…and in `Order`, beside the other derived flags:

```dart
    /// Whether the customer left part of this order behind. Derived on the server from the
    /// lines, which the list already loads, so it costs nothing and arrives on **both** the
    /// list and the detail payloads.
    @JsonKey(name: 'is_partially_delivered') bool? isPartiallyDelivered,
```

Then `dart run build_runner build --delete-conflicting-outputs`.

> **`billable_quantity` has not changed shape, but it has changed meaning.** It was
> `quantity − shortage`; it is now `quantity − shortage − undelivered`. Anything in the app that
> re-derives it locally is now wrong. `OrderItem.pricedQuantity` already reads the server's value
> and is fine; `OrderItem.hasShortage` and the line at
> [order.dart:733](../../frontend/lib/features/orders/models/order.dart#L733) that parses
> `shortageQuantity` by hand are about the shortage only and stay as they are.

---

## 2. Endpoints

**No new endpoints, and no new request shape.** Everything travels on calls the app already
makes:

| Call | What is new |
|---|---|
| `GET /orders` | `is_partially_delivered` on each row |
| `GET /orders/{id}` | the same, plus the four line keys, plus the new fields inside `available_transitions[].fields` |
| `POST /orders/{id}/status` | `fields.delivered_{itemId}` and `fields.returned_{itemId}` — **rendered from the server's description, so nothing to write** |
| `GET /reports/profit-loss` | a `losses` object |

---

## 3. The form — already done, and worth checking rather than building

The move into «تم الاستلام» now describes extra fields, and
[transition_field_input.dart](../../frontend/lib/features/orders/presentation/widgets/transition_field_input.dart)
already draws them: they are `number` fields, a kind the app has had since «نواقص».

What arrives, per line the customer could still take something from:

```jsonc
{
  "key": "delivered_42",
  "type": "number",
  "label": "المُستلَم من 25*35 (قطعة)",
  "required": false,
  "max": 300,
  "value": "300.000",                       // pre-filled: agreeing is one tap
  "hint": "من أصل 300.000 — وما لا يأخذه يُخصم من الفاتورة ويعود إلى المخزن"
}
```

…and, **only** on a سادة line whose selling unit differs from the shelf's:

```jsonc
{
  "key": "returned_42",
  "type": "number",
  "label": "المُعاد إلى المخزن من 25*35 (كيلوغرام)",
  "required": false,
  "max": 12.5,
  "hint": "خرج من المخزن 12.500 كيلوغرام — صحّح المُعاد إن وزنته"
}
```

**The only job here is to look at it on a real order and confirm it reads well.** A five-line
order now draws five boxes on that screen; if that is too long, the fix is a server-side one
(§7), not a Dart one.

**Do not add a local check for `recordPartialDelivery`.** The server omits the fields entirely
for anybody without the grant, exactly as it already does for the money box. A second opinion in
Dart is the thing that goes out of step.

---

## 4. The order screen — «غير مُستلَم» on the line

[order_item_card.dart](../../frontend/lib/features/orders/presentation/widgets/order_item_card.dart)
already prints the shortage on the line it belongs to, at
[:257](../../frontend/lib/features/orders/presentation/widgets/order_item_card.dart#L257). The
same treatment, directly underneath, because the two are the same kind of fact — a quantity that
is not being charged for — and a person reading the line wants them together:

```dart
        if (item.hasShortage) ...[ /* … unchanged … */ ],

        // Under the shortage, because both answer «why is this line charging less than it
        // ordered?» and they can both be true at once: an order short fifty, whose customer
        // then took only three hundred of the four hundred and fifty that existed.
        if (item.wasPartlyLeftBehind) ...[
          SizedBox(height: 4.h),
          Text(
            'غير مُستلَم: ${item.undeliveredQuantity!.grouped} ${item.pricingUnitLabel} '
            '— ${item.undeliveredDispositionLabel}',
            style: context.textTheme.bodySmall?.copyWith(
              // Deliberately *not* `error` like the shortage above. A shortage is our failure;
              // this is the customer's choice, recorded. Same weight, calmer colour.
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
```

…with the getter beside `hasShortage` in `OrderItem`:

```dart
  /// Whether the customer left any of this line behind. Parsed rather than compared to null,
  /// for the reason [hasShortage] is: a recorded zero is «took it all», not «left nothing».
  bool get wasPartlyLeftBehind => (double.tryParse(undeliveredQuantity ?? '') ?? 0) > 0;
```

**The loss figure goes with the other costs, not here.** `deliveryLoss` is money, and money on a
line is already gathered in
[order_line_costs.dart](../../frontend/lib/features/orders/presentation/widgets/order_line_costs.dart)
behind the same permission the rest of the costs sit behind. Putting «خسارة ٤٠٠» beside a
quantity on a card a salesperson reads would be the only cost figure on that card.

---

## 5. The orders list — a chip

This was asked for explicitly (Decision 7), and the server flag is on the list payload, so it is
a chip and nothing more. In
[order_card.dart](../../frontend/lib/features/orders/presentation/widgets/order_card.dart),
beside the urgency and payment chips that are already there:

```dart
if (order.isPartiallyDelivered ?? false)
  const _Chip(label: 'تسليم جزئي', tone: _Tone.neutral),
```

**Neutral, not a warning.** It is a fact about a finished order, not something anybody must act
on — an order that was partly collected and paid for correctly is not a problem. Match whatever
the existing chips do rather than inventing a tone.

**No filter.** It was the option that was not chosen; the P&L section in §6 answers «كم يكلّفنا
هذا؟», which is what a filter would mostly be used for.

---

## 6. The profit-and-loss report — a new section

The server now sends:

```jsonc
"losses": {
  "scrap": "120.00",              // bags spoiled on the press
  "partial_delivery": "400.00",   // made, counted, and left on the counter
  "total": "520.00"
}
```

[profit_and_loss_summary.dart](../../frontend/lib/features/reports/models/profit_and_loss_summary.dart):

```dart
    @JsonKey(name: 'gross_profit') required String grossProfit,

    /// Goods this business made and never sold. **Reported, never subtracted** — both figures
    /// are already inside [grossProfit] by construction, so showing them as a deduction would
    /// tell the same story twice and make the arithmetic on screen fail to add up.
    ///
    /// Nullable so an app talking to a server older than this feature still parses.
    PnlLosses? losses,
```

```dart
@freezed
abstract class PnlLosses with _$PnlLosses {
  const factory PnlLosses({
    /// تلف — spoiled during production.
    required String scrap,

    /// ما لم يستلمه العميل — made, counted, refused.
    @JsonKey(name: 'partial_delivery') required String partialDelivery,
    required String total,
  }) = _PnlLosses;

  factory PnlLosses.fromJson(Map<String, dynamic> json) => _$PnlLossesFromJson(json);
}
```

On [profit_and_loss_page.dart](../../frontend/lib/features/reports/presentation/views/profit_and_loss_page.dart),
**below** gross profit, in its own card headed «الخسائر»:

- «خسارة تلف» — scrap
- «خسارة تسليم جزئي» — partial delivery
- «الإجمالي» — total

**The card must not look like part of the subtraction above it.** Gross profit is
`revenue − COGS` and the losses are already inside it; a reader who subtracts this card from that
number will be wrong by exactly this amount. A line of caption text under the heading —
«محتسبة ضمن الربح أعلاه» — is worth the two lines it costs.

> **While you are in this file:** `write_offs` has been on this endpoint since the write-off
> feature shipped and the app has never read it. Not this feature's to fix, but it belongs on the
> same card and it is three lines.

---

## 7. What the backend still owes, if the screen asks for it

Nothing is missing for correctness. Two things would be server-side changes if the app side finds
them wanting, and both are listed here so nobody solves them in Dart:

1. **A long form.** A ten-line order draws ten boxes on the status screen. If that is too much,
   the server can collapse it — one «استلم الكل؟» switch that hides the per-line boxes — and that
   belongs in `TransitionFields`, where the form is described.
2. **The money box's ceiling.** On «تم الاستلام» the payment field's `max` is built before the
   clerk types anything, so it still reflects the *pre-partial* remainder. The write itself is
   ordered correctly — the invoice shrinks before the payment is recorded — so the money lands
   against the corrected total and an overpayment falls out into `RefundOrderPayment`, which is
   an already-handled state. If staff find that confusing, the fix is a hint or a second
   round-trip, decided on the server.

---

## 8. Checklist

| # | | Where | |
|---|---|---|---|
| 1 | `recordPartialDelivery` in `AppPermission` | §1.1 | ✅ |
| 2 | Four keys on `OrderItem`, one on `Order`, then build_runner | §1.2 | ✅ |
| 3 | Look at the delivery form on a real multi-line order | §3 | ⬜ **the only one left** |
| 4 | «غير مُستلَم» under the shortage on the line card | §4 | ✅ |
| 5 | `deliveryLoss` into `OrderLineCosts`, behind the existing cost permission | §4 | ✅ |
| 6 | «تسليم جزئي» chip on the order card | §5 | ✅ |
| 7 | `PnlLosses` model + «الخسائر» card | §6 | ✅ |
| 8 | `write_offs` — **beside النقد المحصَّل, not on the losses card** | below | ✅ |

Items 1 and 2 were the release; the rest followed on the same branch.

**Item 8 was moved, and the instruction above it was wrong.** This document said `write_offs`
«belongs on the same card». It does not. A write-off forgives a *receivable* — nothing was made
and nothing was spoiled — and this statement recognises revenue on delivery and carries no
expense side at all, so there is nowhere in the arithmetic above to hang a bad debt.
`ProfitAndLossSummaryQuery` says exactly this in its own comment and publishes the key beside
`cash_collected` rather than inside `losses`. Putting it under «الخسائر» would have sat it under
that card's own caption — «محتسبة ضمن الربح أعلاه» — and made the sentence false. It is drawn in
`_CashCollected`, under the break in the page, with a line of its own saying it is not taken off
the profit above. `profit_and_loss_write_offs_test.dart` asserts the position, so the move cannot
be undone by accident.

**And what item 3 is actually asking.** The mechanism is proved: the server sends `number` fields
carrying `max`, `hint` and `value`; `OrderStatusCubit._prefilled` seeds `field.value`; both are
covered by tests that already existed. What no test can answer is whether five boxes on one
status screen read well to somebody standing at a counter. If they do not, §7.1 is the fix and it
is a server-side one.
