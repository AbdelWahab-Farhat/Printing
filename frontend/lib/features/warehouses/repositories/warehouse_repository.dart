import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
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
  Future<Either<Failure, Paginated<Warehouse>>> warehouses({
    String? search,
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
  /// [productVariantId] narrows it to one size — «كل ما حدث لهذا المقاس»: where it came from,
  /// where it went, and every count that corrected it. The two combine.
  Future<Either<Failure, Paginated<StockMovement>>> movements({
    int? warehouseId,
    int? productVariantId,
    int page = 1,
    int perPage = 20,
  });

  /// Stock arriving from outside — a purchase. No source, because there is none.
  Future<Either<Failure, StockMovement>> recordArrival({
    required int productVariantId,
    required int toWarehouseId,
    required String quantity,
    String? notes,
  });

  /// Stock moving between two of our own places. Both ends required, and the server refuses
  /// the same warehouse twice.
  Future<Either<Failure, StockMovement>> recordTransfer({
    required int productVariantId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required String quantity,
    String? notes,
  });

  /// A count that disagreed with the record. [isIncrease] is which way the correction goes —
  /// the quantity itself is always positive.
  Future<Either<Failure, StockMovement>> recordAdjustment({
    required int productVariantId,
    required int warehouseId,
    required String quantity,
    required bool isIncrease,
    String? notes,
  });
}
