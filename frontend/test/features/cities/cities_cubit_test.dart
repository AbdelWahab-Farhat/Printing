import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:dayaa/features/cities/repositories/city_repository.dart';
import 'package:dayaa/features/cities/usecases/get_cities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// How a ViewModel is tested here: the repository is faked, nothing touches Dio, and the
/// assertions are on the sequence of states the screen would have rendered.
///
/// This is exactly what the layering buys — the Cubit depends on an abstract
/// [CityRepository], so a fake is one line and no HTTP client is ever constructed.
///
/// Arrange - Act - Assert throughout.
class _MockCityRepository extends Mock implements CityRepository {}

void main() {
  late _MockCityRepository repository;
  late CitiesCubit cubit;

  const tripoli = City(
    id: 3,
    name: 'طرابلس',
    isRegionRequired: true,
    deliveryPrice: '15.00',
    darbBranch: 'زناتة، طرابلس',
    regionsCount: 50,
  );

  const office = City(
    id: 1,
    name: 'إستلام مكتب(قرجي)',
    isRegionRequired: false,
    fulfilmentType: FulfilmentType.officePickup,
    deliveryPrice: '0.00',
    regionsCount: 0,
  );

  Paginated<City> pageOf(List<City> cities, {int currentPage = 1, int lastPage = 1}) {
    return Paginated<City>(
      items: cities,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: cities.length,
      ),
    );
  }

  /// Every page this fake is asked for, whatever the filters.
  void answerWith(Either<Failure, Paginated<City>> result, {int? page}) {
    when(
      () => repository.cities(
        search: any(named: 'search'),
        isRegionRequired: any(named: 'isRegionRequired'),
        hasPrice: any(named: 'hasPrice'),
        page: page ?? any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockCityRepository();
    cubit = CitiesCubit(getCities: GetCities(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    blocTest<CitiesCubit, CitiesState>(
      'goes loading then loaded when the repository answers',
      setUp: () => answerWith(Right(pageOf([office, tripoli]))),
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CitiesState.loading(),
        isA<CitiesLoaded>().having((s) => s.page.items, 'items', [office, tripoli]),
      ],
    );

    blocTest<CitiesCubit, CitiesState>(
      'surfaces the failure the repository returned, not a generic one',
      setUp: () => answerWith(
        const Left(Failure.forbidden(message: FailureMessages.forbidden)),
      ),
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CitiesState.loading(),
        const CitiesState.failure(Failure.forbidden(message: FailureMessages.forbidden)),
      ],
    );

    blocTest<CitiesCubit, CitiesState>(
      'remembers the term, so an empty result can say what found nothing',
      setUp: () => answerWith(Right(pageOf([]))),
      build: () => cubit,
      act: (cubit) => cubit.load(search: 'زوارة'),
      expect: () => [
        const CitiesState.loading(),
        isA<CitiesLoaded>()
            .having((s) => s.page.isEmpty, 'isEmpty', true)
            .having((s) => s.search, 'search', 'زوارة'),
      ],
    );
  });

  group('loadMore', () {
    blocTest<CitiesCubit, CitiesState>(
      'appends the next page and keeps what was already on screen',
      setUp: () {
        answerWith(Right(pageOf([office], lastPage: 2)), page: 1);
        answerWith(Right(pageOf([tripoli], currentPage: 2, lastPage: 2)), page: 2);
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 2, // the first load's loading + loaded, asserted above
      expect: () => [
        isA<CitiesLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<CitiesLoaded>()
            .having((s) => s.page.items, 'items', [office, tripoli])
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );

    blocTest<CitiesCubit, CitiesState>(
      'does nothing on the last page',
      setUp: () => answerWith(Right(pageOf([office]))),
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => <CitiesState>[],
    );

    blocTest<CitiesCubit, CitiesState>(
      'keeps the loaded list when a further page fails',
      setUp: () {
        answerWith(Right(pageOf([office], lastPage: 2)), page: 1);
        answerWith(
          const Left(Failure.network(message: FailureMessages.noConnection)),
          page: 2,
        );
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 3, // loading, loaded, isLoadingMore: true
      expect: () => [
        // Losing a working list because page 2 failed would be the worse answer.
        isA<CitiesLoaded>()
            .having((s) => s.page.items, 'items', [office])
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });
}
