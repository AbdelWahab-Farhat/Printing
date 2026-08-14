import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// One warehouse counted rather than listed — the numbers above the shelves.
class GetStockSummary {
  const GetStockSummary(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, WarehouseStockSummary>> call(int warehouseId) =>
      _repository.stockSummary(warehouseId);
}
