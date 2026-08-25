import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// Changes what a pile is counted in.
///
/// ⚠️ **It does not convert the balance. It throws it away, and that is the point.** «٢٠٠ كيس»
/// is not «٢٠٠ كيلوغرام»: a quantity is only meaningful in the unit it was measured in, so the
/// server ends it rather than restating it. Every warehouse holding this item is taken to zero by
/// a recorded «تسوية نقص» *before* the unit changes — so the ledger line carries the unit the
/// stock was actually counted in — and only then are the item, its balances and its cost batches
/// restamped. «لماذا اختفى الرصيد؟» stays answerable a year later, by name and by date.
///
/// **Whoever calls this must have asked first, in those words.** Not «سيُعاد تسمية الوحدة» — the
/// balance is gone and the shelves have to be re-counted in the new unit. Getting that sentence
/// wrong loses real stock, and the only control in this app allowed to reach here is
/// `showStockUnitSheet`, which refuses to answer until the confirmation is accepted.
///
/// **Re-picking the unit it already has is a no-op**, server-side: no locks, no movement, no
/// change. Sending it is safe, which is why the sheet may still return a unit the caller does not
/// have to compare.
///
/// A separate use case rather than a flag on [SaveStockItem] for the same reason the API gives it
/// a separate endpoint: everything else on that form is a correction, and this is an act.
class SetStockItemUnit {
  const SetStockItemUnit(this._repository);

  final StockItemRepository _repository;

  Future<Either<Failure, StockItem>> call(int stockItemId, {required StockUnit unit}) =>
      _repository.setUnit(stockItemId, unit: unit);
}
