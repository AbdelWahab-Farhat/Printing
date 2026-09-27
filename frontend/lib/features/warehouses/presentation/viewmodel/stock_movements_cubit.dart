import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_movements.dart';

/// The ledger — every movement, newest first, optionally narrowed to one warehouse.
///
/// Read-only: a row here is written by the recording sheet and never edited afterwards, which
/// is what makes the ledger add up to the balances beside it.
class StockMovementsCubit extends PagedCubit<StockMovement> {
  StockMovementsCubit({
    required GetStockMovements getMovements,
    this.warehouseId,
    this.stockItemId,
    this.orderId,
  }) : _getMovements = getMovements;

  final GetStockMovements _getMovements;

  /// One warehouse's movements, counting both ends of a transfer — or null for all of them.
  final int? warehouseId;

  /// One shelf's movements — «كل ما حدث لهذا الصنف». Combines with [warehouseId], which is what
  /// a shelf's own history is: this pile, in this place.
  ///
  /// **The pile, not one product's share of it.** Two catalogue rows can draw on it, and the
  /// rows that explain its balance are all of them together.
  final int? stockItemId;

  /// One order's movements — «ماذا أخذت هذه الطلبية من المخزن». Which rows those are is the
  /// server's call, and it is narrower than every row carrying the order's number.
  final int? orderId;

  @override
  Object identityOf(StockMovement item) => item.id;

  @override
  Future<Either<Failure, Paginated<StockMovement>>> fetchPage({String? search, required int page}) {
    return _getMovements(warehouseId: warehouseId, stockItemId: stockItemId, orderId: orderId, page: page);
  }
}

typedef StockMovementsState = PagedState<StockMovement>;
typedef StockMovementsInitial = PagedInitial<StockMovement>;
typedef StockMovementsLoading = PagedLoading<StockMovement>;
typedef StockMovementsLoaded = PagedLoaded<StockMovement>;
typedef StockMovementsFailure = PagedFailure<StockMovement>;
