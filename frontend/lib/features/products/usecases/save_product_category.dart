import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';

/// Adds a heading to the catalogue, or edits one that is already on it.
///
/// One use case for both, because the rule they share is the one worth stating: the name is
/// trimmed before it travels. A trailing space makes «أكياس» and «أكياس » two rows the server
/// would accept and nobody could tell apart on screen.
class SaveProductCategory {
  const SaveProductCategory(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, ProductCategory>> call({
    int? categoryId,
    required String name,
    String? description,
    int sortOrder = 0,
    bool isActive = true,
  }) {
    final trimmed = name.trim();

    return categoryId == null
        ? _repository.create(name: trimmed, description: description, sortOrder: sortOrder)
        : _repository.update(
            categoryId,
            name: trimmed,
            description: description,
            sortOrder: sortOrder,
            isActive: isActive,
          );
  }
}
