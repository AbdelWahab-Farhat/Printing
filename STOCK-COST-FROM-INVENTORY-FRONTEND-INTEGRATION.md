# Stock cost from inventory — connecting the Flutter app

> **Status: not started.** The backend is built and green — see
> [STOCK-COST-FROM-INVENTORY.md](STOCK-COST-FROM-INVENTORY.md). Nothing in `frontend/` has been
> touched. This doc is the plan for wiring the app up, written against the shipped API.

---

## 0. Where the app stands, and the one thing already broken

The app can record stock movements and read balances. It cannot see or set a cost.

**`POST /stock-movements/adjustments` with `direction=increase` fails today, every time.**
`RecordAdjustmentRequest` requires `unit_cost` on an increase, and
[`warehouse_repository_impl.dart:178`](frontend/lib/features/warehouses/repositories/warehouse_repository_impl.dart#L178)
sends `stock_item_id`, `warehouse_id`, `quantity`, `direction` and an optional `notes` — no cost.
The server answers 422 «تكلفة الوحدة مطلوبة عند تسجيل زيادة» and the storekeeper sees a refusal
about a field the form never showed them. **§1 is therefore a bug fix, not a feature.**

The quieter half: `POST /stock-movements/arrivals` accepts `unit_cost` and the app omits it, so
every delivery recorded from the app opens its cost layer at `0.000`. FIFO consumes those first,
which is how orders end up recording `material_cost = 0`.

Nothing else breaks. The four new response fields are additive, and `json_serializable` ignores
keys it was not told about.

---

## 1. Send the cost on the way in *(do this first)*

No new screen. Three files and the sheet.

**`WarehouseRepository`** — `recordArrival` and `recordAdjustment` take `String? unitCost`.
**`_impl`** — `'unit_cost': ?unitCost`, omitted rather than sent as null: the API reads an absent
key as «لم يُسجَّل سعرها», which is what leaves the layer findable in the uncosted queue instead
of priced at nothing.

**`RecordStockMovement`** (the use case) — one parameter and **one rule that must not live in a
widget**: only an arrival and an increasing adjustment open a new cost layer, so only those two
may carry a price. A figure typed and then abandoned by switching the chip to «تحويل» is dropped
here, not by the form hiding a box.

```dart
bool get opensCostLayer => this == MovementKind.arrival || this == MovementKind.increase;
bool get requiresCost   => this == MovementKind.increase;
```

The cost goes through the same normalisation the quantity already does — ٣٫٥ and `3,5` both have
to reach the API as `3.5` — and **an empty box is `null`, never `'0'`**: «لا نعرف سعرها» and
«مجانية» are different claims.

**`record_movement_sheet.dart`** — «تكلفة الوحدة (لكل كغم)» shown only when `opensCostLayer`,
validated as required when `requiresCost`. Label it per unit like the quantity box above it:
«التكلفة» alone reads as the whole delivery's price on a form whose previous question was a
quantity.

**`RecordMovementState`** — `unitCostError => _fieldError('unit_cost')`, added to
`hasFieldErrors`, so the server's complaint lands under the box rather than in a snackbar.

**Also fix while you are here:** `notes` is required by the API on *both* adjustment directions
(`min:3`), and the app sends it only when non-empty. The sheet already validates it; the
repository's `if (notes != null && notes.isNotEmpty)` is what drops it.

---

## 2. What the server now returns

### `GET /stock-batches` — the cost layers

Behind `inventory.view`. Filters: `warehouse_id`, `stock_item_id`, `uncosted`, `remaining`,
`per_page`. Paginated, and **ordered the way FIFO consumes them** — oldest `received_at` first.
Used-up layers are excluded unless `remaining=0` asks for them.

```jsonc
{
  "id": 40,
  "warehouse_id": 2,  "warehouse":  { "id": 2, "name": "المخزن الرئيسي" },
  "stock_item_id": 7, "stock_item": { "id": 7, "code": "S7", "name": "كيس شحن",
                                      "display_name": "كيس شحن 25*35" },

  "unit_cost": "0.000",
  "quantity_received": "500.000",
  "quantity_remaining": "300.000",
  "quantity_consumed": "200.000",
  "unit": "kilogram", "unit_label": "كيلوغرام",

  "source_type": "purchase_arrival", "source_type_label": "توريد",
  "received_at": "2026-08-12T09:00:00+00:00",
  "revalued_at": null,

  "stock_movement_id": 88,
  "recorded_by": 4,
  "purchase_order_id": null,
  "split_from_batch_id": null,

  "can_be_revalued": true,
  "is_partly_consumed": true,
  "is_uncosted": true,

  "created_at": "2026-08-12T09:00:00+00:00"
}
```

**The three booleans are the point.** The app must not work out for itself whether a layer may be
repriced — that is a rule the domain owns, and a client re-deriving it offers a button the server
then refuses. Draw the warnings from these:

| Field | What the app does with it |
|---|---|
| `can_be_revalued: false` | the layer is used up — no edit affordance at all |
| `is_partly_consumed: true` | warn «صُرف منها ٢٠٠ من ٥٠٠ — التصحيح يسري على المتبقي فقط» |
| `purchase_order_id` not null | warn «هذه الدفعة من أمر شراء رقم ٧ — التعديل قد يخالف سعر الفاتورة» |
| `is_uncosted: true` | the badge that makes a zero-cost layer visible in a list |

`stock_movement_id` and `purchase_order_id` are **null on every layer opened before this change** —
there was nothing to record them from, and guessing by timestamp would be a fabrication. Render
«غير معروف», not an error.

### `PATCH /stock-batches/{id}/cost` — the correction

Behind **`inventory.revalue`**, a new permission — *not* `inventory.manage`.

```jsonc
{ "unit_cost": "3.500", "quantity": "100.000", "reason": "فاتورة المورد وصلت بسعر مختلف" }
```

| Field | Rule |
|---|---|
| `unit_cost` | required, `>= 0`. **Zero is allowed** — correcting a layer down to nothing is a real decision |
| `quantity` | optional. Omitted = the whole remainder. Smaller = **splits the layer** |
| `reason` | **required**, 3–1000 chars |

Answers the corrected batch as a single `StockBatchResource`. Refusals: **403** without the
grant; **422** on `unit_cost` when the layer is fully consumed, on `quantity` when it exceeds the
remainder, on `reason` when missing.

**What the split does, so the screen can explain it.** The repriced quantity stays on the
original row — which is what keeps it first in the FIFO queue — and the *untouched remainder*
moves to a new row at the old price, carrying `split_from_batch_id`. After repricing 100 of 500:

```
#40  remaining 100  @ 3.500   ← the row you edited, consumed next
#41  remaining 200  @ 0.000   ← split_from_batch_id = 40
```

Re-fetch the list after a save rather than patching one row in place: one call produces two.

### `GET /stock-items/{id}` — the suggested cost

```jsonc
"last_known_unit_cost": {
  "unit_cost": "3.500",
  "received_at": "2026-08-12T09:00:00+00:00",
  "source_type_label": "توريد"
}
```

Null when nothing was ever priced. **Single-item response only** — the listing does not carry it.

---

## 3. What to build in the app

### `AppPermission`

`revalueStock('inventory.revalue', 'تعديل تكلفة دفعات المخزون')`.
`permission_contract_test.dart` fails until this exists — that is the guard working.

### `StockBatch` model + repository

A Freezed model over the payload above, a `stockBatches({warehouseId, stockItemId, uncosted})`
read and a `revalueStockBatch(id, {unitCost, quantity, reason})` write on a repository, each
behind a use case as RULES §2 requires.

### Where the layers appear

**On a shelf**, from the stock row's overflow: «دفعات التكلفة» — the layers in consumption order,
each showing cost, remaining/received, age, source, and a badge on the uncosted ones. This is the
first screen in the app that can answer «بكم هذه البضاعة؟».

**As a queue**, from the inventory section: «بضاعة بلا تكلفة» → `?uncosted=1`. Worth a home-screen
count if the number is ever non-trivial: FIFO draws these first, so every one of them is about to
become an order with no material cost.

### The revaluation sheet

Opened from a layer, behind `revalueStock`, showing what the layer is and asks for three things:

- **the new cost**, pre-filled with the current one (this screen exists to change a number
  deliberately, so a default here is correct);
- **how much of it** — default «كل المتبقي (٣٠٠)», with the option to name less, which the sheet
  should say will split the layer;
- **the reason**, required.

Both warnings above the button, drawn from the flags — never computed locally.

### The suggestion chip *(the arrival form)*

The cost box starts **empty**, with a chip under it:

```
آخر سعر معروف: ٣٫٥٠٠ د.ل / كغم — توريد ١٢ أغسطس        [ استخدامه ]
```

Tapping fills the box. **Not tapping leaves it empty**, the layer opens at `0.000`, and it lands
in the uncosted queue.

**Do not pre-fill it.** A filled box is accepted by muscle memory, and then a cost nobody decided
is in the books; worse, zero-cost layers stop appearing and the only signal that anybody was
*meant* to price the stock is gone. The tap is the confirmation — no dialog, one gesture — and it
is why no `cost_source` flag is needed anywhere: a cost in the database is always one a person
chose.

**Show the date and the source, not just the number.** «آخر سعر: ٣٫٥٠٠» invites acceptance;
«٣٫٥٠٠ — توريد ١٢ أغسطس» invites the judgement the person at the shelf is there to make.

---

## 4. Tests

- `record_stock_movement_test.dart` — the cost travels on an arrival and an increase, is
  **dropped** on a transfer and a decrease, an empty box sends nothing rather than `'0'`, and
  Arabic-Indic digits reach the API as a number.
- A wire test for the revaluation payload: `quantity` omitted when the whole layer is being
  repriced, sent when it is not.
- The three flags drive the three affordances — a fully-consumed layer offers no edit, a
  partly-consumed one warns, a PO-linked one warns.
- The suggestion chip fills the box only when tapped, and an untouched box sends no cost.

`permission_contract_test.dart` and `order_resource_contract_test.dart` need no changes; the
first will tell you when `AppPermission` is done.

---

## 5. Checklist

- [ ] §1 — `unit_cost` on arrivals and increases, and the `notes` fix *(the live 422)*
- [ ] `AppPermission.revalueStock`
- [ ] `StockBatch` model + repository + use cases
- [ ] «دفعات التكلفة» on a shelf
- [ ] «بضاعة بلا تكلفة» queue
- [ ] The revaluation sheet, with both warnings
- [ ] The suggestion chip on the arrival form
- [ ] `flutter analyze` clean · `flutter test` green

> **The tree has a pre-existing blocker.** `flutter analyze` reports an error at
> [order_status_chip.dart:64](frontend/lib/features/orders/presentation/widgets/order_status_chip.dart#L64)
> — a switch not covering `OrderStatus.readyToPrint`, left by the ready-to-print status work. It
> is a *compile* error, so it currently fails ~14 test files that transitively import that widget.
> Unrelated to this feature, and it needs fixing before the suite can go green.
