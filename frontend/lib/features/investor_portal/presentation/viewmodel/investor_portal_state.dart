part of 'investor_portal_cubit.dart';

/// Everything the investor's screen can be, and nothing it cannot.
@freezed
sealed class InvestorPortalState with _$InvestorPortalState {
  const factory InvestorPortalState.initial() = InvestorPortalInitial;

  const factory InvestorPortalState.loading() = InvestorPortalLoading;

  const factory InvestorPortalState.loaded({
    required InvestorPortfolio portfolio,

    /// A refresh running over figures already on screen — part of `loaded` precisely because the
    /// screen keeps rendering throughout.
    @Default(false) bool isRefreshing,
  }) = InvestorPortalLoaded;

  const factory InvestorPortalState.failure(Failure failure) = InvestorPortalFailure;
}
