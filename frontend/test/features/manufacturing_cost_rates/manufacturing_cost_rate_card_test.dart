import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/widgets/manufacturing_cost_rate_card.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One rate on the list: what kind of cost, what it applies to, and how much.
///
/// **The rung is the thing this row exists to say.** Three rates for «عمالة» that differ only in
/// what they are pinned to are three identical lines otherwise, and editing the wrong one is how
/// a workshop-wide default quietly becomes one product's number.
///
/// Two more the row has to get right:
///
///   * a size arrives from the server as the bare dimensions — `'25*35'`, with nothing to say
///     whose they are — so it is prefixed rather than dropped into a column of names;
///   * a «خسارة تلف» rate is stored, listed, and then **never read** by anything. A row that said
///     nothing about that is a number somebody believes is being charged.
///
/// Arrange - Act - Assert throughout.
void main() {
  ManufacturingCostRate rate({
    ArrivalRef? product,
    RateVariant? variant,
    ManufacturingCostType costType = ManufacturingCostType.labor,
    String costTypeLabel = 'عمالة',
    String ratePerUnit = '3.500',
    bool isActive = true,
  }) => ManufacturingCostRate(
    id: 1,
    product: product,
    productVariant: variant,
    costType: costType,
    costTypeLabel: costTypeLabel,
    ratePerUnit: ratePerUnit,
    isActive: isActive,
  );

  /// The same frame the app boots into: ScreenUtil at the reference design size, Arabic, RTL.
  Widget host(Widget child) => ScreenUtilInit(
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
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );

  /// A manager's card: every control the row can offer is on it.
  Widget managed(ManufacturingCostRate line) => host(
    ManufacturingCostRateCard(
      rate: line,
      onTap: () {},
      onToggleActive: (_) {},
      onDelete: () {},
    ),
  );

  group('the rung', () {
    testWidgets('a rate with neither reference says «افتراضي»', (tester) async {
      // Arrange
      final line = rate();

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert — the word for «everything without something narrower», said rather than implied
      // by an empty space where the other rows have a name.
      expect(find.text('افتراضي'), findsOneWidget);
    });

    testWidgets('a product-wide rate is named by the product', (tester) async {
      // Arrange
      final line = rate(product: const ArrivalRef(id: 3, name: 'كيس ورقي'));

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert
      expect(find.text('كيس ورقي'), findsOneWidget);
    });

    testWidgets('a size is prefixed, because the server sends the bare dimensions', (
      tester,
    ) async {
      // Arrange
      final line = rate(variant: const RateVariant(id: 11, label: '25*35'));

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert — «25*35» alone in a column of names reads as noise, not as a rung.
      expect(find.text('مقاس 25*35'), findsOneWidget);
    });
  });

  group('what it costs', () {
    testWidgets('the rate loses the padding the database added', (tester) async {
      // Arrange — the server stores three decimals whatever was typed.
      final line = rate(ratePerUnit: '3.500');

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert — string surgery, so `0.850` can never reach a screen as `0.8500000000000001`.
      expect(find.text('3.5'), findsOneWidget);
      expect(find.text('3.500'), findsNothing);
    });

    testWidgets('the kind of cost is the server\'s own word', (tester) async {
      // Arrange — a kind added on the server still reads right, because nothing here maps it.
      final line = rate(
        costType: ManufacturingCostType.machineRuntime,
        costTypeLabel: 'تشغيل آلة',
      );

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert
      expect(find.text('تشغيل آلة'), findsOneWidget);
    });
  });

  group('whether it applies', () {
    testWidgets('a stopped rate says so beside what it applies to', (tester) async {
      // Arrange
      final line = rate(isActive: false);

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert — the row keeps its colour: «لم يعد يُطبَّق» is not «خطأ».
      expect(find.text('افتراضي · موقوف'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('a scrap-loss rate warns that nothing ever reads it', (tester) async {
      // Arrange — the API accepts one and then never consults it: a scrap loss is priced from
      // the FIFO cost of the stock actually written off.
      final line = rate(
        costType: ManufacturingCostType.scrapLoss,
        costTypeLabel: 'خسارة تلف',
      );

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert
      expect(find.text('لا يُطبَّق'), findsOneWidget);
    });

    testWidgets('an ordinary rate carries no such warning', (tester) async {
      // Arrange
      final line = rate();

      // Act
      await tester.pumpWidget(managed(line));
      await tester.pump();

      // Assert
      expect(find.text('لا يُطبَّق'), findsNothing);
    });
  });

  testWidgets('a reader gets no switch and no bin', (tester) async {
    // Arrange — the server refuses either way; this is what keeps a control that would fail off
    // the screen in the first place.
    final line = rate();

    // Act
    await tester.pumpWidget(host(ManufacturingCostRateCard(rate: line)));
    await tester.pump();

    // Assert
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('افتراضي'), findsOneWidget);
  });
}
