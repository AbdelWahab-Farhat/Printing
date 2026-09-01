import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// One page of المخازن.
class GetWarehouses {
  const GetWarehouses(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Paginated<Warehouse>>> call({
    String? search,
    WarehouseType? type,
    int page = 1,
    int perPage = 20,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
    // silently finds nothing.
    return _repository.warehouses(
      search: search?.trim(),
      type: type,
      page: page,
      perPage: perPage,
    );
  }
}
