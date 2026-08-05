import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';

/// What sits on one warehouse's shelves.
class GetWarehouseStocks {
  const GetWarehouseStocks(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<WarehouseStock>>> call(
    int warehouseId, {
    bool? lowStock,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.stocks(warehouseId, lowStock: lowStock, page: page, perPage: perPage);
  }
}
