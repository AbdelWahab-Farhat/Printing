import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:dayaa/features/warehouses/usecases/set_low_stock_threshold.dart';

/// The three questions this screen is opened with.
///
/// **[low] and [out] are not degrees of the same thing.** A shelf nobody set an alert level for
/// is outside the low-stock question entirely — the server says so — but it is empty all the
/// same, and «ماذا نفد؟» is the question somebody asks before ordering. Each value maps to the
/// filter the summary counted with, so a button cannot promise a number the list contradicts.
enum StockShelfFilter {
  all,
  low,
  out;

  /// What the server should be asked for `low_stock`. Null means "do not narrow on it".
  bool? get lowStock => this == StockShelfFilter.low ? true : null;

  /// What the server should be asked for `in_stock`.
  bool? get inStock => this == StockShelfFilter.out ? false : null;
}

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

  /// Which of the three the list is showing. Everything, by default.
  StockShelfFilter filter = StockShelfFilter.all;

  @override
  Future<Either<Failure, Paginated<WarehouseStock>>> fetchPage({
    String? search,
    required int page,
  }) {
    // The endpoint has no text search: a shelf is found by scrolling a list of sizes, not by
    // typing one. `search` is accepted by the base class and deliberately unused here.
    return _getStocks(
      warehouseId,
      lowStock: filter.lowStock,
      inStock: filter.inStock,
      page: page,
    );
  }

  Future<void> filterBy(StockShelfFilter next) async {
    if (next == filter) return;

    filter = next;
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
