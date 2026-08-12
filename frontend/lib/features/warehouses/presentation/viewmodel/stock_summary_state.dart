part of 'stock_summary_cubit.dart';

/// Everything the card above the shelves can be.
///
/// [failure] carries no message, which is the whole point of it: the numbers are a header over a
/// working list, and a header that failed should take itself away rather than put an error on
/// top of shelves somebody can still read.
@freezed
sealed class StockSummaryState with _$StockSummaryState {
  const factory StockSummaryState.initial() = StockSummaryInitial;

  const factory StockSummaryState.loading() = StockSummaryLoading;

  const factory StockSummaryState.loaded(WarehouseStockSummary summary) = StockSummaryLoaded;

  const factory StockSummaryState.failure() = StockSummaryFailure;
}
