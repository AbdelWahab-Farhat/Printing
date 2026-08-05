import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:printing/features/warehouses/usecases/set_low_stock_threshold.dart';

/// The shelves of one warehouse.
///
/// **About one warehouse, so the id is a construction argument** rather than something the
/// Cubit is told afterwards — the same shape the regions and designs screens use.
class WarehouseStocksCubit extends PagedCubit<WarehouseStock> {
  WarehouseStocksCubit({
    required this.warehouseId,
    required GetWarehouseStocks getStocks,
    required SetLowStockThreshold setThreshold,
  }) : _getStocks = getStocks,
       _setThreshold = setThreshold;

  final int warehouseId;
  final GetWarehouseStocks _getStocks;
  final SetLowStockThreshold _setThreshold;

  /// `true` narrows the list to the shelves asking to be refilled — the question this screen is
  /// opened for on a busy morning. `null` shows everything.
  bool? lowStockOnly;

  @override
  Future<Either<Failure, Paginated<WarehouseStock>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The endpoint has no text search: a shelf is found by scrolling a list of sizes, not by
    // typing one. `search` is accepted by the base class and deliberately unused here.
    return _getStocks(warehouseId, lowStock: lowStockOnly, page: page);
  }

  Future<void> filterByLowStock(bool? next) async {
    if (next == lowStockOnly) return;

    lowStockOnly = next;
    await load();
  }

  /// Sets or clears the alert level on one shelf, then re-reads: the line's own `is_low_stock`
  /// is the server's answer, and a locally patched row would disagree with it immediately.
  Future<Failure?> setThreshold(WarehouseStock stock, String? threshold) async {
    final result = await _setThreshold(warehouseId, stock.id, threshold: threshold);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure == null) await refresh();

    return failure;
  }
}

typedef WarehouseStocksState = PagedState<WarehouseStock>;
typedef WarehouseStocksInitial = PagedInitial<WarehouseStock>;
typedef WarehouseStocksLoading = PagedLoading<WarehouseStock>;
typedef WarehouseStocksLoaded = PagedLoaded<WarehouseStock>;
typedef WarehouseStocksFailure = PagedFailure<WarehouseStock>;
