# Purchase order additional costs — connecting the Flutter app

> How to bring `frontend/lib/features/purchase_orders/` up to date with the backend change in
> [PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md](PURCHASE-ORDER-ADDITIONAL-COSTS-BACKEND-CHANGES.md).
> Nothing here has been implemented — the backend task this doc follows was explicitly backend
> only. File paths, class names and code below are shown against what is **actually in the repo
> today** (read directly from `frontend/lib/features/purchase_orders/`), not the older, more
> generic [PURCHASE-ORDERS-FRONTEND-INTEGRATION.md](PURCHASE-ORDERS-FRONTEND-INTEGRATION.md).

---

## 0. Read this first — this is not a field rename

The current app carries **no cost of any kind** on a purchase order. `PurchaseOrderItem` and
`PurchaseOrder` (`lib/features/purchase_orders/models/purchase_order.dart`) have no cost fields,
and `PurchaseOrderLine.toJson()` (`repositories/purchase_order_repository.dart`) sends only `id`,
`product_variant_id`, `quantity_ordered`. That reflects the *original* design
(`VENDORS-AND-PURCHASE-ORDERS.md`: **"لا مال فيها إطلاقاً"** — no money on it at all), which the
model's own docblock still quotes.

The server moved on from that design before this change (see
`COST-TRACKING-UNIT-CONVERSION.md`), and `items.*.base_total_cost` (formerly `items.*.unit_cost`)
has been **required** on `POST`/`PUT /purchase-orders` since then. That means **creating or
editing a purchase order through the live app fails validation today, independent of this
change** — this isn't a regression this feature introduces, but closing it is now unavoidable if
that screen is to work at all. Budget for it as new UI (a cost field per line, plus a whole new
additional-costs editor), not a one-line rename.

---

## 1. What the server now expects and returns

Request body (`POST`/`PUT /purchase-orders`) — `items.*.unit_cost` no longer exists; every item
needs `base_total_cost` instead (the line's total cost, not a per-unit price — the server derives
the per-unit figure). A new, optional `additional_costs` array sits alongside `items`:

```jsonc
{
  "vendor_id": 3, "warehouse_id": 5, "order_date": "2026-08-13",
  "items": [
    { "id": 40, "product_variant_id": 14, "quantity_ordered": 4, "base_total_cost": 75 },
    { "product_variant_id": 22, "quantity_ordered": 6, "base_total_cost": 25 }
  ],
  "additional_costs": [
    { "id": 7, "name": "Delivery", "amount": 10 },
    { "name": "Customs", "amount": 3 }
  ]
}
```

Same replace-the-whole-set contract `items` already follows (§6 of the design doc): an
`additional_costs` entry with an `id` updates that cost, one without creates a new one, and any
existing cost missing from the array is removed. **Omitting `additional_costs` on a `PUT` clears
it** — send the full current list every time, exactly like `items`.

Response (`PurchaseOrderResource` / `PurchaseOrderItemResource`) — new fields:

```jsonc
{
  "total_amount": "113.00",            // now present — was never sent to this app before
  "total_additional_cost": "13.00",
  "additional_costs": [
    { "id": 7, "name": "Delivery", "amount": "10.00" },
    { "id": 8, "name": "Customs", "amount": "3.00" }
  ],
  "items": [
    {
      "base_total_cost": "75.00",              // what was typed
      "base_unit_cost": "18.750",              // base_total_cost / quantity_ordered
      "allocated_additional_cost": "9.75",     // this line's share of total_additional_cost
      "final_unit_cost": "21.188",             // the landed cost — show this as "the real cost"
      "final_total_cost": "84.75"
    }
  ]
}
```

All five are strings, like every other money/quantity field in this app — never parse to `num`
except for a form's numeric input. `base_unit_cost`, `allocated_additional_cost`,
`final_unit_cost`, `final_total_cost` are **server-computed only** — nothing in the app should
ever send them back.

`POST /purchase-orders/{id}/arrivals` needs no change at all: it still returns a `StockArrival`
with `unit_cost`/`total_cost`, unchanged in shape. The only difference is that value now reflects
the landed cost automatically — nothing to build for that.

---

## 2. Model changes

`lib/features/purchase_orders/models/purchase_order.dart`:

```dart
@freezed
abstract class PurchaseOrder with _$PurchaseOrder {
  const factory PurchaseOrder({
    // … existing fields …

    /// Null on an order raised before cost tracking existed. Already inclusive of
    /// total_additional_cost — each line's final_total_cost (summed into this) already carries
    /// its allocated share, so don't add the two together on screen.
    @JsonKey(name: 'total_amount') String? totalAmount,
    @JsonKey(name: 'total_additional_cost') String? totalAdditionalCost,

    /// Delivery, unloading, customs, … — order-level costs not tied to any one line.
    @Default(<PurchaseOrderAdditionalCost>[]) List<PurchaseOrderAdditionalCost> additionalCosts,

    // … rest unchanged …
  }) = _PurchaseOrder;

  // … rest unchanged …
}

/// One line: a size, how much was ordered, how much has turned up, and what it costs.
@freezed
abstract class PurchaseOrderItem with _$PurchaseOrderItem {
  const factory PurchaseOrderItem({
    // … existing fields …

    /// Null only on a line predating cost tracking.
    @JsonKey(name: 'base_total_cost') String? baseTotalCost,
    @JsonKey(name: 'base_unit_cost') String? baseUnitCost,
    @JsonKey(name: 'allocated_additional_cost') String? allocatedAdditionalCost,

    /// The landed cost — base plus this line's share of the order's additional costs. Show
    /// *this* as "what this line costs," not base_unit_cost, once it's non-null.
    @JsonKey(name: 'final_unit_cost') String? finalUnitCost,
    @JsonKey(name: 'final_total_cost') String? finalTotalCost,
  }) = _PurchaseOrderItem;

  // … rest unchanged …
}

/// One order-level cost not tied to any line — delivery, unloading, customs.
@freezed
abstract class PurchaseOrderAdditionalCost with _$PurchaseOrderAdditionalCost {
  const factory PurchaseOrderAdditionalCost({
    required int id,
    required String name,
    required String amount,
  }) = _PurchaseOrderAdditionalCost;

  factory PurchaseOrderAdditionalCost.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderAdditionalCostFromJson(json);
}
```

Then `dart run build_runner build`.

---

## 3. Repository changes

`lib/features/purchase_orders/repositories/purchase_order_repository.dart`:

```dart
/// One line of an order as the server needs it.
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.productVariantId,
    required this.quantity,
    required this.baseTotalCost,   // new — required, matches the server's own required rule
    this.id,
  });

  final int? id;
  final int productVariantId;
  final String quantity;

  /// As typed, normalised to ASCII digits. The line's total cost, not a per-unit price — the
  /// server derives base_unit_cost from this, never the other way around.
  final String baseTotalCost;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'product_variant_id': productVariantId,
    'quantity_ordered': quantity,
    'base_total_cost': baseTotalCost,
  };
}

/// One order-level additional cost as the form holds it.
class PurchaseOrderAdditionalCostLine {
  const PurchaseOrderAdditionalCostLine({
    required this.name,
    required this.amount,
    this.id,
  });

  /// Absent means "new"; present corrects that cost in place. Same replace-the-whole-set
  /// contract as [PurchaseOrderLine] — an existing cost left out of the list is removed.
  final int? id;
  final String name;
  final String amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'name': name,
    'amount': amount,
  };
}
```

`create`/`update` gain an `additionalCosts` parameter:

```dart
Future<Either<Failure, PurchaseOrder>> create({
  required int vendorId,
  required int warehouseId,
  required String orderDate,
  required List<PurchaseOrderLine> items,
  // Empty list, not null-vs-empty — matches the server treating an absent/empty
  // additional_costs the same way (§1).
  List<PurchaseOrderAdditionalCostLine> additionalCosts = const [],
  String? expectedDate,
  String? notes,
});

Future<Either<Failure, PurchaseOrder>> update(
  int purchaseOrderId, {
  required int vendorId,
  required int warehouseId,
  required String orderDate,
  required List<PurchaseOrderLine> items,
  List<PurchaseOrderAdditionalCostLine> additionalCosts = const [],
  String? expectedDate,
  String? notes,
});
```

`purchase_order_repository_impl.dart` — thread it through the shared `_document(...)` body
builder:

```dart
Map<String, dynamic> _document({
  required int vendorId,
  required int warehouseId,
  required String orderDate,
  required List<PurchaseOrderLine> items,
  required List<PurchaseOrderAdditionalCostLine> additionalCosts,
  String? expectedDate,
  String? notes,
}) {
  return {
    'vendor_id': vendorId,
    'warehouse_id': warehouseId,
    'order_date': orderDate,
    'expected_date': ?expectedDate,
    'notes': ?notes,
    'items': items.map((line) => line.toJson()).toList(growable: false),
    'additional_costs': additionalCosts.map((c) => c.toJson()).toList(growable: false),
  };
}
```

---

## 4. Use case / cubit changes

`lib/features/purchase_orders/usecases/purchase_order_usecases.dart`:

- `DraftLine` gains a `baseTotalCost` field (text, as typed — same treatment `quantity` already
  gets).
- New `DraftAdditionalCost` (`id?`, `name`, `amount` — both text, as typed).
- `SavePurchaseOrder.call()` gains `required List<DraftAdditionalCost> additionalCosts`, converts
  each amount through the same `_number()` Arabic-digit/comma normaliser `quantity` already goes
  through, and builds `PurchaseOrderLine`/`PurchaseOrderAdditionalCostLine` to pass down.

```dart
class DraftLine {
  const DraftLine({
    required this.productVariantId,
    required this.quantity,
    required this.baseTotalCost,   // new
    this.id,
    this.title,
  });

  final int? id;
  final int productVariantId;
  final String quantity;
  final String baseTotalCost;
  final String? title;
}

/// One additional cost as the form holds it.
class DraftAdditionalCost {
  const DraftAdditionalCost({required this.name, required this.amount, this.id});

  final int? id;
  final String name;
  final String amount;
}
```

`save_purchase_order_cubit.dart` — `submit()` gains the same `additionalCosts` parameter and
passes it straight through to `SavePurchaseOrder`. No new state cases needed — this stays inside
the existing `initial → submitting → success/failure` shape.

---

## 5. UI

- **Line-items editor** (`purchase_order_form_page.dart`) — add a cost text field next to each
  line's quantity field. Validate `numeric`, `>= 0`, matching the server's own `base_total_cost`
  rule, so a bad value is caught before the request rather than surfacing as a 422 on a field the
  form can't point at cleanly.
- **New additional-costs editor** — a second small list, same add/remove-row shape as the line
  items list: a name field and an amount field per row. Reuse whatever pattern the line-items
  editor already uses for add/remove so the two lists feel like one screen, not two features
  bolted together.
- **Detail screen** — show `total_amount` and, if non-null, `total_additional_cost` and the
  `additional_costs` list (read-only — additional costs are only editable through the `PUT`
  form, same as items). Per line, prefer `final_unit_cost`/`final_total_cost` over the base
  figures once present — that's the number that actually matters (the landed cost), with base
  cost and the allocated share available as a detail/tooltip for whoever wants to see the split.
- **Receive-arrival screen** — no changes. It already only deals in quantities; the landed cost
  is applied automatically server-side the moment a shipment posts.

---

## 6. Migration checklist

1. `models/purchase_order.dart` — §2, then `dart run build_runner build`.
2. `repositories/purchase_order_repository.dart` + `_impl.dart` — §3.
3. `usecases/purchase_order_usecases.dart` — §4.
4. `presentation/viewmodel/save_purchase_order_cubit.dart` — §4.
5. `presentation/views/purchase_order_form_page.dart` — §5 (cost field per line, additional-costs
   editor).
6. `presentation/views/purchase_order_detail_page.dart` — §5 (totals + additional-costs display).
7. Existing tests that build a `PurchaseOrderLine`/`DraftLine`/call `SavePurchaseOrder` will fail
   to compile once `baseTotalCost` becomes required — update fixtures alongside the production
   code, don't default it to `'0'` just to keep them green.
8. `test/features/purchase_orders/purchase_order_wire_test.dart` — extend with the new
   response fields (§1's example payload is a ready-made fixture).
9. `dart run build_runner build`, then `flutter analyze`, then `flutter test`.

Verify against the live contract before wiring anything: run the backend and open
`http://localhost:8000/docs/api` — if this document disagrees with it, the spec is right.
