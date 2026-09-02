import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/stock_batch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One cost layer under a balance, and what a shelf is worth read off all of them.
///
/// Arrange - Act - Assert throughout.
void main() {
  StockBatch batch({
    int id = 1,
    String unitCost = '3.500',
    String received = '1000.000',
    String remaining = '300.000',
    bool uncosted = false,
    DateTime? receivedAt,
  }) => StockBatch(
    id: id,
    warehouseId: 1,
    stockItemId: 7,
    unitCost: unitCost,
    quantityReceived: received,
    quantityRemaining: remaining,
    quantityConsumed: '0.000',
    unit: 'piece',
    unitLabel: 'قطعة',
    sourceType: 'purchase_arrival',
    sourceTypeLabel: 'توريد',
    receivedAt: receivedAt ?? DateTime(2026, 8, 31),
    isUncosted: uncosted,
  );

  Widget host(Widget row) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: row),
    ),
  );

  testWidgets('the first layer says its price, what is left of it, and that it goes next', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(StockBatchRow(batch: batch(), position: 1, isNext: true)));

    // Act
    await tester.pump();

    // Assert — the price with its trailing zeros dropped, the value rounded to the dinar
    expect(find.text('توريد · 31 أغسطس 2026'), findsOneWidget);
    expect(find.text('3.5 د.ل/قطعة'), findsOneWidget);
    expect(find.text('متبقي 300 من 1,000'), findsOneWidget);
    expect(find.text('1,050 د.ل'), findsOneWidget);
    expect(find.text('التالية للصرف'), findsOneWidget);
  });

  testWidgets('a layer nobody priced says so, and shows no value', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(StockBatchRow(batch: batch(unitCost: '0.000', uncosted: true), position: 2)),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('بلا تكلفة'), findsOneWidget);
    expect(find.textContaining('د.ل'), findsNothing);
    expect(find.text('التالية للصرف'), findsNothing);
  });

  group('the valuation', () {
    test('sums what remains at each layer\'s price and averages by what remains', () {
      // Arrange — 300 @ 3.500 and 100 @ 5.000: 1,050 + 500 over 400 units
      final layers = [
        batch(id: 1, remaining: '300.000', unitCost: '3.500', receivedAt: DateTime(2026, 8, 31)),
        batch(id: 2, remaining: '100.000', unitCost: '5.000', receivedAt: DateTime(2026, 9, 2)),
      ];

      // Act
      final valuation = ShelfValuation.of(layers);

      // Assert
      expect(valuation.totalValue, '1550.00');
      expect(valuation.averageUnitCost, '3.875');
      expect(valuation.layerCount, 2);
      expect(valuation.oldestReceivedAt, DateTime(2026, 8, 31));
    });

    test('drops the average as soon as any of the shelf is unpriced', () {
      // Arrange
      final layers = [
        batch(id: 1, remaining: '300.000', unitCost: '3.500'),
        batch(id: 2, remaining: '100.000', unitCost: '0.000', uncosted: true),
      ];

      // Act
      final valuation = ShelfValuation.of(layers);

      // Assert — the total it can vouch for stays; the average that would count zeros goes
      expect(valuation.totalValue, '1050.00');
      expect(valuation.averageUnitCost, isNull);
      expect(valuation.uncostedQuantity, '100.000');
      expect(valuation.hasUncosted, isTrue);
      expect(valuation.isWhollyUncosted, isFalse);
    });

    test('a spent layer weighs nothing, and an empty shelf is empty', () {
      // Arrange
      final layers = [batch(id: 1, remaining: '0.000')];

      // Act
      final valuation = ShelfValuation.of(layers);

      // Assert
      expect(valuation.isEmpty, isTrue);
      expect(valuation.averageUnitCost, isNull);
    });
  });
}
