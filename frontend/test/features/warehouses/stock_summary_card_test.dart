import 'package:dayaa/features/warehouses/models/warehouse_stock_summary.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card that answers «كم عندي في هذا المخزن؟» before anybody scrolls.
///
/// Its job is to make three things readable at arm's length: the total, how many sizes it is
/// spread over, and how much of the shelf is asking for attention. The bar is the only graphic,
/// and it is only ever a part-to-whole of the line count — **never colour alone**: every segment
/// has a word and a number beside it, because a red bar nobody can name is decoration.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(WarehouseStockSummary summary) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: StockSummaryCard(summary: summary)),
    ),
  );

  const full = WarehouseStockSummary(
    totalLines: 24,
    totalQuantity: '12450.000',
    lowStockCount: 4,
    outOfStockCount: 2,
    healthyCount: 18,
  );

  testWidgets('the total is the one big number, grouped', (tester) async {
    // Arrange
    await tester.pumpWidget(host(full));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('12,450'), findsOneWidget);
    expect(find.text('إجمالي القطع'), findsOneWidget);
  });

  testWidgets('the number of sizes is said too, because pieces alone are not a shelf', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(full));

    // Act
    await tester.pumpAndSettle();

    // Assert — a warehouse holding six sizes of one bag is a small warehouse, however many
    // thousands of bags that is
    expect(find.text('24 صنفاً'), findsOneWidget);
  });

  testWidgets('every segment of the bar is named and counted', (tester) async {
    // Arrange
    await tester.pumpWidget(host(full));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('18 سليم'), findsOneWidget);
    expect(find.text('4 تحت الحد'), findsOneWidget);
    expect(find.text('2 نافد'), findsOneWidget);
  });

  testWidgets('a segment with nothing in it is left out rather than drawn at zero', (
    tester,
  ) async {
    // Arrange — everything is fine in this warehouse, and «0 نافد» is a reassurance nobody asked
    // for taking space from the two numbers that matter
    const healthy = WarehouseStockSummary(
      totalLines: 5,
      totalQuantity: '900.000',
      healthyCount: 5,
    );
    await tester.pumpWidget(host(healthy));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('5 سليم'), findsOneWidget);
    expect(find.textContaining('نافد'), findsNothing);
    expect(find.textContaining('تحت الحد'), findsNothing);
  });

  testWidgets('an empty warehouse gets no card at all', (tester) async {
    // Arrange — the list below already says «لا توجد أرصدة في هذا المخزن بعد», and a header
    // repeating it over a bar of nothing is the same sentence twice
    const empty = WarehouseStockSummary(totalLines: 0, totalQuantity: '0.000');
    await tester.pumpWidget(host(empty));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إجمالي القطع'), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
