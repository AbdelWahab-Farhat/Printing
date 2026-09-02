import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What one line cost to make, under what the customer is being charged for it.
///
/// **Four figures, all four null until the line reaches «قيد الطباعة», and null draws nothing.**
/// A `0.00` on an unstarted line says the bags cost nothing to make; even the honest «لم يُحتسب
/// بعد» is wrong here, because it would be printed once per line on a screen whose subject is
/// what the customer pays — the order's own cost section says it once, in words.
///
/// **A part with no rate behind it is left out, not zeroed.** The server resolves the rates one
/// cost type at a time and skips a type nothing applies to, so a line costed for labour but not
/// for overhead has two figures and not three.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
  Widget host(Widget child) {
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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  OrderItem line({
    String? materialCost,
    String? laborCost,
    String? overheadCost,
    String? cogs,
    String? unitMaterialCost,
    String? stockUnitLabel,
  }) => OrderItem(
    id: 11,
    productId: 1,
    productVariantId: 12,
    productName: 'كيس شحن',
    variantLabel: '25*35',
    pricingUnitLabel: 'قطعة',
    quantity: '300.000',
    unitPrice: '1.550',
    lineTotal: '465.00',
    materialCost: materialCost,
    laborCost: laborCost,
    overheadCost: overheadCost,
    cogs: cogs,
    unitMaterialCost: unitMaterialCost,
    stockUnitLabel: stockUnitLabel,
  );

  testWidgets('a line nobody has printed yet draws nothing at all', (tester) async {
    // Arrange — all four null, which is every line before the press runs.
    await tester.pumpWidget(host(OrderLineCosts(item: line())));

    // Act - Assert
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('an uncosted line is never given a cost of zero', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderLineCosts(item: line())));

    // Act - Assert — «التكلفة ٠٫٠٠» is a claim about the line, and it is a false one.
    expect(find.textContaining('0.00'), findsNothing);
    expect(find.textContaining('التكلفة'), findsNothing);
  });

  testWidgets('a costed line says what it cost, split the way the server split it', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(
            materialCost: '80.00',
            laborCost: '30.00',
            overheadCost: '10.00',
            cogs: '120.00',
          ),
        ),
      ),
    );

    // Act - Assert — one quiet line, the four figures as the server sent them.
    expect(
      find.text('التكلفة 120.00 — مواد 80.00 · عمالة 30.00 · مصاريف 10.00'),
      findsOneWidget,
    );
  });

  testWidgets('a cost type with no rate behind it is left out, not shown as zero', (
    tester,
  ) async {
    // Arrange — no overhead rate applied to this product, which the server expresses by
    // skipping the type rather than posting nothing against it.
    await tester.pumpWidget(
      host(OrderLineCosts(item: line(materialCost: '80.00', laborCost: '30.00', cogs: '110.00'))),
    );

    // Act - Assert
    expect(find.text('التكلفة 110.00 — مواد 80.00 · عمالة 30.00'), findsOneWidget);
    expect(find.textContaining('مصاريف'), findsNothing);
  });

  testWidgets('a total with no breakdown still says the total', (tester) async {
    // Arrange — the sum is a column of its own on the server, so it can arrive without the
    // parts. Better a figure with no split than no figure.
    await tester.pumpWidget(host(OrderLineCosts(item: line(cogs: '120.00'))));

    // Act - Assert
    expect(find.text('التكلفة 120.00'), findsOneWidget);
  });

  testWidgets('nothing here is added up on the phone', (tester) async {
    // Arrange — the parts are summed from the lines and the total is a cached column, and the
    // two are allowed to disagree. What is drawn is what arrived.
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(
            materialCost: '80.00',
            laborCost: '30.00',
            overheadCost: '10.00',
            cogs: '119.99',
          ),
        ),
      ),
    );

    // Act - Assert
    expect(find.textContaining('التكلفة 119.99'), findsOneWidget);
    expect(find.textContaining('120.00'), findsNothing);
  });

  testWidgets('a costed line says what one unit of it cost in material', (tester) async {
    // Arrange — 300 bags at 80.00 of material, which the server divided into 0.267 a bag.
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(
            materialCost: '80.00',
            cogs: '80.00',
            unitMaterialCost: '0.267',
            stockUnitLabel: 'قطعة',
          ),
        ),
      ),
    );

    // Act - Assert — the question «كم تكلفتنا القطعة؟», answered in words on its own line.
    expect(find.text('تكلفة المواد للقطعة 0.267'), findsOneWidget);
  });

  testWidgets('the rate is labelled with the shelf\'s unit, not the one it was sold in', (
    tester,
  ) async {
    // Arrange — sold by the piece, stocked by the kilo: 12.5 kg off the shelf at 8.000 each.
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(
            materialCost: '100.00',
            cogs: '100.00',
            unitMaterialCost: '8.000',
            stockUnitLabel: 'كيلوغرام',
          ),
        ),
      ),
    );

    // Act - Assert — «تكلفة القطعة ٨٫٠٠٠» would be a wrong number, not an imprecise one.
    expect(find.text('تكلفة المواد للكيلوغرام 8.000'), findsOneWidget);
    expect(find.textContaining('للقطعة'), findsNothing);
  });

  testWidgets('a line with no rate behind it draws no second line', (tester) async {
    // Arrange — a total arrived without the split, so there is nothing to divide.
    await tester.pumpWidget(host(OrderLineCosts(item: line(cogs: '120.00'))));

    // Act - Assert
    expect(find.textContaining('تكلفة المواد'), findsNothing);
  });
}
