import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// Removes one photograph from a product — and the file from storage.
///
/// **Nothing offers to undo this**, and that is not an oversight: the row is soft-deleted like
/// every other record in this app, but the stored file is removed for real, so a restored row
/// would point at nothing. See `ProductImage` on the server.
///
/// The server refuses to remove the last one, which is the rule that keeps «الصورة مطلوبة» true
/// for the whole of a product's life rather than only at the moment it is created.
class DeleteProductImage {
  const DeleteProductImage(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, String>> call(int productId, int imageId) =>
      _repository.deleteImage(productId, imageId);
}
