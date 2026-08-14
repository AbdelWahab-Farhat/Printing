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
    this.productVariantId,
  }) : _getMovements = getMovements;

  final GetStockMovements _getMovements;

  /// One warehouse's movements, counting both ends of a transfer — or null for all of them.
  final int? warehouseId;

  /// One size's movements — «كل ما حدث لهذا المقاس». Combines with [warehouseId], which is what
  /// a shelf's own history is: this size, in this place.
  final int? productVariantId;

  @override
  Future<Either<Failure, Paginated<StockMovement>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getMovements(
      warehouseId: warehouseId,
      productVariantId: productVariantId,
      page: page,
    );
  }
}

typedef StockMovementsState = PagedState<StockMovement>;
typedef StockMovementsInitial = PagedInitial<StockMovement>;
typedef StockMovementsLoading = PagedLoading<StockMovement>;
typedef StockMovementsLoaded = PagedLoaded<StockMovement>;
typedef StockMovementsFailure = PagedFailure<StockMovement>;
