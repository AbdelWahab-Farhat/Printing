import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';

/// One page of «أصناف المخزون».
///
/// [widthCm] and [heightCm] are what a shelf picker sends: given a 25*35 variant, offer the
/// 25*35 shelves first. **They narrow, they do not decide** — a 25*35 bag can legitimately be
/// cut from a wider sheet, so whoever calls this with a size must leave a way to drop it.
class GetStockItems {
  const GetStockItems(this._repository);

  final StockItemRepository _repository;

  Future<Either<Failure, Paginated<StockItem>>> call({
    String? search,
    bool? isActive,
    int? widthCm,
    int? heightCm,
    int page = 1,
    int perPage = 20,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space from a paste is a search that
    // silently finds nothing, and the server matches the name with a plain `ILIKE %…%`.
    return _repository.items(
      search: search?.trim(),
      isActive: isActive,
      widthCm: widthCm,
      heightCm: heightCm,
      page: page,
      perPage: perPage,
    );
  }
}
