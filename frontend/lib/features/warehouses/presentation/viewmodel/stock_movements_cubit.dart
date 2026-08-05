import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/warehouses/models/stock_movement.dart';
import 'package:printing/features/warehouses/usecases/get_stock_movements.dart';

/// The ledger — every movement, newest first, optionally narrowed to one warehouse.
///
/// Read-only: a row here is written by the recording sheet and never edited afterwards, which
/// is what makes the ledger add up to the balances beside it.
class StockMovementsCubit extends PagedCubit<StockMovement> {
  StockMovementsCubit({required GetStockMovements getMovements, this.warehouseId})
    : _getMovements = getMovements;

  final GetStockMovements _getMovements;

  /// One warehouse's movements, counting both ends of a transfer — or null for all of them.
  final int? warehouseId;

  @override
  Future<Either<Failure, Paginated<StockMovement>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getMovements(warehouseId: warehouseId, page: page);
  }
}

typedef StockMovementsState = PagedState<StockMovement>;
typedef StockMovementsInitial = PagedInitial<StockMovement>;
typedef StockMovementsLoading = PagedLoading<StockMovement>;
typedef StockMovementsLoaded = PagedLoaded<StockMovement>;
typedef StockMovementsFailure = PagedFailure<StockMovement>;
