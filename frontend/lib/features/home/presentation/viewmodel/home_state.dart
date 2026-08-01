part of 'home_cubit.dart';

/// Everything the home screen can be, and nothing it cannot.
///
/// A union rather than one class with `isLoading`, `failure` and `summary` all nullable: that
/// shape permits "loading, and also failed, and also has numbers", which has no rendering — and
/// is exactly how a spinner ends up spinning forever on top of an error nobody can see.
@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;

  /// First load: there is nothing on screen worth keeping, so the skeleton takes the page.
  const factory HomeState.loading() = HomeLoading;

  const factory HomeState.loaded({
    required AuthUser user,
    required HomeSummary summary,

    /// A refresh is running over numbers that are already on screen. Part of `loaded` rather
    /// than a case of its own, precisely because the screen keeps rendering throughout.
    @Default(false) bool isRefreshing,
  }) = HomeLoaded;

  const factory HomeState.failure(Failure failure) = HomeFailure;
}
