import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/cities/models/city.dart';
import 'package:printing/features/cities/presentation/viewmodel/city_regions_cubit.dart';
import 'package:printing/features/cities/repositories/city_repository.dart';
import 'package:printing/features/cities/usecases/get_city_regions.dart';

/// The regions screen's ViewModel, with the repository faked and nothing touching Dio.
///
/// Arrange - Act - Assert throughout.
class _MockCityRepository extends Mock implements CityRepository {}

void main() {
  late _MockCityRepository repository;
  late CityRegionsCubit cubit;

  const cityId = 3;

  const soukAlJumaa = Region(
    id: 9,
    cityId: cityId,
    name: 'سوق الجمعة',
    code: 's18',
    darbBranch: 'زناتة',
  );

  const zanata = Region(id: 11, cityId: cityId, name: 'زناتة');

  Paginated<Region> pageOf(
    List<Region> regions, {
    int currentPage = 1,
    int lastPage = 1,
  }) {
    return Paginated<Region>(
      items: regions,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: regions.length,
      ),
    );
  }

  void answerWith(
    Either<Failure, Paginated<Region>> result, {
    int? forCity,
    int? page,
  }) {
    when(
      () => repository.regions(
        forCity ?? any(),
        search: any(named: 'search'),
        page: page ?? any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockCityRepository();
    cubit = CityRegionsCubit(
      cityId: cityId,
      getCityRegions: GetCityRegions(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    blocTest<CityRegionsCubit, CityRegionsState>(
      'goes loading then loaded with the regions of its own city',
      setUp: () => answerWith(Right(pageOf([soukAlJumaa, zanata]))),
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CityRegionsState.loading(),
        isA<CityRegionsLoaded>().having(
          (s) => s.page.items,
          'items',
          [soukAlJumaa, zanata],
        ),
      ],
      verify: (_) {
        // The id is a construction argument, so every request this Cubit makes is about the
        // one city it was built for — including the ones `loadMore` asks for.
        verify(
          () => repository.regions(
            cityId,
            search: any(named: 'search'),
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).called(1);
      },
    );

    blocTest<CityRegionsCubit, CityRegionsState>(
      'surfaces the server\'s own message rather than a generic one',
      setUp: () => answerWith(
        const Left(Failure.forbidden(message: FailureMessages.forbidden)),
      ),
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CityRegionsState.loading(),
        const CityRegionsState.failure(
          Failure.forbidden(message: FailureMessages.forbidden),
        ),
      ],
    );

    blocTest<CityRegionsCubit, CityRegionsState>(
      'a city with no regions is an empty list, not a failure',
      setUp: () => answerWith(Right(pageOf([]))),
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const CityRegionsState.loading(),
        isA<CityRegionsLoaded>().having((s) => s.page.isEmpty, 'isEmpty', true),
      ],
    );
  });

  group('loadMore', () {
    blocTest<CityRegionsCubit, CityRegionsState>(
      'appends the next page, still scoped to the same city',
      setUp: () {
        answerWith(Right(pageOf([soukAlJumaa], lastPage: 2)), forCity: cityId, page: 1);
        answerWith(
          Right(pageOf([zanata], currentPage: 2, lastPage: 2)),
          forCity: cityId,
          page: 2,
        );
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 2,
      expect: () => [
        isA<CityRegionsLoaded>().having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<CityRegionsLoaded>()
            .having((s) => s.page.items, 'items', [soukAlJumaa, zanata])
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );

    blocTest<CityRegionsCubit, CityRegionsState>(
      'keeps the loaded regions when a further page fails',
      setUp: () {
        answerWith(Right(pageOf([soukAlJumaa], lastPage: 2)), forCity: cityId, page: 1);
        answerWith(
          const Left(Failure.network(message: FailureMessages.noConnection)),
          forCity: cityId,
          page: 2,
        );
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      skip: 3,
      expect: () => [
        isA<CityRegionsLoaded>()
            .having((s) => s.page.items, 'items', [soukAlJumaa])
            .having((s) => s.isLoadingMore, 'isLoadingMore', false),
      ],
    );
  });
}
