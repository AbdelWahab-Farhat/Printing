import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:dayaa/features/cities/repositories/city_repository.dart';
import 'package:dayaa/features/cities/usecases/get_cities.dart';
import 'package:dayaa/features/orders/presentation/widgets/destination_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Choosing a place off the delivery map.
///
/// One list, two questions. An order asks «إلى أين نوصّلها؟», and our own branches are a real
/// answer to it — picking «إستلام مكتب(قرجي)» *is* how an order becomes a collection. A
/// customer's shop asks «أين يقع هذا المحل؟», and a branch of ours is not an answer to that at
/// all. `deliveryOnly` is the whole of the difference.
///
/// Arrange - Act - Assert throughout.
class _MockCityRepository extends Mock implements CityRepository {}

void main() {
  late _MockCityRepository repository;

  const tripoli = City(id: 1, name: 'طرابلس', isRegionRequired: true, deliveryPrice: '15.00');
  const office = City(
    id: 2,
    name: 'إستلام مكتب(قرجي)',
    isRegionRequired: false,
    fulfilmentType: FulfilmentType.officePickup,
    deliveryPrice: '0.00',
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockCityRepository();

    when(
      () => repository.cities(
        search: any(named: 'search'),
        isRegionRequired: any(named: 'isRegionRequired'),
        hasPrice: any(named: 'hasPrice'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<City>(
          // The branches sort first on the real map, which is exactly why a filter that only
          // looked at the first row would pass a test that used any other order.
          items: [office, tripoli],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
        ),
      ),
    );

    sl.registerFactory<CitiesCubit>(() => CitiesCubit(getCities: GetCities(repository)));
  });

  tearDown(Injector.reset);

  /// A screen with one button on it, standing in for whichever form opens the sheet.
  Widget host({required bool deliveryOnly, void Function(City?)? onPicked}) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final city = await showCityPicker(
                  context: context,
                  deliveryOnly: deliveryOnly,
                );
                onPicked?.call(city);
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('an order is offered our branches alongside the cities', (tester) async {
    // Arrange
    await tester.pumpWidget(host(deliveryOnly: false));

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert — collecting in person is picked from this same list, so removing the branches
    // would leave an order with no way to say it is being collected.
    expect(find.text('إستلام مكتب(قرجي)'), findsOneWidget);
    expect(find.text('طرابلس'), findsOneWidget);
  });

  testWidgets('a shop is offered only real places', (tester) async {
    // Arrange
    await tester.pumpWidget(host(deliveryOnly: true));

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert — «هذا المحل يقع في: إستلام مكتب(قرجي)» is a sentence with no meaning, and the
    // surest way to stop it being recorded is to not offer it.
    expect(find.text('إستلام مكتب(قرجي)'), findsNothing);
    expect(find.text('طرابلس'), findsOneWidget);
  });

  testWidgets('the delivery rate is shown to an order and not to a shop', (tester) async {
    // Arrange — the rate lands on the order the moment the city is picked, so it belongs on
    // screen before the tap. Recording where a shop *is* costs nothing, and a price beside that
    // question is an answer to a question nobody asked.
    await tester.pumpWidget(host(deliveryOnly: false));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('15.00 د.ل'), findsOneWidget);

    // Act — the same city, asked about as a shop's address.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(deliveryOnly: true));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('15.00 د.ل'), findsNothing);
  });

  testWidgets('picking a city hands the whole city back', (tester) async {
    // Arrange
    City? picked;
    await tester.pumpWidget(host(deliveryOnly: true, onPicked: (city) => picked = city));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('طرابلس'));
    await tester.pumpAndSettle();

    // Assert — the whole city, not an id: the tile that opened this shows a name, and
    // `hasRegions` decides whether the neighbourhood tile appears beside it at all.
    expect(picked, tripoli);
  });
}
