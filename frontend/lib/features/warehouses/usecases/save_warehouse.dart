import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';

/// Adds a warehouse, or edits one that exists.
///
/// One use case for both, because the rule they share is worth stating once: the name is
/// trimmed before it travels, so «المخزن الرئيسي» and «المخزن الرئيسي » cannot become two
/// places nobody can tell apart on a transfer form.
class SaveWarehouse {
  const SaveWarehouse(this._repository);

  final WarehouseRepository _repository;

  Future<Either<Failure, Warehouse>> call({
    int? warehouseId,
    required String name,
    required WarehouseType type,
    String? location,
  }) {
    final trimmedName = name.trim();
    final trimmedLocation = location?.trim();

    return warehouseId == null
        ? _repository.create(name: trimmedName, type: type, location: trimmedLocation)
        : _repository.update(
            warehouseId,
            name: trimmedName,
            type: type,
            location: trimmedLocation,
          );
  }
}
