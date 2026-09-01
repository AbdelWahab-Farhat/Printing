import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// The cost layers under one shelf, oldest first.
class GetStockBatches {
  const GetStockBatches(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<StockBatch>>> call({
    required int warehouseId,
    required int stockItemId,
    bool remaining = true,
    int page = 1,
    int perPage = 50,
  }) {
    return _repository.stockBatches(
      warehouseId: warehouseId,
      stockItemId: stockItemId,
      remaining: remaining,
      page: page,
      perPage: perPage,
    );
  }
}
