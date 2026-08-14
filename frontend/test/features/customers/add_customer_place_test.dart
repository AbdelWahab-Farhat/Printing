import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';
import 'package:dayaa/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:dayaa/features/business_fields/repositories/business_field_repository.dart';
import 'package:dayaa/features/business_fields/usecases/delete_business_field.dart';
import 'package:dayaa/features/business_fields/usecases/get_business_fields.dart';
import 'package:dayaa/features/business_fields/usecases/set_business_field_activation.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/cities_cubit.dart';
import 'package:dayaa/features/cities/presentation/viewmodel/city_regions_cubit.dart';
import 'package:dayaa/features/cities/repositories/city_repository.dart';
import 'package:dayaa/features/cities/usecases/get_cities.dart';
import 'package:dayaa/features/cities/usecases/get_city_regions.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/new_customer.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:dayaa/features/customers/presentation/views/add_customer_page.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/create_customer.dart';
import 'package:dayaa/features/customers/usecases/update_customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «أين يقع هذا المحل؟», as the form asks it.
///
/// The screen used to ask for a latitude and a longitude — first as two boxes to copy out of
/// Google Maps, then as a pin on a real map. Both asked the clerk to *find* a place they can
/// already name. This asks for the name: a city off the delivery map, and the neighbourhood
/// inside it when the city has any.
///
/// Real Cubits and real use cases, fake repositories — so what reaches the API is what this
/// asserts on, not a description of it.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockCityRepository extends Mock implements CityRepository {}

class _MockBusinessFieldRepository extends Mock implements BusinessFieldRepository {}

void main() {
  late _MockCustomerRepository customers;
  late _MockCityRepository cities;
  late _MockBusinessFieldRepository businessFields;

  const tripoli = City(
    id: 3,
    name: 'طرابلس',
    isRegionRequired: true,
    deliveryPrice: '15.00',
    regionsCount: 2,
  );

  // No neighbourhoods at all, which is the common case on this map — and the one that decides
  // whether the second tile is drawn.
  const misrata = City(id: 9, name: 'مصراتة', isRegionRequired: false, deliveryPrice: '30.00');

  const soukAlJumaa = Region(id: 11, cityId: 3, name: 'سوق الجمعة');

  const created = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [],
  );

  setUpAll(() => registerFallbackValue(const NewCustomer(name: '', phone: '')));

  setUp(() async {
    await Injector.reset();

    customers = _MockCustomerRepository();
    cities = _MockCityRepository();
    businessFields = _MockBusinessFieldRepository();

    when(() => customers.create(any())).thenAnswer((_) async => const Right(created));

    when(
      () => cities.cities(
        search: any(named: 'search'),
        isRegionRequired: any(named: 'isRegionRequired'),
        hasPrice: any(named: 'hasPrice'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<City>(
          items: [tripoli, misrata],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 2),
        ),
      ),
    );

    when(
      () => cities.regions(
        any(),
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<Region>(
          items: [soukAlJumaa],
          meta: PageMeta(currentPage: 1, perPage: 50, lastPage: 1, total: 1),
        ),
      ),
    );

    when(
      () => businessFields.fields(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<BusinessField>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );

    sl
      ..registerFactory<AddCustomerCubit>(
        () => AddCustomerCubit(
          createCustomer: CreateCustomer(customers),
          updateCustomer: UpdateCustomer(customers),
        ),
      )
      ..registerFactory<BusinessFieldsCubit>(
        () => BusinessFieldsCubit(
          getBusinessFields: GetBusinessFields(businessFields),
          setActivation: SetBusinessFieldActivation(businessFields),
          deleteBusinessField: DeleteBusinessField(businessFields),
        )..isActive = true,
        instanceName: 'active-only',
      )
      ..registerFactory<CitiesCubit>(() => CitiesCubit(getCities: GetCities(cities)))
      ..registerFactoryParam<CityRegionsCubit, int, void>(
        (cityId, _) => CityRegionsCubit(
          cityId: cityId,
          getCityRegions: GetCityRegions(cities),
        ),
      );
  });

  tearDown(Injector.reset);

  /// A router, not a bare `home:` — the screen leaves through `context.canPop()` on a
  /// successful save, and GoRouter asserts rather than degrades when it is not in the tree.
  Widget host() {
    final router = GoRouter(
      initialLocation: '/customers/new',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('الرئيسية'))),
        GoRoute(path: '/customers/new', builder: (_, _) => const AddCustomerPage()),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  /// A real phone, not the 800×600 the test binding defaults to — this form is taller than
  /// that, and every tap below would land off the render tree.
  void useAPhone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 1600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Fills in the customer and adds one empty shop row.
  Future<void> startAShop(WidgetTester tester) async {
    useAPhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'مطبعة النور');
    await tester.enterText(find.byType(TextFormField).at(1), '0913334444');

    await tester.tap(find.text('إضافة محل'));
    await tester.pumpAndSettle();
  }

  /// Opens the city sheet from the row at [index] and taps [cityName].
  Future<void> pickCity(WidgetTester tester, String cityName, {int index = 0}) async {
    await tester.tap(find.text('المدينة').at(index));
    await tester.pumpAndSettle();
    await tester.tap(find.text(cityName).last);
    await tester.pumpAndSettle();
  }

  /// Presses «إضافة العميل» and lets the success toast run out.
  ///
  /// The toast schedules its own timers, which outlive `pumpAndSettle` — settling only waits
  /// for frames — and a timer still pending when the tree is disposed fails the test with a
  /// message about the toast rather than about the shop being asserted on.
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('إضافة العميل'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  NewCustomerShop sentShop() {
    final sent = verify(() => customers.create(captureAny())).captured.last as NewCustomer;

    return sent.shops!.first;
  }

  testWidgets('the form asks for a city and no longer for coordinates', (tester) async {
    // Arrange
    await startAShop(tester);

    // Assert — the pin is gone from the screen, not merely optional on it.
    expect(find.text('المدينة'), findsOneWidget);
    expect(find.text('مطلوبة'), findsOneWidget);
    expect(find.text('إدخال الإحداثيات يدوياً'), findsNothing);
    expect(find.text('الموقع على الخريطة'), findsNothing);
  });

  testWidgets('a shop with no city refuses to be saved', (tester) async {
    // Arrange — the one field that replaced the pin, so it is the one the row is refused for.
    await startAShop(tester);

    // Act
    await tester.tap(find.text('إضافة العميل'));
    await tester.pumpAndSettle();

    // Assert — refused here, before a round trip that would come back 422 anyway.
    expect(find.text('اختر مدينة المحل'), findsOneWidget);
    verifyNever(() => customers.create(any()));
  });

  testWidgets('the chosen city and region reach the API as ids', (tester) async {
    // Arrange
    await startAShop(tester);
    await tester.enterText(find.byType(TextFormField).at(2), 'فرع سوق الجمعة');

    // Act
    await pickCity(tester, 'طرابلس');
    await tester.tap(find.text('المنطقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سوق الجمعة').last);
    await tester.pumpAndSettle();
    await save(tester);

    // Assert
    final shop = sentShop();
    expect(shop.cityId, 3);
    expect(shop.regionId, 11);
  });

  testWidgets('a city with no neighbourhoods offers no region tile', (tester) async {
    // Arrange — a tile that opens an empty sheet is worse than no tile at all, and
    // `regionsCount` already came down with the list, so this costs no request.
    await startAShop(tester);

    // Act
    await pickCity(tester, 'مصراتة');

    // Assert
    expect(find.text('مصراتة'), findsOneWidget);
    expect(find.text('المنطقة'), findsNothing);
  });

  testWidgets('changing the city drops the region that belonged to the old one', (tester) async {
    // Arrange — «طرابلس / سوق الجمعة», then moved to a city that neighbourhood is not in.
    await startAShop(tester);
    await pickCity(tester, 'طرابلس');
    await tester.tap(find.text('المنطقة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سوق الجمعة').last);
    await tester.pumpAndSettle();

    // Act
    await pickCity(tester, 'مصراتة');
    await tester.enterText(find.byType(TextFormField).at(2), 'الفرع');
    await save(tester);

    // Assert — keeping it would send the server a pair it refuses, and rightly so.
    final shop = sentShop();
    expect(shop.cityId, 9);
    expect(shop.regionId, isNull);
  });

  testWidgets('a second shop starts in the city of the one above it', (tester) async {
    // Arrange — a customer's shops are nearly always in one city, and the value being copied is
    // one the user chose seconds ago on this same screen.
    await startAShop(tester);
    await pickCity(tester, 'طرابلس');

    // Act
    await tester.tap(find.text('إضافة محل آخر'));
    await tester.pumpAndSettle();

    // Assert — inherited, and still one tap from being changed.
    expect(find.text('طرابلس'), findsNWidgets(2));
    expect(find.text('مطلوبة'), findsNothing);
  });
}
