import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// Adds one photograph to a product.
///
/// **Refuses locally before it sends**, using the same numbers the API enforces — see
/// [ProductImageRules]. A photo off a modern phone camera is routinely over the 5 MB limit, and
/// discovering that after pushing it over a mobile connection costs a minute of somebody's time
/// to learn something knowable instantly. The server refuses it either way; this only decides
/// whether the trip is worth starting.
class UploadProductImage {
  const UploadProductImage(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, ProductImage>> call(
    int productId, {
    required PickedFile image,
    void Function(int sent, int total)? onProgress,
  }) async {
    final refusal = ProductImageRules.reject(image);

    if (refusal != null) {
      // `server`, though no server was asked: it is the refusal the API *would* have given, in
      // the same shape, so the screen shows it the same way and needs no second path. `network`
      // would be a lie about the connection, and 422 is the status this stands in for.
      return Left(Failure.server(message: refusal, statusCode: 422));
    }

    return _repository.uploadImage(productId, image: image, onProgress: onProgress);
  }
}
