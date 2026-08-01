import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/location/models/place.dart';
import 'package:printing/features/location/presentation/viewmodel/pick_location_cubit.dart';
import 'package:printing/features/location/repositories/geocoding_repository.dart';
import 'package:printing/features/location/usecases/search_places.dart';

/// The search box on the map screen.
///
/// Arrange - Act - Assert throughout.
class _MockGeocodingRepository extends Mock implements GeocodingRepository {}

void main() {
  late _MockGeocodingRepository repository;
  late PickLocationCubit cubit;

  const tripoli = Place(displayName: 'طرابلس، ليبيا', point: LatLng(32.8872, 13.1913));

  setUp(() {
    repository = _MockGeocodingRepository();
    cubit = PickLocationCubit(searchPlaces: SearchPlaces(repository));
  });

  tearDown(() => cubit.close());

  blocTest<PickLocationCubit, PickLocationState>(
    'a search goes searching, then answers',
    setUp: () {
      // Arrange
      when(() => repository.search(any())).thenAnswer((_) async => const Right([tripoli]));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.search('طرابلس'),
    // Assert
    expect: () => [
      const PickLocationState.searching('طرابلس'),
      const PickLocationState.results([tripoli]),
    ],
  );

  blocTest<PickLocationCubit, PickLocationState>(
    'finding nothing is its own state, not an empty list of results',
    setUp: () {
      // Arrange — this is the ordinary answer for a small town, and the screen draws advice and
      // a row of cities for it. `results([])` would draw an empty panel instead.
      when(() => repository.search(any())).thenAnswer((_) async => const Right([]));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.search('قرية صغيرة'),
    // Assert
    expect: () => [
      const PickLocationState.searching('قرية صغيرة'),
      const PickLocationState.noResults('قرية صغيرة'),
    ],
  );

  blocTest<PickLocationCubit, PickLocationState>(
    "the geocoder's own failure is what the screen shows",
    setUp: () {
      // Arrange
      when(() => repository.search(any())).thenAnswer(
        (_) async => const Left(Failure.network(message: 'تعذر الاتصال')),
      );
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.search('طرابلس'),
    // Assert
    expect: () => [
      const PickLocationState.searching('طرابلس'),
      const PickLocationState.searchFailed(Failure.network(message: 'تعذر الاتصال')),
    ],
  );

  test('a slow early search cannot overwrite a fast later one', () async {
    // Arrange — «طر» is sent, then «طرابلس»; the first answers last.
    when(() => repository.search('طر')).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 60),
        () => const Right([Place(displayName: 'طرهونة', point: LatLng(32.4, 13.6))]),
      ),
    );
    when(() => repository.search('طرابلس')).thenAnswer((_) async => const Right([tripoli]));

    // Act
    final slow = cubit.search('طر');
    await cubit.search('طرابلس');
    await slow;

    // Assert — the answer on screen is the one the user last asked for.
    expect(cubit.state, const PickLocationState.results([tripoli]));
  });

  test('a query too short to mean anything never leaves the device', () async {
    // Arrange — one letter matches half the country, and the geocoder's policy forbids a
    // request per keystroke.
    when(() => repository.search(any())).thenAnswer((_) async => const Right([tripoli]));

    // Act
    await cubit.search('ط');

    // Assert
    verifyNever(() => repository.search(any()));
    expect(cubit.state, const PickLocationState.noResults('ط'));
  });

  test('Arabic-Indic digits in a query are normalised before it is sent', () async {
    // Arrange — «شارع ١٠» is a street that exists; the geocoder indexes ASCII numerals.
    when(() => repository.search(any())).thenAnswer((_) async => const Right([tripoli]));

    // Act
    await cubit.search('شارع ١٠');

    // Assert
    verify(() => repository.search('شارع 10')).called(1);
  });

  blocTest<PickLocationCubit, PickLocationState>(
    'picking a result puts the list away',
    setUp: () {
      // Arrange
      when(() => repository.search(any())).thenAnswer((_) async => const Right([tripoli]));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.search('طرابلس');
      cubit.clear();
    },
    // Assert
    expect: () => [
      const PickLocationState.searching('طرابلس'),
      const PickLocationState.results([tripoli]),
      const PickLocationState.idle(),
    ],
  );

  test('a late answer cannot reopen a list the user has dismissed', () async {
    // Arrange — they searched, tapped a result, and started panning the map. The panel must
    // not reappear over it.
    when(() => repository.search(any())).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 40), () => const Right([tripoli])),
    );

    // Act
    final pending = cubit.search('طرابلس');
    cubit.clear();
    await pending;

    // Assert
    expect(cubit.state, const PickLocationState.idle());
  });
}
