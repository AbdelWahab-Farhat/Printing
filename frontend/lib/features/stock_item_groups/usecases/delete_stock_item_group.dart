import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';

/// Removes a material from the table.
///
/// **Only one nothing points at.** The server refuses while any size is filed under it or any
/// product names it, and says so in Arabic naming both counts — «لا يمكن حذف «كيس شحن» لأن 4
/// صنفاً مخزنياً و 2 منتجاً مرتبط بها». Re-filing those is the answer, and the app does not
/// decide it for anybody: there is no cascade here and there must not be one, because deleting a
/// material that owns shelves would leave piles with no name.
///
/// The counts the refusal quotes include soft-deleted rows, which is why a screen can show
/// «لا أصناف» and the delete still be refused. That is the server being right, not a bug.
class DeleteStockItemGroup {
  const DeleteStockItemGroup(this._repository);

  final StockItemGroupRepository _repository;

  Future<Either<Failure, String>> call(int groupId) => _repository.delete(groupId);
}
