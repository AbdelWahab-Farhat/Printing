import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';

/// Adds a material, or edits one that exists.
///
/// One use case for both, because the rule they share is worth stating once: the name is
/// **trimmed before it travels**, and here that matters more than it does anywhere else in the
/// app. A material's name is copied onto every size under it and `(name, width, height)` is what
/// identifies a shelf — so «كيس شحن » saved with its trailing space would file a second pile
/// beside the first, identical on screen and separate in every balance.
///
/// An emptied description is passed through as null rather than as `''`, so clearing the box
/// clears the field instead of storing a blank string that reads as a description on every
/// screen that tests it for emptiness.
class SaveStockItemGroup {
  const SaveStockItemGroup(this._repository);

  final StockItemGroupRepository _repository;

  Future<Either<Failure, StockItemGroup>> call({
    int? groupId,
    required String name,
    required StockUnit defaultUnit,
    String? description,
    bool isActive = true,
  }) {
    final trimmedName = name.trim();
    final trimmedDescription = description?.trim();
    final cleanedDescription =
        (trimmedDescription == null || trimmedDescription.isEmpty) ? null : trimmedDescription;

    return groupId == null
        ? _repository.create(
            name: trimmedName,
            defaultUnit: defaultUnit,
            description: cleanedDescription,
            isActive: isActive,
          )
        : _repository.update(
            groupId,
            name: trimmedName,
            defaultUnit: defaultUnit,
            description: cleanedDescription,
            isActive: isActive,
          );
  }
}
