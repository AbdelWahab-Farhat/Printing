import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/location/models/place.dart';
import 'package:printing/features/location/usecases/search_places.dart';

part 'pick_location_state.dart';
part 'pick_location_cubit.freezed.dart';

/// The search box on the map screen. It knows nothing about the map itself.
///
/// The camera is not state here, and that is the design: the pin is painted at the centre of the
/// viewport, so the answer is always `mapController.camera.center` and there is no second copy
/// to keep in step. What this Cubit owns is the *search* — a thing that can be in flight, can
/// come back empty, and can fail.
class PickLocationCubit extends Cubit<PickLocationState> {
  PickLocationCubit({required SearchPlaces searchPlaces})
    : _searchPlaces = searchPlaces,
      super(const PickLocationState.idle());

  final SearchPlaces _searchPlaces;

  /// Which request is the current one.
  ///
  /// A slow «طر» must not overwrite the results of a faster «طرابلس» that was typed after it.
  /// A counter rather than a timestamp, because two requests can share a millisecond.
  int _requestId = 0;

  Future<void> search(String term) async {
    final query = term.trim();
    if (query.isEmpty) return clear();

    final id = ++_requestId;
    emit(PickLocationState.searching(query));

    final result = await _searchPlaces(query);

    // The screen may be gone, or a later search may already have answered.
    if (isClosed || id != _requestId) return;

    emit(
      result.fold(
        PickLocationState.searchFailed,
        // Empty is its own case, not `results([])`. For a small Libyan town — or for a shop
        // name typed where a place name belongs — nothing found is the *expected* answer, and
        // the screen draws something completely different for it: advice, and a row of cities.
        (places) => places.isEmpty
            ? PickLocationState.noResults(query)
            : PickLocationState.results(places),
      ),
    );
  }

  /// Puts the result list away — after a result is tapped, or the box is emptied.
  void clear() {
    // Also retires any request still in flight, so a late answer cannot reopen the list over a
    // map the user has already started panning.
    _requestId++;

    if (state is! PickLocationIdle) emit(const PickLocationState.idle());
  }
}
