import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/data/datasources/city_remote_data_source.dart';
import 'package:printing/features/cities/domain/entities/city.dart';
import 'package:printing/features/cities/domain/repositories/city_repository.dart';

/// Fulfils [CityRepository] from the API, mapping models to entities on the way out.
///
/// The mapping is the whole job: above this line nothing has ever heard of `CityModel`, so the
/// wire format and the app's own vocabulary can drift apart without a migration.
class CityRepositoryImpl implements CityRepository {
  const CityRepositoryImpl(this._remote);

  final CityRemoteDataSource _remote;

  @override
  Future<Either<Failure, Paginated<City>>> cities({
    String? search,
    bool? isRegionRequired,
    bool? hasPrice,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _remote.cities(
      search: search,
      isRegionRequired: isRegionRequired,
      hasPrice: hasPrice,
      page: page,
      perPage: perPage,
    );

    return result.map(
      (page) => Paginated<City>(
        items: page.items.map((model) => model.toEntity()).toList(growable: false),
        meta: page.meta,
      ),
    );
  }

  @override
  Future<Either<Failure, City>> city(int cityId) async {
    final result = await _remote.city(cityId);

    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, Paginated<Region>>> regions(
    int cityId, {
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    final result = await _remote.regions(
      cityId,
      search: search,
      page: page,
      perPage: perPage,
    );

    return result.map(
      (page) => Paginated<Region>(
        items: page.items.map((model) => model.toEntity()).toList(growable: false),
        meta: page.meta,
      ),
    );
  }
}
