import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/domain/entities/city.dart';
import 'package:printing/features/cities/domain/usecases/get_cities.dart';
import 'package:printing/features/cities/domain/usecases/get_city_regions.dart';

part 'cities_state.dart';
part 'cities_cubit.freezed.dart';

/// The ViewModel for anything that picks a city.
///
/// It talks to use cases, never to a repository or to Dio, and it holds no `BuildContext` — a
/// Cubit that imports `material.dart` has stopped being testable without a widget tree.
class CitiesCubit extends Cubit<CitiesState> {
  CitiesCubit({required GetCities getCities, required GetCityRegions getCityRegions})
    : _getCities = getCities,
      _getCityRegions = getCityRegions,
      super(const CitiesState.initial());

  final GetCities _getCities;
  final GetCityRegions _getCityRegions;

  /// The regions of the currently chosen city, kept apart from the city list so loading them
  /// never blanks the list behind the dropdown.
  final regions = _RegionsController();

  String? _search;
  Timer? _debounce;

  /// Guards against an out-of-order response: a slow request for "طر" must not overwrite the
  /// results of a later, faster "طرابلس".
  int _requestId = 0;

  Future<void> load({String? search, bool? isRegionRequired, bool? hasPrice}) async {
    _search = search;
    final requestId = ++_requestId;

    emit(const CitiesState.loading());

    final result = await _getCities(
      search: search,
      isRegionRequired: isRegionRequired,
      hasPrice: hasPrice,
    );

    // `isClosed` before every emit: the screen may have been popped while the request was in
    // flight, and emitting into a closed Cubit throws.
    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        CitiesState.failure,
        (page) => CitiesState.loaded(page: page, search: search),
      ),
    );
  }

  /// Typing in the search box. Waits for a pause before hitting the network, so a five-letter
  /// city name is one request instead of five.
  void search(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(load(search: term.trim().isEmpty ? null : term.trim()));
    });
  }

  /// Appends the next page. A no-op when a page is already loading or the last one has been
  /// reached — an infinite list fires its callback far more often than it needs to.
  Future<void> loadMore() async {
    final current = state;
    if (current is! CitiesLoaded) return;
    if (current.isLoadingMore || !current.page.hasMore) return;

    final requestId = ++_requestId;
    emit(current.copyWith(isLoadingMore: true));

    final result = await _getCities(
      search: _search,
      page: current.page.meta.currentPage + 1,
    );

    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        // The already-loaded pages stay on screen; only the "loading more" footer clears.
        // Losing a working list because page 4 failed would be the worse answer.
        (failure) => current.copyWith(isLoadingMore: false),
        (next) => current.copyWith(page: current.page.merge(next), isLoadingMore: false),
      ),
    );
  }

  Future<void> refresh() => load(search: _search);

  /// Loads the regions of [city], or clears them when it needs none — an address form calls
  /// this every time the city dropdown changes.
  Future<void> selectCity(City city) async {
    if (!city.isRegionRequired && (city.regionsCount ?? 0) == 0) {
      regions.emit(const RegionsState.loaded([]));

      return;
    }

    regions.emit(const RegionsState.loading());

    final result = await _getCityRegions(city.id);
    if (isClosed) return;

    regions.emit(
      result.fold(RegionsState.failure, (page) => RegionsState.loaded(page.items)),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();

    return Future.wait([regions.close(), super.close()]).then((_) {});
  }
}

/// A second stream on the same screen, so the region dropdown can be loading while the city
/// list is not. Nested rather than a separate injected Cubit because its lifetime is exactly
/// this one's — there is no screen that wants regions without cities.
class _RegionsController extends Cubit<RegionsState> {
  _RegionsController() : super(const RegionsState.initial());

  @override
  void emit(RegionsState state) {
    if (isClosed) return;
    super.emit(state);
  }
}
