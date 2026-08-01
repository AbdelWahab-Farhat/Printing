import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/products/models/new_product.dart';
import 'package:printing/features/products/models/product.dart';

/// Reading the catalogue, stated without saying how.
abstract interface class ProductRepository {
  /// One page of products, in catalogue order.
  ///
  /// [search] matches the name or the slug — the API's rule, not one re-implemented here. It
  /// does **not** match the pricing unit: "كيلو" finds nothing, which is why [pricingUnit]
  /// exists as a filter of its own rather than as something to type.
  ///
  /// [pricingUnit] is `piece` or `kilogram`; [isActive] left null returns both active and
  /// inactive products.
  Future<Either<Failure, Paginated<Product>>> products({
    String? search,
    String? category,
    String? pricingUnit,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  });

  /// One product with everything on it — every variant, every price break, every photo.
  Future<Either<Failure, Product>> product(int productId);

  /// Adds a product to the catalogue, and answers with the one the server stored.
  ///
  /// The answer matters: it carries the `code` the server allocated, which is the name staff
  /// will use for this bag from now on. Nothing the app made up is returned here.
  Future<Either<Failure, Product>> create(NewProduct product);
}
