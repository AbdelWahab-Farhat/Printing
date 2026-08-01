import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';

/// Fulfils [CityRepository] over HTTP.
///
/// The Dio calls live here rather than in a separate data source. With one source of data, the
/// extra class only forwarded. If a local cache ever lands beside the network, *that* is when
/// the split earns its place — and the contract above means nothing else changes when it does.
///
/// Query parameters are assembled here, so the fact that the API spells one of them
/// `is_region_required` never leaves this file.
class CityRepositoryImpl implements CityRepository {
  const CityRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<City>>> cities({
    String? search,
    bool? isRegionRequired,
    bool? hasPrice,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<City>(
      () => _dio.get(
        CityEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string becomes the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isRegionRequired != null) 'is_region_required': isRegionRequired ? 1 : 0,
          if (hasPrice != null) 'has_price': hasPrice ? 1 : 0,
        },
      ),
      parseItem: City.fromJson,
    );
  }

  @override
  Future<Either<Failure, City>> city(int cityId) {
    return safeRequest<City>(
      () => _dio.get(CityEndpoints.show(cityId)),
      parse: (data) => City.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<Region>>> regions(
    int cityId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return safePaginatedRequest<Region>(
      () => _dio.get(
        CityEndpoints.regions(cityId),
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ),
      parseItem: Region.fromJson,
    );
  }
}
