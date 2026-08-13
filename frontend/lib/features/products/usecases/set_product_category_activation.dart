import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/repositories/product_category_repository.dart';

/// Stops offering a heading, or offers it again.
///
/// The ordinary way to retire one. It leaves the pickers; every product already under it keeps
/// saying so, because this hides a row rather than retracting what it described.
class SetProductCategoryActivation {
  const SetProductCategoryActivation(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, ProductCategory>> call(int categoryId, {required bool isActive}) =>
      _repository.setActivation(categoryId, isActive: isActive);
}
