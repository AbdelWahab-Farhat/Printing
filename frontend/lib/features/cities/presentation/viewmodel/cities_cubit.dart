import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/usecases/get_cities.dart';

/// The delivery map's ViewModel.
///
/// The debounce, the out-of-order guard, appending pages and keeping the list when a page fails
/// all come from [PagedCubit] — this Cubit used to carry its own copy of all four, written
/// before that class existed. What is left is the one thing that is about cities: which use case
/// fetches them.
///
/// **The regions of a city are no longer loaded here.** They were, as a second stream feeding a
/// dropdown beside the list; regions now have a screen of their own, so they have a Cubit of
/// their own — see `CityRegionsCubit`.
class CitiesCubit extends PagedCubit<City> {
  CitiesCubit({required GetCities getCities}) : _getCities = getCities;

  final GetCities _getCities;

  @override
  Future<Either<Failure, Paginated<City>>> fetchPage({
    String? search,
    required int page,
  }) {
    return _getCities(search: search, page: page);
  }
}

/// The state this screen switches on. A name for `PagedState<City>`, so the view reads as a
/// cities screen while there is one implementation behind every list in the app.
typedef CitiesState = PagedState<City>;
typedef CitiesInitial = PagedInitial<City>;
typedef CitiesLoading = PagedLoading<City>;
typedef CitiesLoaded = PagedLoaded<City>;
typedef CitiesFailure = PagedFailure<City>;
