# Purchase Orders — connecting the Flutter app

> How to wire `frontend/` up to the backend described in
> [PURCHASE-ORDERS-DESIGN.md](PURCHASE-ORDERS-DESIGN.md). Follows the recipe in
> [frontend/RULES.md §12](frontend/RULES.md) — this doc applies it to this specific feature
> rather than repeating the general rules.

---

## 0. Before you start — one dependency to know about

`POST /purchase-orders/{id}/arrivals` does not return a purchase order — it returns a
**`StockArrival`** (the same shape `POST /stock-arrivals` returns), now carrying
`purchase_order_id`. The Flutter app does not have a `vendors`/`stock_arrivals` feature yet (only
`warehouses`, which models the plain ledger via `StockMovement`). You need a minimal
`StockArrival` model to parse that one response even if you build nothing else from the Vendors
side yet — see §3. If a full Vendors feature lands first, reuse its model instead of the minimal
one below.

---

## 1. Endpoints

Add to [api_endpoints.dart](frontend/lib/core/network/api_endpoints.dart):

```dart
/// أوامر الشراء — stock ordered from a vendor ahead of it arriving.
abstract final class PurchaseOrderEndpoints {
  static const String index = '/purchase-orders';

  static String show(int id) => '/purchase-orders/$id';

  static String status(int id) => '/purchase-orders/$id/status';

  /// Guarded by `inventory.manage` on the server, not `purchase_orders.manage` — see the
  /// design doc §5. Gate the button on the app side the same way.
  static String arrivals(int id) => '/purchase-orders/$id/arrivals';

  static String logs(int id) => '/purchase-orders/$id/logs';
}
```

| Verb | Path | Permission | Cubit action |
|---|---|---|---|
| `GET` | `index` | `purchase_orders.view` | list, filter by `vendor_id`/`warehouse_id`/`status` |
| `POST` | `index` | `purchase_orders.manage` | create (`status` always comes back `new`) |
| `GET` | `show(id)` | `purchase_orders.view` | detail |
| `PUT` | `show(id)` | `purchase_orders.manage` | edit — **send the full `items` list every time**, see §5 |
| `PATCH` | `status(id)` | `purchase_orders.manage` | body `{"status": "arrived"}` or `{"status": "cancelled"}` only |
| `POST` | `arrivals(id)` | **`inventory.manage`** | receive a shipment |
| `GET` | `logs(id)` | `logs.view` | history |

---

## 2. Permission gating in the UI

Two **different** permissions govern this one screen, and that split is deliberate on the
backend (see design doc §5) — mirror it, don't collapse it:

- `purchase_orders.manage` → create, edit (while `new`), send, cancel.
- `inventory.manage` → the "receive shipment" button.

A user can legitimately have one without the other. Check both independently when deciding what
to render — **do not** assume `purchase_orders.manage` implies the receive action is available,
or the button will 403 on tap.

`status` only ever accepts two manual values from this app: `arrived` and `cancelled`.
`completed` is never sent — it is something the order *becomes*, never something requested.

---

## 3. Models

`lib/features/purchase_orders/models/purchase_order_status.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

/// new → arrived → completed, with cancelled reachable from new or arrived.
/// `unknown` for forward compatibility — see WarehouseType for why this shape is used everywhere
/// the server hands the app an enum.
enum PurchaseOrderStatus {
  @JsonValue('new')
  newOrder,
  @JsonValue('arrived')
  arrived,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  unknown,
}
```

`lib/features/purchase_orders/models/purchase_order_item.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_order_item.freezed.dart';
part 'purchase_order_item.g.dart';

@freezed
abstract class PurchaseOrderItem with _$PurchaseOrderItem {
  const factory PurchaseOrderItem({
    required int id,
    @JsonKey(name: 'product_variant_id') required int productVariantId,
    // Quantities are strings, never double — the same rule money follows. '10.000' as the
    // server sends it; do not parse to num for display, only for a form's numeric input.
    @JsonKey(name: 'quantity_ordered') required String quantityOrdered,
    @JsonKey(name: 'quantity_received') required String quantityReceived,
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,
  }) = _PurchaseOrderItem;

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemFromJson(json);
}
```

`lib/features/purchase_orders/models/purchase_order.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/purchase_orders/models/purchase_order_item.dart';
import 'package:printing/features/purchase_orders/models/purchase_order_status.dart';

part 'purchase_order.freezed.dart';
part 'purchase_order.g.dart';

@freezed
abstract class PurchaseOrder with _$PurchaseOrder {
  const factory PurchaseOrder({
    required int id,
    @JsonKey(name: 'vendor_id') required int vendorId,
    // Null when the list response didn't eager-load it — treat as "not loaded", not "no vendor".
    PurchaseOrderVendor? vendor,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    PurchaseOrderWarehouse? warehouse,
    @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown) required PurchaseOrderStatus status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'order_date') required DateTime orderDate,
    @JsonKey(name: 'expected_date') DateTime? expectedDate,
    String? notes,
    @Default(<PurchaseOrderItem>[]) List<PurchaseOrderItem> items,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PurchaseOrder;

  const PurchaseOrder._();

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => _$PurchaseOrderFromJson(json);

  bool get isEditable => status == PurchaseOrderStatus.newOrder;

  bool get canSend => status == PurchaseOrderStatus.newOrder;

  bool get canCancel =>
      status == PurchaseOrderStatus.newOrder || status == PurchaseOrderStatus.arrived;

  bool get canReceive =>
      status == PurchaseOrderStatus.newOrder || status == PurchaseOrderStatus.arrived;
}

@freezed
abstract class PurchaseOrderVendor with _$PurchaseOrderVendor {
  const factory PurchaseOrderVendor({required int id, required String name}) =
      _PurchaseOrderVendor;

  factory PurchaseOrderVendor.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderVendorFromJson(json);
}

@freezed
abstract class PurchaseOrderWarehouse with _$PurchaseOrderWarehouse {
  const factory PurchaseOrderWarehouse({required int id, required String name}) =
      _PurchaseOrderWarehouse;

  factory PurchaseOrderWarehouse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderWarehouseFromJson(json);
}
```

**Minimal `StockArrival`** (only if no Vendors feature exists yet — delete this once one does):

```dart
@freezed
abstract class StockArrival with _$StockArrival {
  const factory StockArrival({
    required int id,
    @JsonKey(name: 'vendor_id') required int vendorId,
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    @JsonKey(name: 'purchase_order_id') int? purchaseOrderId,
    @JsonKey(name: 'invoice_number') String? invoiceNumber,
    @JsonKey(name: 'received_by') required int receivedBy,
  }) = _StockArrival;

  factory StockArrival.fromJson(Map<String, dynamic> json) => _$StockArrivalFromJson(json);
}
```

---

## 4. Repository

`lib/features/purchase_orders/repositories/purchase_order_repository.dart`:

```dart
abstract interface class PurchaseOrderRepository {
  Future<Either<Failure, Paginated<PurchaseOrder>>> purchaseOrders({
    int? vendorId,
    int? warehouseId,
    PurchaseOrderStatus? status,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, PurchaseOrder>> show(int id);

  Future<Either<Failure, PurchaseOrder>> create({
    required int vendorId,
    required int warehouseId,
    required DateTime orderDate,
    DateTime? expectedDate,
    String? notes,
    required List<PurchaseOrderItemInput> items,
  });

  /// Sends the FULL current line set — see design doc §6. A line missing from [items] is
  /// removed on the server.
  Future<Either<Failure, PurchaseOrder>> update(
    int id, {
    required int vendorId,
    required int warehouseId,
    required DateTime orderDate,
    DateTime? expectedDate,
    String? notes,
    required List<PurchaseOrderItemInput> items,
  });

  Future<Either<Failure, PurchaseOrder>> send(int id);

  Future<Either<Failure, PurchaseOrder>> cancel(int id);

  /// Requires `inventory.manage`, not `purchase_orders.manage` — gate the calling button
  /// accordingly (§2). Returns the StockArrival the receipt produced, not the order — re-fetch
  /// [show] to render the order's own updated status and line totals.
  Future<Either<Failure, StockArrival>> receiveArrival(
    int id, {
    required List<PurchaseOrderItemInput> items,
    String? invoiceNumber,
    String? notes,
  });
}

/// One line, shaped identically for both create/update and receive — [id] is present only when
/// updating an existing order line (§6); absent, it creates a new one.
class PurchaseOrderItemInput {
  const PurchaseOrderItemInput({required this.productVariantId, required this.quantity, this.id});

  final int? id;
  final int productVariantId;
  final String quantity;

  Map<String, dynamic> toJson({required String quantityKey}) => {
    if (id != null) 'id': id,
    'product_variant_id': productVariantId,
    quantityKey: quantity,
  };
}
```

`lib/features/purchase_orders/repositories/purchase_order_repository_impl.dart` — same shape as
[warehouse_repository_impl.dart](frontend/lib/features/warehouses/repositories/warehouse_repository_impl.dart):

```dart
class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  const PurchaseOrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<PurchaseOrder>>> purchaseOrders({
    int? vendorId,
    int? warehouseId,
    PurchaseOrderStatus? status,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<PurchaseOrder>(
      () => _dio.get(
        PurchaseOrderEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (vendorId != null) 'vendor_id': vendorId,
          if (warehouseId != null) 'warehouse_id': warehouseId,
          if (status != null) 'status': _statusValue(status),
        },
      ),
      parseItem: PurchaseOrder.fromJson,
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> show(int id) {
    return safeRequest<PurchaseOrder>(
      () => _dio.get(PurchaseOrderEndpoints.show(id)),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> create({
    required int vendorId,
    required int warehouseId,
    required DateTime orderDate,
    DateTime? expectedDate,
    String? notes,
    required List<PurchaseOrderItemInput> items,
  }) {
    return safeRequest<PurchaseOrder>(
      () => _dio.post(
        PurchaseOrderEndpoints.index,
        data: _body(vendorId, warehouseId, orderDate, expectedDate, notes, items),
      ),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> update(
    int id, {
    required int vendorId,
    required int warehouseId,
    required DateTime orderDate,
    DateTime? expectedDate,
    String? notes,
    required List<PurchaseOrderItemInput> items,
  }) {
    return safeRequest<PurchaseOrder>(
      () => _dio.put(
        PurchaseOrderEndpoints.show(id),
        data: _body(vendorId, warehouseId, orderDate, expectedDate, notes, items),
      ),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> send(int id) => _changeStatus(id, 'arrived');

  @override
  Future<Either<Failure, PurchaseOrder>> cancel(int id) => _changeStatus(id, 'cancelled');

  Future<Either<Failure, PurchaseOrder>> _changeStatus(int id, String status) {
    return safeRequest<PurchaseOrder>(
      () => _dio.patch(PurchaseOrderEndpoints.status(id), data: {'status': status}),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockArrival>> receiveArrival(
    int id, {
    required List<PurchaseOrderItemInput> items,
    String? invoiceNumber,
    String? notes,
  }) {
    return safeRequest<StockArrival>(
      () => _dio.post(
        PurchaseOrderEndpoints.arrivals(id),
        data: {
          if (invoiceNumber != null) 'invoice_number': invoiceNumber,
          if (notes != null) 'notes': notes,
          'items': items.map((i) => i.toJson(quantityKey: 'quantity')).toList(),
        },
      ),
      parse: (data) => StockArrival.fromJson(data as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> _body(
    int vendorId,
    int warehouseId,
    DateTime orderDate,
    DateTime? expectedDate,
    String? notes,
    List<PurchaseOrderItemInput> items,
  ) {
    return {
      'vendor_id': vendorId,
      'warehouse_id': warehouseId,
      'order_date': _dateOnly(orderDate),
      if (expectedDate != null) 'expected_date': _dateOnly(expectedDate),
      if (notes != null) 'notes': notes,
      'items': items.map((i) => i.toJson(quantityKey: 'quantity_ordered')).toList(),
    };
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;

  String _statusValue(PurchaseOrderStatus status) => switch (status) {
    PurchaseOrderStatus.newOrder => 'new',
    PurchaseOrderStatus.arrived => 'arrived',
    PurchaseOrderStatus.completed => 'completed',
    PurchaseOrderStatus.cancelled => 'cancelled',
    PurchaseOrderStatus.unknown => throw ArgumentError('cannot filter by an unknown status'),
  };
}
```

---

## 5. UseCases

One verb each, mirroring [warehouses' set](frontend/lib/features/warehouses/usecases/):

`GetPurchaseOrders`, `GetPurchaseOrder`, `CreatePurchaseOrder`, `UpdatePurchaseOrder`,
`SendPurchaseOrder`, `CancelPurchaseOrder`, `ReceivePurchaseOrderArrival`.

Each takes `PurchaseOrderRepository` in its constructor and exposes one `call(...)`. No business
logic beyond argument shaping belongs here — the server is the source of truth for every rule
described in the design doc (editable-only-while-new, the over-receipt guard, the status map).
The app's job is to *reflect* those rules in what it lets a user tap (§2), and to show the
server's own 422 when it disagrees — never to silently re-implement them client-side.

---

## 6. Cubit / state notes specific to this feature

- **List screen** — same `CitiesCubit` shape (`initial → loading → loaded → failure`, `_requestId`
  guard against late responses, failed extra page doesn't clear what's shown). Filter chips for
  `status` map 1:1 to `PurchaseOrderStatus`.
- **Detail screen** — one Cubit holding the `PurchaseOrder`, with distinct pending-flags for
  send/cancel/receive so a tap on "cancel" doesn't grey out "receive" too. Re-fetch (`GetPurchaseOrder`)
  after every mutating action rather than trying to patch the in-memory order by hand — receiving
  in particular changes multiple lines' `quantity_received` and the order's own `status` in one
  server-side transaction, and reconstructing that client-side is a second place the completion
  rule could drift from the server's.
- **Create/edit form** — one line-items editor, Freezed-state list of `PurchaseOrderItemInput`
  (or a small local model that carries the same fields plus a `key` for the widget list). On
  submit, send the **entire** current list — see §6 of the design doc; there is no add/remove
  endpoint per line.
- **Receive-arrival form** — pre-fill one input per line from `PurchaseOrder.items`, defaulting
  the quantity field to `quantityRemaining`, not `quantityOrdered` — the common case is finishing
  a partial shipment, not re-receiving the whole thing.
- **422 handling** — the over-receipt and "variant not on this order" failures both come back
  with `errors.items` (a single message under the `items` key, not per-index) — show it as a
  form-level message above the line list, not attached to one specific row, since the server
  doesn't say which row.

---

## 7. Injector registration

```dart
static void _registerPurchaseOrders() {
  sl
    ..registerLazySingleton<PurchaseOrderRepository>(
      () => PurchaseOrderRepositoryImpl(sl<Dio>()),
    )
    ..registerLazySingleton<GetPurchaseOrders>(() => GetPurchaseOrders(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<GetPurchaseOrder>(() => GetPurchaseOrder(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<CreatePurchaseOrder>(() => CreatePurchaseOrder(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<UpdatePurchaseOrder>(() => UpdatePurchaseOrder(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<SendPurchaseOrder>(() => SendPurchaseOrder(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<CancelPurchaseOrder>(() => CancelPurchaseOrder(sl<PurchaseOrderRepository>()))
    ..registerLazySingleton<ReceivePurchaseOrderArrival>(
      () => ReceivePurchaseOrderArrival(sl<PurchaseOrderRepository>()),
    )
    ..registerFactory<PurchaseOrdersCubit>(
      () => PurchaseOrdersCubit(getPurchaseOrders: sl<GetPurchaseOrders>()),
    )
    ..registerFactoryParam<PurchaseOrderDetailCubit, int, void>(
      (id, _) => PurchaseOrderDetailCubit(
        purchaseOrderId: id,
        getPurchaseOrder: sl<GetPurchaseOrder>(),
        sendPurchaseOrder: sl<SendPurchaseOrder>(),
        cancelPurchaseOrder: sl<CancelPurchaseOrder>(),
        receiveArrival: sl<ReceivePurchaseOrderArrival>(),
      ),
    );
}
```

Call `_registerPurchaseOrders();` from the same place `_registerWarehouses();` is called.

---

## 8. Recipe checklist

Following [frontend/RULES.md §12](frontend/RULES.md):

1. `models/` — §3 above, then `dart run build_runner build`.
2. `repositories/purchase_order_repository.dart` — §4's contract.
3. `repositories/purchase_order_repository_impl.dart` — §4's impl.
4. `usecases/` — §5.
5. `presentation/viewmodel/` — Cubits + Freezed states per §6.
6. `presentation/views/` — list, detail, create/edit form, receive-arrival form.
7. Register in [Injector](frontend/lib/core/di/injector.dart) — §7.
8. Cubit tests — fake `PurchaseOrderRepository`, assert the state sequence for each action
   including the 422 path (over-receipt, editing a non-`new` order).
9. `dart run build_runner build`, then `flutter analyze`, then `flutter test`.

Verify against the live contract before wiring anything: run the backend and open
`http://localhost:8000/docs/api` — if this document disagrees with it, the spec is right.
