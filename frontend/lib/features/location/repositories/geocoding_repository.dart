import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/location/models/place.dart';

/// Turning a typed place name into points on a map.
///
/// An abstraction over a service that is **not ours**, which is the whole reason it exists as a
/// contract: the tile and search providers are configuration (`GEOCODER_BASE_URL`), because
/// OpenStreetMap's policy allows withdrawing access from commercial users at any time. The day
/// that happens, one implementation changes and nothing above it does.
abstract interface class GeocodingRepository {
  /// Places matching [query], best first, capped by the implementation.
  ///
  /// An empty list is a **successful** answer, and a common one: search a small Libyan town, or
  /// a shop name rather than a place name, and there is genuinely nothing to return. Callers
  /// must render that differently from a failure.
  Future<Either<Failure, List<Place>>> search(String query);
}
