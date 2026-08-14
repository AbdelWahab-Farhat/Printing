import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';

/// Puts the picture the catalogue prints above a heading, or takes it off.
///
/// One use case for both, because they are the same decision seen from two sides — «ما صورة هذا
/// التصنيف؟» — and the screen that asks one always offers the other beside it.
///
/// **Setting replaces.** The server deletes the file it replaced: nothing points at a heading's
/// picture the way an order points at a customer's design, so keeping every old one would grow
/// without bound for no reader.
class SetProductCategoryImage {
  const SetProductCategoryImage(this._repository);

  final ProductCategoryRepository _repository;

  Future<Either<Failure, ProductCategory>> call(
    int categoryId, {
    required String path,
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) => _repository.setImage(
    categoryId,
    path: path,
    filename: filename,
    onProgress: onProgress,
  );

  /// Idempotent on the server, so a retry after a dropped connection is free.
  Future<Either<Failure, ProductCategory>> remove(int categoryId) =>
      _repository.removeImage(categoryId);
}
