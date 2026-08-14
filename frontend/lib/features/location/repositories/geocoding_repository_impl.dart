import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/location/models/place.dart';
import 'package:dayaa/features/location/repositories/geocoding_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [GeocodingRepository] against a Nominatim-compatible geocoder.
///
/// **The `Dio` handed to this is a second, separate client, and that is deliberate.** The rule
/// that there is one `Dio` in the app exists so no request silently misses the bearer token —
/// here missing it is the *requirement*. The shared client's `AuthInterceptor` would send this
/// app's Sanctum token to a public server that has no business holding it. See the registration
/// in the injector, which is commented as the exception.
///
/// [safeForeignRequest] and not [safeRequest]: a geocoder answers a bare JSON array, and putting
/// that through our envelope parser would report a perfectly good response as malformed.
class GeocodingRepositoryImpl implements GeocodingRepository {
  const GeocodingRepositoryImpl(this._dio);

  final Dio _dio;

  /// Six is what fits above the keyboard without becoming a list to scroll.
  static const int _limit = 6;

  @override
  Future<Either<Failure, List<Place>>> search(String query) {
    return safeForeignRequest<List<Place>>(
      () => _dio.get<dynamic>(
        '/search',
        queryParameters: <String, dynamic>{
          'q': query,
          'format': 'jsonv2',
          // Without this «الزاوية» comes back from five countries and the right answer is
          // somewhere on page two.
          'countrycodes': 'ly',
          // Most Libyan places carry only an Arabic `name` tag; ask in English and half of them
          // answer with a transliteration nobody recognises.
          'accept-language': 'ar',
          'limit': _limit,
        },
      ),
      // A row that cannot be read is skipped rather than thrown: one malformed result among six
      // must not empty a list the user could have used.
      parse: (body) => body is! List
          ? const <Place>[]
          : body
                .whereType<Map<String, dynamic>>()
                .map(Place.tryFromJson)
                .whereType<Place>()
                .toList(),
    );
  }
}
