import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/stock_item_groups/models/stock_item_group.dart';
import 'package:dayaa/features/stock_item_groups/repositories/stock_item_group_repository.dart';

/// One page of مجموعات الأصناف.
///
/// The search matches the **name only** — not the code — because that is what the endpoint
/// does. Anywhere the screen invites «ابحث عن مادة» rather than «ابحث», that is why.
class GetStockItemGroups {
  const GetStockItemGroups(this._repository);

  final StockItemGroupRepository _repository;

  Future<Either<Failure, Paginated<StockItemGroup>>> call({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
    // silently finds nothing.
    return _repository.groups(
      search: search?.trim(),
      isActive: isActive,
      page: page,
      perPage: perPage,
    );
  }
}
