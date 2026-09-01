import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [WarehouseRepository] over HTTP.
class WarehouseRepositoryImpl implements WarehouseRepository {
  const WarehouseRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Warehouse>>> warehouses({
    String? search,
    WarehouseType? type,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Warehouse>(
      () => _dio.get(
        WarehouseEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          // `unknown` is a kind this build cannot name, so it is no filter at all — sending it
          // would ask the server about a word it has never heard of.
          if (type != null && type != WarehouseType.unknown) 'type': _wire(type),
        },
      ),
      parseItem: Warehouse.fromJson,
    );
  }

  @override
  Future<Either<Failure, Warehouse>> create({
    required String name,
    required WarehouseType type,
    String? location,
  }) {
    return safeRequest<Warehouse>(
      () => _dio.post(WarehouseEndpoints.index, data: _body(name, type, location)),
      parse: (data) => Warehouse.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Warehouse>> update(
    int warehouseId, {
    required String name,
    required WarehouseType type,
    String? location,
  }) {
    return safeRequest<Warehouse>(
      () => _dio.put(WarehouseEndpoints.show(warehouseId), data: _body(name, type, location)),
      parse: (data) => Warehouse.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int warehouseId) {
    return safeCommand(() => _dio.delete(WarehouseEndpoints.show(warehouseId)));
  }

  @override
  Future<Either<Failure, Paginated<WarehouseStock>>> stocks(
    int warehouseId, {
    bool? lowStock,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<WarehouseStock>(
      () => _dio.get(
        WarehouseEndpoints.stocks(warehouseId),
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (lowStock != null) 'low_stock': lowStock ? 1 : 0,
          if (inStock != null) 'in_stock': inStock ? 1 : 0,
        },
      ),
      parseItem: WarehouseStock.fromJson,
    );
  }

  @override
  Future<Either<Failure, WarehouseStockSummary>> stockSummary(int warehouseId) {
    return safeRequest<WarehouseStockSummary>(
      () => _dio.get(WarehouseEndpoints.stocksSummary(warehouseId)),
      parse: (data) => WarehouseStockSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, WarehouseStock>> setThreshold(
    int warehouseId,
    int stockId, {
    String? threshold,
  }) {
    return safeRequest<WarehouseStock>(
      () => _dio.patch(
        WarehouseEndpoints.stockThreshold(warehouseId, stockId),
        // Sent as an explicit null when cleared: the key being absent would read as «اتركه كما
        // هو», and «لا تنبهني» is a decision somebody made.
        data: <String, dynamic>{'low_stock_threshold': threshold},
      ),
      parse: (data) => WarehouseStock.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<StockMovement>>> movements({
    int? warehouseId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<StockMovement>(
      () => _dio.get(
        StockMovementEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          'warehouse_id': ?warehouseId,
          'stock_item_id': ?stockItemId,
        },
      ),
      parseItem: StockMovement.fromJson,
    );
  }

  @override
  Future<Either<Failure, Paginated<StockBatch>>> stockBatches({
    required int warehouseId,
    required int stockItemId,
    bool remaining = true,
    int page = 1,
    int perPage = 50,
  }) {
    return safePaginatedRequest<StockBatch>(
      () => _dio.get(
        StockBatchEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          'warehouse_id': warehouseId,
          'stock_item_id': stockItemId,
          'remaining': remaining ? 1 : 0,
        },
      ),
      parseItem: StockBatch.fromJson,
    );
  }

  @override
  Future<Either<Failure, StockMovement>> recordArrival({
    required int stockItemId,
    required int toWarehouseId,
    required String quantity,
    String? unitCost,
    String? notes,
  }) {
    return _record(StockMovementEndpoints.arrivals, <String, dynamic>{
      'stock_item_id': stockItemId,
      'to_warehouse_id': toWarehouseId,
      'quantity': quantity,
      // **Omitted, never sent as null.** An absent key is «لم يُسجّل سعرها» — the layer opens at
      // `0.000` and stays in the uncosted queue; a null would be a claim about the price.
      'unit_cost': ?unitCost,
      'notes': ?notes,
    });
  }

  @override
  Future<Either<Failure, StockMovement>> recordTransfer({
    required int stockItemId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required String quantity,
    String? notes,
  }) {
    return _record(StockMovementEndpoints.transfers, <String, dynamic>{
      'stock_item_id': stockItemId,
      'from_warehouse_id': fromWarehouseId,
      'to_warehouse_id': toWarehouseId,
      'quantity': quantity,
      'notes': ?notes,
    });
  }

  @override
  Future<Either<Failure, StockMovement>> recordAdjustment({
    required int stockItemId,
    required int warehouseId,
    required String quantity,
    required bool isIncrease,
    String? unitCost,
    String? notes,
  }) {
    return _record(StockMovementEndpoints.adjustments, <String, dynamic>{
      'stock_item_id': stockItemId,
      'warehouse_id': warehouseId,
      'quantity': quantity,
      // The backend's own enum. The one place the app spells one of its values, because a
      // direction has to exist before any movement is loaded.
      'direction': isIncrease ? 'increase' : 'decrease',
      // Required by the API on an increase, ignored on a decrease. Which of the two this is has
      // already been decided in [RecordStockMovement] — a decrease arrives here with null.
      'unit_cost': ?unitCost,
      // **`notes` is required on both directions** (`min:3`), and this used to be
      // `if (notes != null && notes.isNotEmpty)` — a guard that silently dropped a field the
      // server demands. The sheet validates it, so the refusal was only ever one bypass away.
      'notes': ?notes,
    });
  }

  Future<Either<Failure, StockMovement>> _record(String path, Map<String, dynamic> body) {
    return safeRequest<StockMovement>(
      () => _dio.post(path, data: body),
      parse: (data) => StockMovement.fromJson(data as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> _body(String name, WarehouseType type, String? location) => {
    'name': name,
    'type': _wire(type),
    if (location != null && location.isNotEmpty) 'location': location,
  };

  /// The enum's wire value. Spelt here rather than read off a label, because a warehouse is
  /// created before any has been loaded to copy a value from.
  String _wire(WarehouseType type) => switch (type) {
    WarehouseType.main => 'main',
    WarehouseType.operational => 'operational',
    WarehouseType.showroom => 'showroom',
    // Never sent: the form offers the three the server knows. Kept total so a case added to
    // the enum tomorrow is a compile error here rather than a 422 in front of a storekeeper.
    WarehouseType.unknown => 'operational',
  };
}
