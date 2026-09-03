import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_line_costs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a وسيط line cost us, under what the customer is charged for it.
///
/// **Two figures, two moments.** `unit_cost` is the catalogue's number copied the day the order
/// was taken — a price agreed with the vendor, known from the first minute. `outsourcing_cost`
/// is what the line came to, written when the vendor handed the job over; before «جاهزة» it is
/// null, because a price agreed is not a cost incurred.
///
/// **And two grants.** The production figures — material, labour, overhead — are drawn for a
/// holder of `reports.pnl.view`; the vendor's figures for a holder of `products.view_cost`. The
/// server omits the vendor's keys without the second grant, so the widget is told which of the
/// two it may draw rather than guessing from the nulls.
///
/// Arrange - Act - Assert throughout.
void main() {
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

  OrderItem line({String? unitCost, String? outsourcingCost, String? cogs}) => OrderItem(
    id: 11,
    productId: 3,
    productVariantId: 12,
    productName: 'كروت بزنس',
    variantLabel: 'قياسي',
    pricingUnitLabel: 'قطعة',
    quantity: '50.000',
    unitPrice: '50.000',
    lineTotal: '2500.00',
    unitCost: unitCost,
    outsourcingCost: outsourcingCost,
    cogs: cogs,
  );

  testWidgets('a line just taken says what the vendor charges per unit', (tester) async {
    // Arrange — nothing has been recognised yet, but the agreed rate is a fact worth reading.
    await tester.pumpWidget(
      host(
        OrderLineCosts(item: line(unitCost: '25.000'), showProduction: false, showOutsourcing: true),
      ),
    );

    // Act - Assert
    expect(find.text('تكلفة المورد للقطعة 25.000'), findsOneWidget);
    expect(find.textContaining('تصنيع خارجي'), findsNothing);
  });

  testWidgets('a line the vendor handed over says what it came to', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(unitCost: '25.000', outsourcingCost: '750.00', cogs: '750.00'),
          showOutsourcing: true,
          showProduction: false,
        ),
      ),
    );

    // Act - Assert
    expect(find.text('تصنيع خارجي 750.00'), findsOneWidget);
    expect(find.text('تكلفة المورد للقطعة 25.000'), findsOneWidget);
  });

  testWidgets('a reader without the vendor grant is shown neither', (tester) async {
    // Arrange — the payload would not carry these for such a reader; the widget must not draw
    // them even when handed a line that does.
    await tester.pumpWidget(
      host(
        OrderLineCosts(
          item: line(unitCost: '25.000', outsourcingCost: '750.00'),
          showProduction: false,
        ),
      ),
    );

    // Act - Assert
    expect(find.textContaining('المورد'), findsNothing);
    expect(find.textContaining('تصنيع خارجي'), findsNothing);
  });

  testWidgets('the production reader sees the vendor\'s share inside the cost line', (
    tester,
  ) async {
    // Arrange — `cogs` folds the outsourcing cost in, so a reader of the cost line is owed the
    // part that explains it.
    await tester.pumpWidget(
      host(OrderLineCosts(item: line(outsourcingCost: '750.00', cogs: '750.00'))),
    );

    // Act - Assert
    expect(find.text('التكلفة 750.00 — تصنيع خارجي 750.00'), findsOneWidget);
  });
}
