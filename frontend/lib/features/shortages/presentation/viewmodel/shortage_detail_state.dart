part of 'shortage_detail_cubit.dart';

/// Everything the shortage screen can be.
///
/// **Each case carries the shortage it already has**, which is what lets a refusal put the user
/// back on the screen they were reading rather than on a spinner or an error page — and the
/// refusals are the point here: nine of them, each naming a different problem in the server's own
/// Arabic. Only the very first load has nothing to show.
@freezed
sealed class ShortageDetailState with _$ShortageDetailState {
  const factory ShortageDetailState.loading({Shortage? shortage}) = ShortageDetailLoading;

  const factory ShortageDetailState.ready(Shortage shortage) = ShortageDetailReady;

  /// A write is in flight — a status move, an assignment, a supply, or its undo. The shortage
  /// stays on screen and the buttons lock.
  const factory ShortageDetailState.working(Shortage shortage) = ShortageDetailWorking;

  const factory ShortageDetailState.failure(Failure failure, {Shortage? shortage}) =
      ShortageDetailFailure;
}

extension ShortageDetailStateX on ShortageDetailState {
  /// What is on screen, whatever else is happening. Null only before the first read lands.
  Shortage? get shortage => switch (this) {
    ShortageDetailLoading(:final shortage) => shortage,
    ShortageDetailReady(:final shortage) => shortage,
    ShortageDetailWorking(:final shortage) => shortage,
    ShortageDetailFailure(:final shortage) => shortage,
  };

  bool get isWorking => this is ShortageDetailWorking;
}
