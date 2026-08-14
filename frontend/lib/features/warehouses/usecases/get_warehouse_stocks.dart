import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// What sits on one warehouse's shelves.
class GetWarehouseStocks {
  const GetWarehouseStocks(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<WarehouseStock>>> call(
    int warehouseId, {
    bool? lowStock,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.stocks(
      warehouseId,
      lowStock: lowStock,
      inStock: inStock,
      page: page,
      perPage: perPage,
    );
  }
}
