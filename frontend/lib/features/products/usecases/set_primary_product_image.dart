import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// Makes one photograph the one the catalogue, the shelves and the order sheets all draw.
///
/// A product has exactly one primary image, so this promotes rather than toggles — there is no
/// «اجعلها ليست الرئيسية», and the API refuses the attempt rather than leaving a product with
/// none.
class SetPrimaryProductImage {
  const SetPrimaryProductImage(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, ProductImage>> call(int productId, int imageId) =>
      _repository.makeImagePrimary(productId, imageId);
}
