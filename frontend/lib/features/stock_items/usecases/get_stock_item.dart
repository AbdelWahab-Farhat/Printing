import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// One shelf on its own — the only call that carries `variants_count` outside the list, which is
/// how a screen opened straight from a deep link learns whether anything draws on it.
class GetStockItem {
  const GetStockItem(this._repository);

  final StockItemRepository _repository;

  Future<Either<Failure, StockItem>> call(int stockItemId) => _repository.item(stockItemId);
}
