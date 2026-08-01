part of 'pick_location_cubit.dart';

/// Everything the search box can be.
///
/// [noResults] is a case of its own rather than `results([])`, and that is the point of the
/// union here: for a small Libyan town, or for a shop name typed where a place name belongs,
/// finding nothing is the *ordinary* answer — not an error and not an empty list to shrug at.
/// The screen answers it with advice and a row of cities, which it could not do if the two
/// looked the same to a `switch`.
@freezed
sealed class PickLocationState with _$PickLocationState {
  /// Nothing searched, or the results were dismissed. The map is all there is.
  const factory PickLocationState.idle() = PickLocationIdle;

  const factory PickLocationState.searching(String term) = PickLocationSearching;

  const factory PickLocationState.results(List<Place> places) = PickLocationResults;

  const factory PickLocationState.noResults(String term) = PickLocationNoResults;

  const factory PickLocationState.searchFailed(Failure failure) = PickLocationSearchFailed;
}

extension PickLocationStateX on PickLocationState {
  bool get isSearching => this is PickLocationSearching;
}
