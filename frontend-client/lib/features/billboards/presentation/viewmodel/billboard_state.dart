part of 'billboard_cubit.dart';

/// Everything the carousel can be.
@freezed
sealed class BillboardState with _$BillboardState {
  const factory BillboardState.loading() = BillboardLoading;

  /// **An empty list is a perfectly good answer**, and it is not a failure: the shop is simply
  /// not running a campaign. The carousel takes no height at all rather than drawing an empty
  /// box the customer has to scroll past.
  const factory BillboardState.loaded(List<Billboard> billboards) = BillboardLoaded;

  const factory BillboardState.failure(Failure failure) = BillboardFailure;
}

extension BillboardStateX on BillboardState {
  /// Whether the carousel should occupy any of the screen at all.
  bool get hasAnything => switch (this) {
    BillboardLoaded(:final billboards) => billboards.isNotEmpty,
    _ => false,
  };

  List<Billboard> get billboards => switch (this) {
    BillboardLoaded(:final billboards) => billboards,
    _ => const <Billboard>[],
  };
}
