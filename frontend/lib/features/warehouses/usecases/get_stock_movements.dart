import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';

/// The ledger, newest first.
class GetStockMovements {
  const GetStockMovements(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<StockMovement>>> call({
    int? warehouseId,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.movements(warehouseId: warehouseId, page: page, perPage: perPage);
  }
}
