import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/usecases/get_city_regions.dart';

/// The neighbourhoods inside one city.
///
/// Parameterised by the city, like every other screen that is *about* one record: the id is a
/// construction argument rather than something the Cubit is told afterwards and might be asked
/// for twice with two different answers.
///
/// Everything else — the debounced search, the out-of-order guard, appending pages — is
/// [PagedCubit]'s, because a region list is a searchable paginated list and nothing more.
class CityRegionsCubit extends PagedCubit<Region> {
  CityRegionsCubit({required int cityId, required GetCityRegions getCityRegions})
    : _cityId = cityId,
      _getCityRegions = getCityRegions;

  final int _cityId;
  final GetCityRegions _getCityRegions;

  @override
  Future<Either<Failure, Paginated<Region>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getCityRegions(_cityId, search: search, page: page);
  }
}

/// A name for `PagedState<Region>`, so the view reads as a regions screen.
typedef CityRegionsState = PagedState<Region>;
typedef CityRegionsInitial = PagedInitial<Region>;
typedef CityRegionsLoading = PagedLoading<Region>;
typedef CityRegionsLoaded = PagedLoaded<Region>;
typedef CityRegionsFailure = PagedFailure<Region>;
