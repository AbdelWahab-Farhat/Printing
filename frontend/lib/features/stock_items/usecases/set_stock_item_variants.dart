import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// Says which product sizes draw on one material — **the whole set, replacing what was there.**
///
/// **The link used to have one writer, and it was the product.** `stock_item_id` lives on a
/// product size, so pointing four sizes across three products at one pile meant saving three
/// products, each save resending prices, tiers and images that nobody doing the pointing had
/// touched — and quietly reverting a price somebody else had just changed.
///
/// **A replacement, not an addition.** What is sent is linked, what was linked and is not sent
/// comes off, and an empty list empties the material deliberately. That is what a multi-select
/// means when it is saved: unticking a box has to do something, and this is the only shape in
/// which it does.
///
/// **A size already drawing on another material is moved, and nothing warns from here.** Past
/// movements do not follow it — a ledger row is keyed on the material, not on the size that
/// caused it — so what changes is only what this size deducts from next. Saying that out loud is
/// the screen's job, by name, before this is called: see `showVariantLinkPicker`.
///
/// A separate use case rather than part of [SaveStockItem], because it is a separate endpoint and
/// a separate act: the form's fields are corrections to one row, and this rewires several others.
class SetStockItemVariants {
  const SetStockItemVariants(this._repository);

  final StockItemRepository _repository;

  Future<Either<Failure, StockItem>> call(int stockItemId, List<int> variantIds) =>
      _repository.setVariants(stockItemId, variantIds);
}
