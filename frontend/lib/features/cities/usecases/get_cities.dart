import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';

/// One page of the delivery map.
///
/// A use case is one verb and one `call`. It looks thin next to the repository today, and that
/// is fine — it is the place a business rule goes when one appears ("hide cities with no
/// price from the customer app"), so the rule lands in one testable class instead of being
/// copied into every Cubit that lists cities.
class GetCities {
  const GetCities(this._repository);

  final CityRepository _repository;

  Future<Either<Failure, Paginated<City>>> call({
    String? search,
    bool? isRegionRequired,
    bool? hasPrice,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.cities(
      search: search,
      isRegionRequired: isRegionRequired,
      hasPrice: hasPrice,
      page: page,
      perPage: perPage,
    );
  }
}
