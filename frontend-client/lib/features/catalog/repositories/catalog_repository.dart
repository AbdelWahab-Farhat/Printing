import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';

/// What the shop sells, and what a quantity of it costs.
abstract interface class CatalogRepository {
  /// One page of the live catalogue.
  ///
  /// **There is no `isActive` argument, and there will not be one.** The server fixes it: a
  /// customer asking for the retired half of the catalogue gets the live one. Nothing this app
  /// sends can reopen what the shop has stopped selling.
  Future<Either<Failure, Paginated<Product>>> products({
    int page,
    String? search,
    int? categoryId,
  });

  /// One product, with its sizes and their price breaks.
  Future<Either<Failure, Product>> product(int id);

  /// The headings, for the filter chips. Never paged — there are a handful.
  Future<Either<Failure, List<ProductCategory>>> categories();

  /// Price a quantity of one size.
  ///
  /// **Asked of the server rather than worked out here**, so the number the customer is shown
  /// and the number written to the order come from the same code. A total computed in this app
  /// would be a second pricing implementation, and the one that drifts is always the one facing
  /// the customer.
  Future<Either<Failure, PriceQuote>> quote({
    required int productId,
    required int variantId,
    required String quantity,
  });
}
