# Nawris — connecting the Flutter app

> How to wire `frontend/` up to the carrier integration described in
> [NAWRIS-INTEGRATION.md](NAWRIS-INTEGRATION.md) and built as recorded in
> [NAWRIS-CHANGES.md](NAWRIS-CHANGES.md). Follows the recipe in
> [frontend/RULES.md §12](../../frontend/RULES.md) — this doc applies it to this feature rather
> than repeating the general rules.

---

## 0. Before you start — the one thing that will confuse you

**Most of this feature is not a screen. It is two queues and a number.**

The carrier moves orders on its own, through a webhook, with no user involved. The app's job is
therefore not to *drive* the integration — it is to make visible the three things that go wrong
quietly:

1. A webhook arrived and was never processed → the order silently stopped moving.
2. An order went out for delivery and was never lodged → Nawris has never heard of it.
3. A delivery arrived under a parcel code we did not expect → a human has to decide.

If you build only the order-detail additions in §4 and skip §6, the integration still works and
its failures are invisible. **§6 is the part that earns its keep.**

---

## 1. What changed in responses you already parse

### `OrderResource` — one new field

```jsonc
{
  "paid_amount": "100.00",
  "written_off_amount": "0.00",
  "carrier_settled_amount": "20.00",   // ← NEW
  "remaining_amount": "0.00",
  "payment_status": "paid"
}
```

**Add it to your `Order` model and show it**, because without it the payments card becomes
arithmetic that does not add up: an order of 120 showing 100 paid and nothing outstanding reads as
a bug. It is money the customer paid **to the courier** for delivery, not to us.

> ⚠️ Do **not** add it to a "cash collected" total anywhere. It never reached the drawer. That is
> the whole reason it is a separate column rather than part of `paid_amount`.

Suggested label: «سُدِّدت لدى الناقل».

### `CityResource` / `RegionResource` — one new field each

```jsonc
{ "nawris_government_id": "5" }     // city
{ "nawris_area_id": "204" }         // region
```

Both nullable, both free text, both admin-only in practice. A city with `null` is simply not a
Nawris destination — that is normal, not an error state. Show them as plain text fields on the
city/region form, beside `darb_branch`, which is the same kind of column for a different carrier.

---

## 2. Endpoints

Add to [api_endpoints.dart](../../frontend/lib/core/network/api_endpoints.dart):

```dart
/// شحنات نورس — the carrier integration's operations surface.
///
/// There is no "create a shipment" endpoint here on purpose: dispatch happens as a side effect
/// of moving an order to «جاري التوصيل», through the status endpoint the app already calls.
abstract final class CarrierEndpoints {
  static const String events = '/carrier/events';
  static const String parcels = '/carrier/parcels';
  static const String notLodged = '/carrier/not-lodged';

  static String lodge(int orderId) => '/carrier/orders/$orderId/lodge';

  static String cancelShipment(int orderId) => '/carrier/orders/$orderId/cancel-shipment';

  static String resolveConflict(int parcelId) => '/carrier/parcels/$parcelId/resolve-conflict';
}
```

| Verb | Path | Permission | Cubit action |
|---|---|---|---|
| `GET` | `events` | `carrier.view` | list; `?pending=1`, `?unmatched=1` |
| `GET` | `parcels` | `carrier.view` | list; `?open=1`, `?conflict=1` |
| `GET` | `notLodged` | `carrier.view` | list of orders |
| `POST` | `lodge(id)` | `carrier.manage` | retry — returns a parcel |
| `POST` | `cancelShipment(id)` | `carrier.manage` | **does not cancel the order** — see §5 |
| `POST` | `resolveConflict(id)` | `carrier.manage` | returns the parcel |

All paginated lists use the envelope's standard `meta`, so the existing pagination helper works
unchanged.

---

## 3. Two new permissions

```dart
static const String carrierView = 'carrier.view';
static const String carrierManage = 'carrier.manage';
```

**Gate them separately.** Seeing that a parcel is stuck is not the same authority as declaring a
delivery conflict resolved — the server enforces the split and the UI should read the same way.
`carrier.manage` gates exactly three buttons: lodge, cancel shipment, resolve conflict.

---

## 4. The order screen

### 4.1 The parcel card

When an order has a parcel, show it. Model it from `NawrisParcelResource`:

```dart
class NawrisParcel {
  final int id;
  final String? code;              // their handle — what a courier says on the phone
  final String reference;          // ours
  final String? barCode;           // what gets scanned
  final String amountToCollect;    // what we asked them to collect
  final String deliveryPriceDeducted;
  final String? collectedAmount;   // what came back, incl. their own fee
  final int? remoteStatusCode;
  final String? remoteStatusText;  // their label — show this verbatim
  final bool isOpen;
  final bool hasOpenConflict;
  final DateTime? dispatchedAt;
  final DateTime? closedAt;
}
```

**Show `remote_status_text` beside our own status, never instead of it.** They are two different
claims about the same parcel and they are allowed to disagree — that disagreement is exactly what
somebody chasing a parcel needs to see. Ours is «جاري التوصيل»; theirs might be «تم التسليم» from
an hour ago that has not been processed yet.

`collected_amount` will usually be **higher** than `amount_to_collect`. That is not an error: the
courier adds their own fee at the door. Do not colour it red.

### 4.2 Dispatch needs no new UI

Moving an order to «جاري التوصيل» through the existing status endpoint lodges the parcel
automatically, when the city is mapped and credentials are configured. The app does nothing extra.

**But handle this failure shape:** the status change commits *first*, then the carrier is called.
So a `502` or a `422` from the status endpoint can mean **the order moved and the parcel was not
lodged**. Refresh the order on error rather than assuming the move failed, and surface the message —
it will name the reason («لم تُربط مدينة … بمحافظة لدى نورس بعد» is the common one).

### 4.3 Payments need no new UI either

Recording a payment on an order with a live parcel silently lowers the COD Nawris is holding. If
that call fails it is rescued server-side and logged — the payment still succeeds and the response
is normal. Nothing for the app to do.

---

## 5. Three things that will feel wrong and are not

**«إلغاء الشحنة» does not cancel the order.** An order is never written off while it is physically
outside the building. Cancelling the shipment tells Nawris to stop; the goods still come home
through the return chain, and only «راجع مكتب» offers «إلغاء تام». **Label the button
«إلغاء الشحنة لدى نورس», never «إلغاء الطلبية»**, or staff will press it expecting the latter.

**The carrier cannot always move the order.** Our return chain is walked one link at a time —
«راجع لدى المندوب» → «راجع لدى شركة التوصيل» → «راجع مكتب» — and Nawris jumps. When it announces a
step we cannot legally take, the event is **parked**: the raw label lands on the parcel, the order
does not move, and the event appears in the pending queue. This is by design, not a bug, and §6 is
where a human unsticks it.

**There is no refresh-from-carrier button.** No polling, no reconciliation job — everything after
dispatch arrives by webhook. A "check status" button would suggest the app can find out something
it cannot.

---

## 6. The operations screen — the part that matters

One screen, three tabs. Behind `carrier.view`.

### Tab 1 — «إشعارات لم تُعالَج» · `GET /carrier/events?pending=1`

**The single most important list in this feature.** An event received and never processed is an
order that has silently stopped moving, and nothing else in the app will ever show it.

Each row: the carrier's code, the status code, `error`, and how long it has been sitting. Show the
raw `payload` behind a tap — it is verbatim and it is often the only way to understand what
happened.

> If this list is never empty and nobody has noticed, **the queue worker is probably not running.**
> That is the integration's most likely silent failure, and this screen is how you find out.

### Tab 2 — «لم تُسلَّم للناقل» · `GET /carrier/not-lodged`

Orders out for delivery in a Nawris-mapped city with no parcel. Each row gets a **«إعادة المحاولة»**
button → `POST /carrier/orders/{id}/lodge`.

Nothing is wrong with these orders — they are genuinely out for delivery, Nawris just has not been
told. Word the empty state accordingly («كل الشحنات مُسلَّمة»), and do not style them as errors.

### Tab 3 — «تعارضات التسليم» · `GET /carrier/parcels?conflict=1`

A delivery arrived under a parcel code we did not expect. Show what we expected against what came
back, then **«إغلاق التعارض»** → `POST /carrier/parcels/{id}/resolve-conflict`.

Two shapes reach here and the screen should distinguish them:

- **Blocked** — a different code *and* a short amount. The order did **not** move and no money was
  written. Someone must look before anything happens.
- **Flagged only** — a different code but the amount matched. The order moved and the money was
  recorded; this is a review, not an emergency. Most conflicts are this one, because a legitimate
  re-send also arrives under a new code.

---

## 7. Suggested feature layout

```
lib/features/carrier/
├── data/
│   ├── models/  nawris_parcel.dart · nawris_webhook_event.dart
│   └── carrier_repository.dart
├── logic/
│   ├── carrier_events_cubit.dart      tabs 1 and 3
│   └── carrier_not_lodged_cubit.dart  tab 2
└── ui/
    ├── carrier_operations_page.dart
    └── widgets/  parcel_card.dart · event_tile.dart · conflict_tile.dart
```

`parcel_card.dart` is reused on the order detail screen (§4.1), so keep it free of anything that
assumes the operations page around it.

---

## 8. Build order

1. **`carrier_settled_amount` on the `Order` model and the payments card.** Smallest change, and
   without it the existing screen shows arithmetic that does not add up.
2. **The two mapping fields on the city and region forms.** Nothing dispatches until cities are
   mapped, so this unblocks everyone else.
3. **The parcel card on order detail.** The first thing staff will ask for.
4. **Tab 1.** The one that prevents silent failure.
5. **Tabs 2 and 3**, and the three `carrier.manage` buttons.

---

## 9. What the app deliberately does not get

- **A way to create a shipment directly.** Dispatch is a consequence of moving an order to «جاري
  التوصيل», and a second door would be a second set of preconditions to keep in step.
- **An edit-parcel form.** Money is the only thing that can change on a live parcel, and it changes
  through the payments screen that already exists.
- **A Nawris destination picker.** The order's city carries the mapping; asking a clerk to choose a
  government is asking them to re-answer a question the order already answered.
- **Anything that writes an order status from a carrier screen.** The webhook owns that path, and a
  second writer is how the two get out of step.
