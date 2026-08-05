import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';

/// Sets the level at which a shelf starts asking to be refilled — or clears it.
///
/// **The only write a balance accepts.** A quantity is never sent: it moves because a movement
/// explains it, in the same transaction, which is what keeps the ledger and the balance one
/// story rather than two.
class SetLowStockThreshold {
  const SetLowStockThreshold(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, WarehouseStock>> call(
    int warehouseId,
    int stockId, {
    String? threshold,
  }) {
    final value = threshold?.trim();

    return _repository.setThreshold(
      warehouseId,
      stockId,
      // An empty box means «لا تنبهني», which is a decision — so it travels as an explicit
      // null rather than as an empty string the API would have to interpret.
      threshold: value == null || value.isEmpty ? null : value,
    );
  }
}
