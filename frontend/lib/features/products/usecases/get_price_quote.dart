import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/products/models/price_quote.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// "What does this many of this size cost?"
///
/// Thin, with one job of its own: the quantity arrives as the clerk typed it — `٣٠٠` on a Libyan
/// keyboard — and `quantity` on the API is `numeric`, ASCII-only. Converting it here rather than
/// at the field is the same rule [TakeOrder] follows, and it matters more here: this runs on
/// every keystroke, so a quantity that fails to convert is a price that silently never appears.
class GetPriceQuote {
  const GetPriceQuote(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, PriceQuote>> call({
    required int productId,
    required int variantId,
    required String quantity,
  }) {
    return _repository.quote(
      productId: productId,
      variantId: variantId,
      quantity: Validators.toWesternDigits(quantity.trim()).replaceAll(',', '.'),
    );
  }
}
