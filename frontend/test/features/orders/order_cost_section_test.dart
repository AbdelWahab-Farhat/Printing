import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_cost_section.dart';

/// What the order cost to make, and what is left of the invoice after it.
///
/// **The whole point of these tests is that «لم يُحتسب» never becomes «٠٫٠٠».** Nothing is costed
/// until the order enters «قيد الطباعة» and stock leaves a shelf, and a zero drawn in that gap
/// says something else entirely — that the job was free — about an order nobody has started. Half
/// of what follows exists to keep a `?? '0.00'` from ever being typed into this widget.
///
/// The other half is the rule the money row already keeps: the strings are the server's,
/// subtraction included. A test that asserted `350 - 120 = 230` would be asserting that this
/// widget does arithmetic it must never do.
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

  Order orderWith({String? totalCogs, String? grossProfit}) => Order(
    id: 7,
    code: '7',
    status: OrderStatus.printing,
    statusLabel: 'قيد الطباعة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
    totalCogs: totalCogs,
    grossProfit: grossProfit,
  );

  testWidgets('an order the press has not reached says so in words', (tester) async {
    // Arrange — both figures null, which is every order before «قيد الطباعة».
    await tester.pumpWidget(host(OrderCostSection(order: orderWith())));

    // Act - Assert
    expect(find.textContaining('لم تُحتسب التكلفة بعد'), findsOneWidget);
  });

  testWidgets('a cost nobody has worked out is never drawn as zero', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCostSection(order: orderWith())));

    // Act - Assert — «٠٫٠٠» here would say the job cost us nothing, which is a different claim
    // from «nobody has costed it yet» and the only one of the two that is false.
    expect(find.text('0.00'), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('once the press has run, both figures are on screen under their own names', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCostSection(order: orderWith(totalCogs: '120.00', grossProfit: '230.00'))),
    );

    // Act - Assert
    expect(find.text('تكلفة الإنتاج'), findsOneWidget);
    expect(find.text('120.00'), findsOneWidget);
    expect(find.text('مجمل الربح'), findsOneWidget);
    expect(find.text('230.00'), findsOneWidget);
    expect(find.textContaining('لم تُحتسب'), findsNothing);
  });

  testWidgets('nothing is recomputed — the margin arrives rendered as it was sent', (
    tester,
  ) async {
    // Arrange — a profit that disagrees with `grandTotal - totalCogs`, which is what a figure
    // rounded on the server against unrounded cost produces. The widget must show what it was
    // handed, not what it could work out.
    await tester.pumpWidget(
      host(OrderCostSection(order: orderWith(totalCogs: '120.00', grossProfit: '229.99'))),
    );

    // Act - Assert
    expect(find.text('229.99'), findsOneWidget);
    expect(find.text('230.00'), findsNothing);
  });

  testWidgets('a job that lost money says so, minus sign and all', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCostSection(order: orderWith(totalCogs: '395.00', grossProfit: '-45.00'))),
    );

    // Act
    final profit = tester.widget<Text>(find.text('-45.00'));
    final scheme = Theme.of(tester.element(find.text('-45.00'))).colorScheme;

    // Assert — floored to zero it would read as a job that broke even, which is the one thing
    // somebody looking at this section needs not to be told.
    expect(profit.style?.color, scheme.error);
  });

  testWidgets('a job in profit is not painted in alarm colours', (tester) async {
    // Arrange — every order in green makes the colour mean nothing by the third screen.
    await tester.pumpWidget(
      host(OrderCostSection(order: orderWith(totalCogs: '120.00', grossProfit: '230.00'))),
    );

    // Act
    final profit = tester.widget<Text>(find.text('230.00'));
    final scheme = Theme.of(tester.element(find.text('230.00'))).colorScheme;

    // Assert
    expect(profit.style?.color, isNot(scheme.error));
  });

  testWidgets('a cost with no margin beside it still refuses to invent one', (tester) async {
    // Arrange — the server derives the profit from the cost, so the pair travels together; this
    // is the defensive half, and the answer is words rather than a subtraction done here.
    await tester.pumpWidget(host(OrderCostSection(order: orderWith(totalCogs: '120.00'))));

    // Act - Assert
    expect(find.text('120.00'), findsOneWidget);
    expect(find.text('لم يُحتسب بعد'), findsOneWidget);
    expect(find.text('230.00'), findsNothing);
  });
}
