import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/location/models/place.dart';
import 'package:printing/features/location/repositories/geocoding_repository.dart';

/// Look up a place by name.
///
/// Two things happen here rather than in the screen, and both are the kind that get forgotten
/// once and then never diagnosed:
///
///   * a query typed in Arabic-Indic digits — «شارع ١٠» — is normalised, because the geocoder
///     indexes ASCII numerals and would answer nothing for a street that exists,
///   * a blank or one-character query never leaves the device. Nominatim's usage policy is
///     explicit that clients must not send a request per keystroke, and a single letter matches
///     half the country anyway.
class SearchPlaces {
  const SearchPlaces(this._repository);

  final GeocodingRepository _repository;

  /// Below this a query is noise, not a search.
  static const int _minimumLength = 2;

  Future<Either<Failure, List<Place>>> call(String query) async {
    final normalised = Validators.toWesternDigits(query.trim());

    if (normalised.length < _minimumLength) return const Right(<Place>[]);

    return _repository.search(normalised);
  }
}
