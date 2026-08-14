import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';

/// Removes a heading from the catalogue for good.
///
/// **Only for a row that should never have existed** — a typo, a duplicate. The server refuses
/// with 422 the moment any product is recorded under it, and says so in Arabic; the screen shows
/// that message rather than deciding for itself what may be deleted.
class DeleteProductCategory {
  const DeleteProductCategory(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, String>> call(int categoryId) => _repository.delete(categoryId);
}
