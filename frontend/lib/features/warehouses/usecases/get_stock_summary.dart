import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';

/// One warehouse counted rather than listed — the numbers above the shelves.
class GetStockSummary {
  const GetStockSummary(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, WarehouseStockSummary>> call(int warehouseId) =>
      _repository.stockSummary(warehouseId);
}
