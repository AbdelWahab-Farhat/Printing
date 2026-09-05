import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';

/// Adds a heading to the catalogue, or edits one that is already on it.
///
/// One use case for both, because the rule they share is the one worth stating: the name is
/// trimmed before it travels. A trailing space makes «أكياس» and «أكياس » two rows the server
/// would accept and nobody could tell apart on screen.
class SaveProductCategory {
  const SaveProductCategory(this._repository);

  final ProductCategoryRepository _repository;

  /// [productionMode] is the three-way answer on the sheet — مطبوعة، سادة، أو وسيط. Defaulted
  /// to printed here, the road every order took before the answer existed, so a caller that
  /// says nothing asks the most of the shop rather than the least.
  ///
  /// [isInvestable] is the three-valued answer to «قابل للاستثمار؟» — true, false, or null for
  /// «حسب الرئيسي». [parentId] is where an existing heading is filed and travels with the edit,
  /// because a PUT replaces the whole representation and a heading whose parent is left out of
  /// one becomes a root.
  Future<Either<Failure, ProductCategory>> call({
    int? categoryId,
    required String name,
    String? description,
    int sortOrder = 0,
    bool isActive = true,
    ProductionMode productionMode = ProductionMode.inHouse,
    int? parentId,
    bool? isInvestable,
  }) {
    final trimmed = name.trim();

    return categoryId == null
        ? _repository.create(
            name: trimmed,
            description: description,
            sortOrder: sortOrder,
            productionMode: productionMode,
            isInvestable: isInvestable,
          )
        : _repository.update(
            categoryId,
            name: trimmed,
            description: description,
            sortOrder: sortOrder,
            isActive: isActive,
            productionMode: productionMode,
            parentId: parentId,
            isInvestable: isInvestable,
          );
  }
}
