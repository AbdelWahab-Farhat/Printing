import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';

/// One material **with the sizes filed under it**.
///
/// Its own use case rather than a flag on [GetStockItemGroups], because it answers a different
/// question and is the only thing that can: `/stock-items` cannot be narrowed to a material, so
/// «ما المقاسات الموجودة من كيس الشحن؟» has exactly one endpoint, and this is it.
class GetStockItemGroup {
  const GetStockItemGroup(this._repository);

  final StockItemGroupRepository _repository;

  Future<Either<Failure, StockItemGroup>> call(int groupId) =>
      _repository.group(groupId);
}
