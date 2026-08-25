part of 'stock_item_group_items_cubit.dart';

/// Everything the sizes sheet can be.
///
/// [failure] carries its message, unlike the summary card over the warehouse shelves: that one
/// is a header over a list somebody can still read, and this is the whole sheet. A sheet that
/// went blank would read as «هذه المادة بلا مقاسات», which is a different and much more
/// alarming statement than «تعذّر التحميل».
@freezed
sealed class StockItemGroupItemsState with _$StockItemGroupItemsState {
  const factory StockItemGroupItemsState.initial() = StockItemGroupItemsInitial;

  const factory StockItemGroupItemsState.loading() = StockItemGroupItemsLoading;

  /// The material **and** its sizes: `group.items` is the list, and the rest of the group is
  /// what lets the sheet say what those sizes are counted in.
  const factory StockItemGroupItemsState.loaded(StockItemGroup group) =
      StockItemGroupItemsLoaded;

  const factory StockItemGroupItemsState.failure(Failure failure) =
      StockItemGroupItemsFailure;
}
