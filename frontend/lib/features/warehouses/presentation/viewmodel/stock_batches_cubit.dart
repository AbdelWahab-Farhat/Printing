import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_batches.dart';

/// The cost layers under one shelf, oldest first — the order the next issue draws them in.
///
/// Two instances live on a shelf's screen: one over what [remaining]s, which is what the shelf
/// is worth and what it will be issued at; and one, opened on demand, over the layers already
/// drawn down entirely, which is history and lives behind a fold.
class StockBatchesCubit extends PagedCubit<StockBatch> {
  StockBatchesCubit({
    required GetStockBatches getBatches,
    required this.warehouseId,
    required this.stockItemId,
    this.remaining = true,
  }) : _getBatches = getBatches;

  final GetStockBatches _getBatches;

  final int warehouseId;
  final int stockItemId;
  final bool remaining;

  @override
  Object identityOf(StockBatch item) => item.id;

  @override
  Future<Either<Failure, Paginated<StockBatch>>> fetchPage({String? search, required int page}) {
    return _getBatches(
      warehouseId: warehouseId,
      stockItemId: stockItemId,
      remaining: remaining,
      page: page,
    );
  }
}

typedef StockBatchesState = PagedState<StockBatch>;
typedef StockBatchesLoaded = PagedLoaded<StockBatch>;
