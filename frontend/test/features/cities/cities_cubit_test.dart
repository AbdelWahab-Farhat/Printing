import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/domain/entities/city.dart';
import 'package:printing/features/cities/domain/repositories/city_repository.dart';
import 'package:printing/features/cities/domain/usecases/get_cities.dart';
import 'package:printing/features/cities/domain/usecases/get_city_regions.dart';
import 'package:printing/features/cities/presentation/viewmodel/cities_cubit.dart';

/// How a ViewModel is tested here: the repository is faked, nothing touches Dio, and the
/// assertions are on the sequence of states the screen would have rendered.
///
/// This is exactly what the layering buys — the Cubit depends on an abstract
/// [CityRepository], so a fake is one line and no HTTP client is ever constructed.
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

  setUp(() {
    repository = _MockCityRepository();
    cubit = CitiesCubit(
      getCities: GetCities(repository),
      getCityRegions: GetCityRegions(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    blocTest<CitiesCubit, CitiesState>(
      'goes loading then loaded when the repository answers',
      setUp: () {
        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => Right(pageOf([office, tripoli])));
      },
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CitiesState.loading(),
        isA<CitiesLoaded>().having((s) => s.page.items, 'items', [office, tripoli]),
      ],
    );

    blocTest<CitiesCubit, CitiesState>(
      'surfaces the failure the repository returned, not a generic one',
      setUp: () {
        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.forbidden(message: FailureMessages.forbidden)),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CitiesState.loading(),
        const CitiesState.failure(Failure.forbidden(message: FailureMessages.forbidden)),
      ],
    );
  });

  group('loadMore', () {
    blocTest<CitiesCubit, CitiesState>(
      'appends the next page and keeps what was already on screen',
      setUp: () {
        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => Right(pageOf([office], lastPage: 2)));

        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: 2,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => Right(pageOf([tripoli], currentPage: 2, lastPage: 2)),
        );
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
      setUp: () {
        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => Right(pageOf([office])));
      },
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
        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: 1,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => Right(pageOf([office], lastPage: 2)));

        when(
          () => repository.cities(
            search: any(named: 'search'),
            isRegionRequired: any(named: 'isRegionRequired'),
            hasPrice: any(named: 'hasPrice'),
            page: 2,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
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

  group('selectCity', () {
    test('skips the request entirely for a city that has no regions', () async {
      await cubit.selectCity(office);

      expect(cubit.regions.state, const RegionsState.loaded([]));
      verifyNever(
        () => repository.regions(
          any(),
          search: any(named: 'search'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      );
    });

    test('loads the regions of a city that requires one', () async {
      const region = Region(id: 9, cityId: 3, name: 'سوق الجمعة', code: 's18');

      when(
        () => repository.regions(
          3,
          search: any(named: 'search'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          Paginated<Region>(
            items: [region],
            meta: PageMeta(currentPage: 1, perPage: 50, lastPage: 1, total: 1),
          ),
        ),
      );

      await cubit.selectCity(tripoli);

      expect(cubit.regions.state, const RegionsState.loaded([region]));
    });
  });
}
