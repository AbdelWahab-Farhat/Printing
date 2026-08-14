import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// Removes a warehouse from the list.
///
/// **Only one that holds nothing.** The server refuses while any balance line sits in it, and
/// says so in Arabic — moving the stock out is the answer, and the app does not decide that
/// for the storekeeper.
class DeleteWarehouse {
  const DeleteWarehouse(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, String>> call(int warehouseId) => _repository.delete(warehouseId);
}
