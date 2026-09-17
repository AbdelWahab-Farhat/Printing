part of 'designs_cubit.dart';

/// Everything «تصاميمي» can be.
///
/// **`isBusy` and `lastFailure` sit on the loaded state rather than replacing it**, and that is
/// the shape decision here. Uploading or renaming must not blank the library — a grid that
/// disappears behind a spinner every time somebody edits a caption is a screen that feels
/// broken. So a write keeps the list on screen, dims it, and a failure returns the same list
/// with a message beside it.
@freezed
sealed class DesignsState with _$DesignsState {
  const factory DesignsState.loading() = DesignsLoading;

  const factory DesignsState.loaded(
    List<CustomerDesign> designs, {
    /// A write is in flight. The grid stays, the controls lock.
    @Default(false) bool isBusy,

    /// The last write that failed, cleared by the next state. **Not a `failure` state**: the
    /// library is still perfectly readable, and a rename that failed should not take it away.
    Failure? lastFailure,
  }) = DesignsLoaded;

  /// Only ever the *first* load failing — after that there is a list to keep showing.
  const factory DesignsState.failure(Failure failure) = DesignsFailure;
}

extension DesignsStateX on DesignsState {
  bool get isBusy => switch (this) {
    DesignsLoaded(:final isBusy) => isBusy,
    _ => false,
  };

  bool get isEmpty => switch (this) {
    DesignsLoaded(:final designs) => designs.isEmpty,
    _ => false,
  };
}
