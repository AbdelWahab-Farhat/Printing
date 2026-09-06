import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_batches.dart';
import 'package:dayaa/features/warehouses/usecases/revalue_stock_batch.dart';

/// The cost layers under one shelf, oldest first — the order the next issue draws them in.
///
/// Two instances live on a shelf's screen: one over what [remaining]s, which is what the shelf
/// is worth and what it will be issued at; and one, opened on demand, over the layers already
/// drawn down entirely, which is history and lives behind a fold.
class StockBatchesCubit extends PagedCubit<StockBatch> {
  StockBatchesCubit({
    required GetStockBatches getBatches,
    required RevalueStockBatch revalueBatch,
    required this.warehouseId,
    required this.stockItemId,
    this.remaining = true,
  }) : _getBatches = getBatches,
       _revalueBatch = revalueBatch;

  final GetStockBatches _getBatches;
  final RevalueStockBatch _revalueBatch;

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

  /// Corrects one layer's price, and answers with the refusal when there is one.
  ///
  /// **A whole-layer correction is patched in place**: the endpoint answers with the layer as it
  /// now stands, which is the row this list is showing — re-reading would be a second request for
  /// an answer already in hand.
  ///
  /// **A partial one re-reads, and that is not the general rule being bent.** Repricing part of a
  /// layer splits it: the repriced quantity stays on this row and the remainder moves onto a row
  /// whose id the server has just minted. Patching the parent alone would leave a shelf whose
  /// layers no longer add up to the balance printed above them — stock the app can no longer
  /// account for — so this is the case the app genuinely cannot answer for itself.
  ///
  /// The split is read off the answer rather than off what was asked for: a quantity typed to
  /// exactly what was left splits nothing, and a colleague's order drawing on the same shelf
  /// mid-request is another way the number moves.
  Future<Failure?> revalue(
    StockBatch batch, {
    required String unitCost,
    required String reason,
    String? quantity,
  }) async {
    final result = await _revalueBatch(
      batchId: batch.id,
      unitCost: unitCost,
      reason: reason,
      quantity: quantity,
    );

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) return failure;

    final corrected = result.getOrElse(() => batch);

    if (thousandths(corrected.quantityRemaining) < thousandths(batch.quantityRemaining)) {
      await refresh();

      return null;
    }

    replace(corrected);

    return null;
  }
}

typedef StockBatchesState = PagedState<StockBatch>;
typedef StockBatchesLoaded = PagedLoaded<StockBatch>;
