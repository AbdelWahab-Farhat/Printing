import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/widgets/city_card.dart';
import 'package:dayaa/features/cities/presentation/widgets/region_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What one row of the delivery map tells somebody quoting a customer, and where it leads.
///
/// The card never animates, so nothing here needs `pumpAndSettle` — and nothing here may
/// introduce a reason for it.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget card) {
    return ScreenUtilInit(
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
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  const tripoli = City(
    id: 3,
    name: 'طرابلس',
    isRegionRequired: true,
    deliveryPrice: '15',
    darbBranch: 'زناتة، طرابلس',
    regionsCount: 50,
  );

  const office = City(
    id: 1,
    name: 'إستلام مكتب(قرجي)',
    isRegionRequired: false,
    fulfilmentType: FulfilmentType.officePickup,
    deliveryPrice: '0',
    regionsCount: 0,
  );

  group('CityCard', () {
    testWidgets('a city carries its name, its regions, its branch and its price', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(host(const CityCard(city: tripoli)));

      // Act — nothing to do; the card is at rest.

      // Assert — the four facts the row exists to hold, and the pin that says it is a place we
      // drive to rather than a counter.
      expect(find.text('طرابلس'), findsOneWidget);
      expect(find.text('50 منطقة · زناتة، طرابلس'), findsOneWidget);
      expect(find.text('15 د.ل'), findsOneWidget);
      expect(find.byIcon(AppIcons.mapPin), findsOneWidget);
    });

    testWidgets('a branch is free, says so, and is drawn as a shop not a pin', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(host(const CityCard(city: office)));

      // Act

      // Assert
      expect(find.text('مجاني'), findsOneWidget);
      expect(find.text('استلام ذاتي — بدون توصيل'), findsOneWidget);
      expect(find.byIcon(AppIcons.officePickup), findsOneWidget);
      expect(find.byIcon(AppIcons.mapPin), findsNothing);
    });

    testWidgets('a city with no agreed rate says so in words, never as a zero', (
      tester,
    ) async {
      // Arrange — null delivery price: nobody has agreed a rate, which is not free.
      const unpriced = City(
        id: 8,
        name: 'زلطن',
        isRegionRequired: false,
        regionsCount: 0,
      );

      // Act
      await tester.pumpWidget(host(const CityCard(city: unpriced)));

      // Assert
      expect(find.text('لم يُحدد'), findsOneWidget);
      expect(find.text('0 د.ل'), findsNothing);
    });

    testWidgets('tapping a city with regions opens them', (tester) async {
      // Arrange
      var opened = 0;
      await tester.pumpWidget(host(CityCard(city: tripoli, onTap: () => opened++)));

      // Act
      await tester.tap(find.text('طرابلس'));
      await tester.pump();

      // Assert — and the chevron was there to say the row leads somewhere.
      expect(opened, 1);
      expect(find.byIcon(AppIcons.forward), findsOneWidget);
    });

    testWidgets('a row with no regions does not lead to an empty screen', (tester) async {
      // Arrange — a branch has no regions, so tapping it must do nothing at all.
      var opened = 0;
      await tester.pumpWidget(host(CityCard(city: office, onTap: () => opened++)));

      // Act
      await tester.tap(find.text('إستلام مكتب(قرجي)'));
      await tester.pump();

      // Assert
      expect(opened, isZero);
      expect(find.byIcon(AppIcons.forward), findsNothing);
    });
  });

  testWidgets('a long name on a narrow phone truncates rather than overflowing', (
    tester,
  ) async {
    // Arrange — the smallest screen this app is built for, and the longest row on the map:
    // everything on the card competing for one line. A `RenderFlex` overflow throws here, so
    // the assertion is that pumping succeeds at all.
    tester.view
      ..physicalSize = const Size(320 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const long = City(
      id: 4,
      name: 'ضواحي طرابلس الجنوبية الشرقية',
      isRegionRequired: true,
      deliveryPrice: '2000',
      darbBranch: 'عين زارة، طرابلس، ليبيا',
      regionsCount: 160,
    );

    // Act
    await tester.pumpWidget(host(CityCard(city: long, onTap: () {})));

    // Assert — the name is on screen, on one line, and the pill it must not push off the end
    // is still there beside it.
    expect(find.text('ضواحي طرابلس الجنوبية الشرقية'), findsOneWidget);
    expect(find.text('2,000 د.ل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RegionCard', () {
    testWidgets('a region shows its درب branch and zone code, and no price', (
      tester,
    ) async {
      // Arrange — a region carries no price of its own; delivery is priced per city.
      const region = Region(
        id: 9,
        cityId: 3,
        name: 'سوق الجمعة',
        code: 's18',
        darbBranch: 'زناتة',
      );

      // Act
      await tester.pumpWidget(host(const RegionCard(region: region)));

      // Assert
      expect(find.text('سوق الجمعة'), findsOneWidget);
      expect(find.text('فرع زناتة'), findsOneWidget);
      expect(find.text('s18'), findsOneWidget);
      expect(find.textContaining('د.ل'), findsNothing);
    });

    testWidgets('a region with no code shows no pill, rather than an empty one', (
      tester,
    ) async {
      // Arrange — the code is شركة درب's, so a region they have not coded has none.
      const region = Region(id: 11, cityId: 3, name: 'زناتة');

      // Act
      await tester.pumpWidget(host(const RegionCard(region: region)));

      // Assert — the name, and nothing else on the row.
      expect(find.text('زناتة'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('a region is the end of the map, so it leads nowhere', (tester) async {
      // Arrange
      const region = Region(id: 11, cityId: 3, name: 'زناتة');

      // Act
      await tester.pumpWidget(host(const RegionCard(region: region)));

      // Assert
      expect(find.byIcon(AppIcons.forward), findsNothing);
    });
  });
}
