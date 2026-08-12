import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:printing/features/warehouses/usecases/get_stock_summary.dart';

part 'stock_summary_cubit.freezed.dart';
part 'stock_summary_state.dart';

/// The numbers above the shelves.
///
/// **A Cubit of its own, beside the list rather than inside it.** The list is a `PagedCubit`
/// whose state is a page, and folding a warehouse-wide total into it would mean a summary that
/// changes every time somebody narrows the list — which is exactly what the summary is for
/// *not* doing.
///
/// It also fails on its own. A summary that could not be read leaves the card away and the
/// shelves perfectly usable; taking a working list down over a header would be the worst of the
/// available answers, so [StockSummaryState.failure] carries no message and nothing shows one.
class StockSummaryCubit extends Cubit<StockSummaryState> {
  StockSummaryCubit({required this.warehouseId, required GetStockSummary getSummary})
    : _getSummary = getSummary,
      super(const StockSummaryState.initial());

  final int warehouseId;
  final GetStockSummary _getSummary;

  /// First load: there is nothing on screen worth keeping.
  Future<void> load() async {
    emit(const StockSummaryState.loading());
    await _fetch();
  }

  /// Re-read after something moved — a movement recorded, an alert level set. Whatever is on
  /// screen stays there while the request runs, and survives its failure.
  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    final result = await _getSummary(warehouseId);

    if (isClosed) return;

    emit(
      result.fold(
        // The failure is swallowed on purpose: see the note on the class. A card that cannot
        // say anything true says nothing.
        (_) => state is StockSummaryLoaded ? state : const StockSummaryState.failure(),
        StockSummaryState.loaded,
      ),
    );
  }
}
