import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// The ledger, newest first.
class GetStockMovements {
  const GetStockMovements(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<StockMovement>>> call({
    int? warehouseId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.movements(
      warehouseId: warehouseId,
      stockItemId: stockItemId,
      page: page,
      perPage: perPage,
    );
  }
}
