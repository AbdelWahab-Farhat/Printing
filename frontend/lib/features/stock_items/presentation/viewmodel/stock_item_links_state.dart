part of 'stock_item_links_cubit.dart';

/// What the links section can be.
@freezed
sealed class StockItemLinksState with _$StockItemLinksState {
  const factory StockItemLinksState.initial() = StockItemLinksInitial;

  const factory StockItemLinksState.loading() = StockItemLinksLoading;

  /// The sizes the server says draw on this material, and the selection on top of them.
  ///
  /// [selected] is null until somebody has actually picked — which is the difference between «لم
  /// يُلمس» and «اختير لا شيء», and the whole reason an untouched form does not rewrite links.
  const factory StockItemLinksState.loaded(
    List<StockItemVariantRef> variants, {
    Set<int>? selected,
  }) = StockItemLinksLoaded;

  /// The links could not be read. **The form is still usable** — the fields are its subject and
  /// they are all local — but the section refuses to offer a picker it cannot seed, because a
  /// selection made from an empty list would unlink everything on save.
  const factory StockItemLinksState.failure(Failure failure) = StockItemLinksFailure;
}

extension StockItemLinksStateX on StockItemLinksState {
  /// What is ticked right now: the picked set if there is one, otherwise what the server sent.
  Set<int> get current => switch (this) {
    StockItemLinksLoaded(:final variants, :final selected) =>
      selected ?? variants.map((v) => v.id).toSet(),
    _ => const <int>{},
  };

  /// What to send with the save, or null when nothing was picked and nothing should be sent.
  Set<int>? get pending => switch (this) {
    StockItemLinksLoaded(:final selected) => selected,
    _ => null,
  };

  /// Whether the picker may be opened. Refused on a failed read for the reason above.
  bool get isReady => this is StockItemLinksLoaded;

  bool get isLoading => this is StockItemLinksLoading || this is StockItemLinksInitial;
}
