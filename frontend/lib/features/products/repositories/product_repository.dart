import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/product.dart';

/// Reading the catalogue, stated without saying how.
abstract interface class ProductRepository {
  /// One page of products, newest catalogue order first.
  ///
  /// [search] matches the name or the slug — the API's rule, not one re-implemented here.
  /// [isActive] left null returns both active and inactive products.
  Future<Either<Failure, Paginated<Product>>> products({
    String? search,
    String? category,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  /// One product with everything on it — every variant, every price break, every photo.
  Future<Either<Failure, Product>> product(int productId);
}
