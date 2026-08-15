import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';

/// Declares what the warehouse counts a product in.
///
/// **A correction, not a conversion.** The numbers on the shelves do not change: they were
/// correct in their own unit before this ran and they are correct after it. What changes is what
/// that unit is called, from here on and retroactively — the server rewrites every warehouse
/// balance and every cost batch for the product's variants in one transaction, so the product,
/// its shelves and its costing can never be found disagreeing about it.
///
/// Independent of `pricing_unit`, which keeps meaning what the customer is charged by. A bag
/// bought in by the kilo and sold by the piece has both, and neither is derived from the other.
class SetProductStockUnit {
  const SetProductStockUnit(this._repository);

  final ProductRepository _repository;

  /// Answers with the product refreshed, which is what the calling screen should show.
  Future<Either<Failure, Product>> call(int productId, PricingUnit unit) =>
      _repository.setStockUnit(productId, unit);
}
