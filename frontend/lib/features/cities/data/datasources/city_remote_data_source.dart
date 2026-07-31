import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/cities/data/models/city_model.dart';

/// The only place that knows cities are fetched over HTTP.
///
/// Query parameters are built here rather than passed down as a ready-made map: the repository
/// speaks in arguments the domain understands (`search`, `page`), and the fact that the API
/// spells one of them `is_region_required` stops at this file.
class CityRemoteDataSource {
  const CityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Either<Failure, Paginated<CityModel>>> cities({
    String? search,
    bool? isRegionRequired,
    bool? hasPrice,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<CityModel>(
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
      parseItem: CityModel.fromJson,
    );
  }

  Future<Either<Failure, CityModel>> city(int cityId) {
    return safeRequest<CityModel>(
      () => _dio.get(CityEndpoints.show(cityId)),
      parse: (data) => CityModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Either<Failure, Paginated<RegionModel>>> regions(
    int cityId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) {
    return safePaginatedRequest<RegionModel>(
      () => _dio.get(
        CityEndpoints.regions(cityId),
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ),
      parseItem: RegionModel.fromJson,
    );
  }
}
