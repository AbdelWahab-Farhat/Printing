import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/repositories/product_repository.dart';

/// One product with everything on it — every size, every price break, every photo.
///
/// Fetched rather than taken from the row that was tapped, and that is the point of the screen
/// existing: the list endpoint is free to send a lighter product one day, and a detail screen
/// built on whatever the list happened to carry would quietly lose half its content when it did.
class GetProduct {
  const GetProduct(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, Product>> call(int productId) => _repository.product(productId);
}
