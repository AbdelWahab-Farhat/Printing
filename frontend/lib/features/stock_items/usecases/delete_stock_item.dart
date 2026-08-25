import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// Removes a shelf from the list.
///
/// **Only one that nothing is using.** The server refuses while any warehouse still holds a
/// quantity of it, and refuses again while any product size still draws on it — the first is
/// answered by squaring the count or moving the stock, the second by re-pointing the sizes, and
/// neither is a decision this app makes for the storekeeper. Both refusals arrive in Arabic
/// under `errors.stock_item` and are shown as sent.
class DeleteStockItem {
  const DeleteStockItem(this._repository);

  final StockItemRepository _repository;

  Future<Either<Failure, String>> call(int stockItemId) => _repository.delete(stockItemId);
}
