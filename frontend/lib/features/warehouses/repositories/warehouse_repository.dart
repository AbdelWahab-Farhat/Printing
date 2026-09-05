import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';

/// المخزن, stated without saying how.
///
/// One contract for all three shapes — the places, the shelves and the ledger — because they
/// are one context: a balance only ever changes through a movement, and a screen that showed
/// one without the other would be showing half an answer.
abstract interface class WarehouseRepository {
  /// [type] narrows to one kind of place — «الرئيسي», today, which is the answer a form
  /// asking for a warehouse opens holding. Asked of the server rather than filtered here: the
  /// main store need not sit on the first page, and a client that read one and hoped would name
  /// the wrong shelf in a business with a dozen.
  Future<Either<Failure, Paginated<Warehouse>>> warehouses({
    String? search,
    WarehouseType? type,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, Warehouse>> create({
    required String name,
    required WarehouseType type,
    String? location,
  });

  Future<Either<Failure, Warehouse>> update(
    int warehouseId, {
    required String name,
    required WarehouseType type,
    String? location,
  });

  /// The server refuses one that still holds stock — move it out first. Answers with the
  /// server's own message.
  Future<Either<Failure, String>> delete(int warehouseId);

  /// What sits on the shelves of one warehouse.
  ///
  /// [lowStock] narrows to the lines asking to be refilled, which is the question this screen
  /// is opened for on a busy morning. [inStock] `false` narrows to the ones that have run out —
  /// **a different question**, because a size nobody set an alert level for is empty all the
  /// same, and the server leaves it out of the low-stock answer entirely.
  Future<Either<Failure, Paginated<WarehouseStock>>> stocks(
    int warehouseId, {
    bool? lowStock,
    bool? inStock,
    int page = 1,
    int perPage = 20,
  });

  /// The same shelves counted rather than listed: how many sizes, how much altogether, and how
  /// many lines are low, empty, or fine.
  ///
  /// Always the whole warehouse. A summary that narrowed along with the list could not tell
  /// anyone what they had narrowed from.
  Future<Either<Failure, WarehouseStockSummary>> stockSummary(int warehouseId);

  /// Sets — or clears, with null — the level at which a shelf starts asking to be refilled.
  /// **The only write a balance line accepts.**
  Future<Either<Failure, WarehouseStock>> setThreshold(
    int warehouseId,
    int stockId, {
    String? threshold,
  });

  /// The ledger, newest first.
  ///
  /// [warehouseId] narrows it to one place, counting both ends of a transfer.
  /// [stockItemId] narrows it to one shelf — «كل ما حدث لهذا الصنف»: where it came from, where
  /// it went, and every count that corrected it. The two combine.
  ///
  /// **One shelf, not one product's size.** Two catalogue rows can draw on the same pile, so
  /// this feed answers for the pile — which is the only reading that explains the number on it.
  Future<Either<Failure, Paginated<StockMovement>>> movements({
    int? warehouseId,
    int? stockItemId,
    int page = 1,
    int perPage = 20,
  });

  /// The cost layers under one shelf, oldest first — the order the next issue draws them in.
  ///
  /// [remaining] true (the default) lists what is still on the shelf; false lists the layers
  /// that have been drawn down entirely, which is history and lives behind a fold.
  Future<Either<Failure, Paginated<StockBatch>>> stockBatches({
    required int warehouseId,
    required int stockItemId,
    bool remaining = true,
    int page = 1,
    int perPage = 50,
  });

  /// Stock arriving from outside — a purchase. No source, because there is none.
  ///
  /// [unitCost] opens the cost layer this arrival creates. **Null is «لم يُسجّل سعرها», not
  /// zero**: the key is left out of the payload entirely, the layer opens at `0.000`, and it
  /// stays findable in the uncosted queue for someone to price later. Sending `'0'` would say a
  /// person decided the goods are worth nothing, and take them out of that queue for good.
  Future<Either<Failure, StockMovement>> recordArrival({
    required int stockItemId,
    required int toWarehouseId,
    required String quantity,
    String? unitCost,
    String? notes,
  });

  /// Stock moving between two of our own places. Both ends required, and the server refuses
  /// the same warehouse twice.
  ///
  /// **No cost.** A transfer relocates the layers that exist at the prices they already hold —
  /// there is no new layer for a price to attach to, so the argument does not exist to be
  /// passed by mistake.
  Future<Either<Failure, StockMovement>> recordTransfer({
    required int stockItemId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required String quantity,
    String? notes,
  });

  /// A count that disagreed with the record. [isIncrease] is which way the correction goes —
  /// the quantity itself is always positive.
  ///
  /// [unitCost] is **required by the API on an increase and ignored on a decrease**: stock found
  /// on a shelf opens a brand-new cost layer, and unlike an arrival a stocktake has no vendor
  /// document to fall back on. A decrease only ever consumes layers that already have prices.
  Future<Either<Failure, StockMovement>> recordAdjustment({
    required int stockItemId,
    required int warehouseId,
    required String quantity,
    required bool isIncrease,
    String? unitCost,
    String? adjustmentReason,
    String? notes,
  });
}
