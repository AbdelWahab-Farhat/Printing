import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';

/// Ask the server what a quantity costs.
///
/// **The one place a price comes from.** Nothing in this app multiplies a unit price by a
/// quantity: the server owns the tier logic, and a second implementation here would be the one
/// that drifts — in front of the customer, on the screen where they decide to buy.
class QuotePrice {
  const QuotePrice(this._repository);

  final CatalogRepository _repository;

  Future<Either<Failure, PriceQuote>> call({
    required int productId,
    required int variantId,
    required String quantity,
  }) => _repository.quote(
    productId: productId,
    variantId: variantId,
    quantity: quantity,
  );
}
