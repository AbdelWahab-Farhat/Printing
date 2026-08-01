import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';

/// The neighbourhoods inside one city — what the second dropdown in an address form needs.
class GetCityRegions {
  const GetCityRegions(this._repository);

  final CityRepository _repository;

  Future<Either<Failure, Paginated<Region>>> call(
    int cityId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return _repository.regions(cityId, search: search, page: page, perPage: perPage);
  }
}
