# Undoing a receipt — connecting the Flutter app

> **Status: planned, not built.** The backend shipped on branch `purchaseOrder_reversal` — see
> [PURCHASE-ORDER-RECEIPT-REVERSAL.md](PURCHASE-ORDER-RECEIPT-REVERSAL.md). Nothing in
> `frontend/lib/features/purchase_orders/` knows about it yet. This document is the plan for
> wiring it up; where it and the shipped code eventually disagree, the code is right.

---

## 0. Where the app stands today

`purchase_order_detail_page.dart` already has everything this needs except the act itself:

- an `AppSpeedDial` of `AppAction`s, each carrying its own `permission:`, so a button that a
  caller may not press is not drawn (`_receive` is the model to copy — first in the list, behind
  `AppPermission.manageInventory`);
- `showReceiveArrivalSheet()` as the pattern for a modal that collects something and returns it
  or null;
- `PurchaseOrderDetailCubit._write()`, which wraps a repository call and refreshes the order.

So this is one endpoint constant, two model fields, one repository method, one usecase, one cubit
method and one confirmation sheet. No new screen.

**One existing comment becomes wrong** and must be corrected in the same change:
`PurchaseOrderStatus.isFinal` in `models/purchase_order.dart` says *«Nothing follows, and nothing
reopens it.»* A completed order can now be reopened — not by a transition, but by undoing the
receipt underneath it. `isFinal` itself stays exactly as it is; only the sentence changes.

**`offeredNext` must *not* gain anything.** Reversal is not a status a person picks — it is a
correction to the ledger that happens to reopen the paperwork. It belongs in the speed dial
beside «تسجيل شحنة», never in the status picker.

---

## 1. What the server sends and expects

### Reading — `GET /purchase-orders/{id}`

Two new fields, **on the detail endpoint only**. The list does not carry them, so
`purchase_order_card.dart` must not reach for them.

```jsonc
{
  "id": 412,
  "status": "completed",
  "receipt_reversible_until": "2026-09-10T10:00:00+00:00", // or null
  "can_reverse_receipt": true                              // computed for THIS caller
}
```

| Field | Meaning |
|---|---|
| `receipt_reversible_until` | when the ordinary 24-hour window closes. `null` when the order has no live receipt behind it (anything not `completed`, or a receipt already undone) |
| `can_reverse_receipt` | whether **this** caller may undo it right now — the window, or the grant that waives it |

`can_reverse_receipt` is computed per caller, so the same order answers `false` to a storekeeper
on day three and `true` to a manager holding `purchase_orders.reverse_receipt_any_time`. Read it;
never re-derive it from the deadline in the app, or the two will disagree the day the window
changes.

### Writing — `POST /purchase-orders/{id}/receipt-reversal`

```jsonc
{ "reason": "سُجّلت الكمية خطأً — ٥٠٠ بدل ٥٠" }
```

`reason` is **required**, 3–500 characters. Returns the reopened order as the usual
`PurchaseOrderResource` (`200`), with `status` back to `arrived` and every line's
`quantity_received` back down — so the response can be fed straight into the detail state, exactly
as `changeStatus` already does.

Guarded by `inventory.manage`, **not** `purchase_orders.manage` — the same split
`POST .../arrivals` already follows, and for the same reason.

### The refusals

All 422 with the envelope's Arabic `message`. **Surface it; do not translate or re-word it in the
app** — each one names a different problem and tells the person what to do instead.

| When | The message says |
|---|---|
| Past 24h, no override | «انتهت مهلة التراجع… الصواب تسوية جرد، أو تراجع بصلاحية المدير» |
| Some of the stock already drawn on | «صُرف من الدفعة… الصواب تسوية جرد لا إلغاء استلام» |
| A layer repriced by hand | «عُدِّلت تكلفة الدفعة… يدوياً بعد استلامها» |
| Already undone | «تم التراجع عن الشحنة… من قبل» |
| No receipt to undo | «لا يوجد استلام يمكن التراجع عنه…» |

---

## 2. Model changes

**`features/purchase_orders/models/purchase_order.dart`** — two fields on `PurchaseOrder`:

```dart
@JsonKey(name: 'receipt_reversible_until') DateTime? receiptReversibleUntil,
@JsonKey(name: 'can_reverse_receipt') @Default(false) bool canReverseReceipt,
```

Both **must default safely**, because the list endpoint omits them: a missing
`can_reverse_receipt` has to read as `false`, never as "unknown, so show the button". Then
`build_runner` for the `.freezed.dart` / `.g.dart` pair.

**`features/vendors/models/stock_arrival.dart`** — for the shipments screen:

```dart
@JsonKey(name: 'reversed_at') DateTime? reversedAt,
@JsonKey(name: 'reversal_reason') String? reversalReason,
```

A getter beside them — `bool get isReversed => reversedAt != null` — so no screen tests the
timestamp itself.

---

## 3. Endpoint

`core/network/api_endpoints.dart`, beside `arrivals()`:

```dart
/// Undoing a receipt entered in error. Guarded by `inventory.manage`, like `arrivals()` —
/// it takes stock back off the shelf. `purchase_orders.reverse_receipt_any_time` does not
/// open this door; it only waives the 24-hour window once inside.
static String receiptReversal(int purchaseOrderId) =>
    '/purchase-orders/$purchaseOrderId/receipt-reversal';
```

---

## 4. Permission

`core/permissions/app_permission.dart`, in the purchase-orders block:

```dart
reverseReceiptAnyTime(
  'purchase_orders.reverse_receipt_any_time',
  'التراجع عن استلام شحنة بعد انتهاء مهلة الـ٢٤ ساعة',
),
```

Added so the permissions screen can grant it. **The button is not gated on it** — see §6.

---

## 5. Repository, usecase, cubit

Repository (`purchase_order_repository.dart` + `_impl.dart`), the same shape `changeStatus` has —
it returns a `PurchaseOrder`, so the detail state is replaced rather than re-fetched:

```dart
Future<Either<Failure, PurchaseOrder>> reverseReceipt(
  int purchaseOrderId, {
  required String reason,
});
```

A `ReverseReceipt` usecase in `purchase_order_usecases.dart` alongside `ReceiveArrival`, and on
`PurchaseOrderDetailCubit`:

```dart
Future<Failure?> reverseReceipt({required String reason}) =>
    _write(() => _reverseReceipt(orderId, reason: reason));
```

---

## 6. The button

In `_PurchaseOrderActions`, immediately after «تسجيل شحنة»:

```dart
// **Gated on the server's answer, not on a status test.** Whether a receipt may still be
// undone depends on the clock and on who is asking, and only the server knows both — see
// `can_reverse_receipt`. `manageInventory` is the grant that opens the endpoint;
// `reverseReceiptAnyTime` is not tested here, because it does not open the door, it only
// waives the window the server has already accounted for in the flag.
if (order.canReverseReceipt)
  AppAction(
    label: 'التراجع عن الاستلام',
    icon: AppIcons.undo,
    tone: AppActionTone.warning,
    permission: AppPermission.manageInventory,
    onTap: onReverseReceipt,
  ),
```

**Do not add `order.status == completed`.** The server already folds that into the flag, and two
conditions over one fact are two things to keep in step.

**Do not try to hide the button when the stock has been drawn on.** The API deliberately does not
publish that — answering it would mean reading every line's cost layers — so the button can be
offered on a receipt that turns out to be un-reversible. That is the intended failure: a clear
refusal naming the reason. Silently hiding the button on a receipt that *is* reversible would be
the worse bug.

### Showing the deadline

Beside «مكتمل» on the detail header, when `receiptReversibleUntil` is in the future:

> «يمكن التراجع عن الاستلام حتى ١٠:٠٠ ٧ سبتمبر»

Coarse wording is fine — this is a deadline someone acts on within a day, not a countdown. When
it has passed and `canReverseReceipt` is still `true`, the caller holds the override; the line can
say «انتهت المهلة — لديك صلاحية التراجع» so nobody is surprised by a button they did not expect.

---

## 7. The confirmation sheet

`reverse_receipt_sheet.dart`, modelled on `receive_arrival_sheet.dart` — returns the reason, or
null:

```dart
Future<String?> showReverseReceiptSheet({
  required BuildContext context,
  required PurchaseOrder order,
});
```

It must carry three things:

1. **What will happen, in plain words** — «سيُسحب ما استُلم من الرف، ويعود الأمر إلى «قيد
   الاستلام» ليُسجَّل الاستلام من جديد». This takes real stock off a real shelf; a bare «هل أنت
   متأكد؟» is not enough.
2. **A required reason field**, validated client-side at 3–500 characters so the person is not
   told by the server what a text box could have told them. Free text, not a picker: the useful
   reasons are the ones nobody predicted.
3. **A `warning`-toned confirm button** — the tone this app gives to «takes something away»,
   the same one «إلغاء الأمر» carries — and the sheet dismissed only on success.

On failure, show the server's `message` in the sheet rather than a snackbar behind it — the person
is mid-decision and the message often tells them to do something else instead (a stocktake
adjustment).

---

## 8. The shipments screen

Where `StockArrival` is listed or shown, a reversed one is **kept and marked**, never hidden — the
document is real history, and hiding it makes a shipment somebody remembers posting look like it
never happened:

> «مُلغى — سُجّلت الكمية خطأً» ·  struck-through quantities, muted tone.

---

## 9. Checklist

- [ ] `PurchaseOrder`: `receiptReversibleUntil`, `canReverseReceipt` (defaulting to `false`), rebuild freezed
- [ ] `StockArrival`: `reversedAt`, `reversalReason`, `isReversed`
- [ ] Correct the «nothing reopens it» sentence on `PurchaseOrderStatus.isFinal`; leave `offeredNext` alone
- [ ] `PurchaseOrderEndpoints.receiptReversal()`
- [ ] `AppPermission.reverseReceiptAnyTime`
- [ ] Repository + usecase + `PurchaseOrderDetailCubit.reverseReceipt()`
- [ ] `showReverseReceiptSheet()` with a required reason
- [ ] The speed-dial action, gated on `canReverseReceipt`
- [ ] The deadline line on the detail header
- [ ] Reversed arrivals marked on the shipments screen
- [ ] Cubit test: success replaces the order and refreshes; a 422 surfaces the server's message and keeps the sheet open
