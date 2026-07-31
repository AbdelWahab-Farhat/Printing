part of 'cities_cubit.dart';

/// Everything the cities screen can be, and nothing it cannot.
///
/// A Freezed union, not a class with `isLoading`, `error` and `cities` all nullable at once.
/// That shape allows `isLoading: true` *and* `error != null` — a state the screen has no
/// sensible rendering for, which is exactly how a spinner ends up stuck on top of an error.
/// Here the compiler refuses to let it be constructed, and `switch` in the view is exhaustive:
/// add a case and every screen stops compiling until it says what to draw.
@freezed
sealed class CitiesState with _$CitiesState {
  const factory CitiesState.initial() = CitiesInitial;

  /// First load — the screen shows a full-page skeleton.
  const factory CitiesState.loading() = CitiesLoading;

  const factory CitiesState.loaded({
    required Paginated<City> page,

    /// A further page is on its way. Kept inside `loaded` rather than as its own case,
    /// because the list stays on screen while it happens.
    @Default(false) bool isLoadingMore,

    /// The search term these results belong to — lets a late response for an old term be
    /// dropped instead of overwriting a newer one.
    String? search,
  }) = CitiesLoaded;

  const factory CitiesState.failure(Failure failure) = CitiesFailure;
}

/// The regions of one city, loaded on demand when a city is chosen.
@freezed
sealed class RegionsState with _$RegionsState {
  const factory RegionsState.initial() = RegionsInitial;

  const factory RegionsState.loading() = RegionsLoading;

  const factory RegionsState.loaded(List<Region> regions) = RegionsLoaded;

  const factory RegionsState.failure(Failure failure) = RegionsFailure;
}
