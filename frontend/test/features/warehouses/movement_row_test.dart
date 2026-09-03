import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/movement_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One line of the workshop-wide feed — what a reader scanning the whole ledger needs from a
/// row without opening it: what moved, which way and how much of what, for which order, when
/// and by whom.
///
/// Arrange - Act - Assert throughout.
void main() {
  const main = MovementPlace(id: 1, name: 'المخزن الرئيسي');
  const floor = MovementPlace(id: 2, name: 'مخزن التشغيل');
  const item = StockItemRef(id: 2, code: 'S2', name: 'أكياس الشحن', displayName: 'أكياس الشحن 40*35');

  StockMovement movement({
    MovementType type = MovementType.orderFulfillment,
    String label = 'صرف لطلب',
    String quantity = '1.600',
    int? referenceId = 1242,
    MovementPlace? from = main,
    MovementPlace? to,
    String? notes,
  }) => StockMovement(
    id: 1,
    movementType: type,
    movementTypeLabel: label,
    quantity: quantity,
    stockItemId: item.id,
    item: item,
    fromWarehouseId: from?.id,
    fromWarehouse: from,
    toWarehouseId: to?.id,
    toWarehouse: to,
    referenceId: referenceId,
    unitLabel: 'كيلوغرام',
    notes: notes,
    employee: const MovementActor(id: 1, name: 'المدير'),
    createdAt: DateTime(2026, 9, 2, 22, 13),
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

  testWidgets('an issue for an order: signed, in its unit, naming the order and the shelf', (tester) async {
    // Arrange
    await tester.pumpWidget(host(MovementRow(movement: movement())));

    // Act
    await tester.pumpAndSettle();

    // Assert — the shelf
    expect(find.text('S2'), findsOneWidget);
    expect(find.text('أكياس الشحن 40*35'), findsOneWidget);
    // … the number, signed, and what it is counted in
    expect(find.text('−1.6'), findsOneWidget);
    expect(find.text('كيلوغرام'), findsOneWidget);
    // … what happened, for which order, from where
    expect(find.text('صرف لطلب #1242 · من المخزن الرئيسي'), findsOneWidget);
    // … the time and who — the day belongs to the header above the group
    expect(find.text('10:13 م · المدير'), findsOneWidget);
    expect(find.textContaining('سبتمبر'), findsNothing);
    expect(find.textContaining('مرجع'), findsNothing);
  });

  testWidgets('a transfer is unsigned and names both ends', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        MovementRow(
          movement: movement(
            type: MovementType.internalTransfer,
            label: 'تحويل داخلي',
            quantity: '20.600',
            referenceId: null,
            from: main,
            to: floor,
          ),
        ),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('20.6'), findsOneWidget);
    expect(find.text('تحويل داخلي · المخزن الرئيسي ← مخزن التشغيل'), findsOneWidget);
  });

  testWidgets('a scrap loss names the order it was for, since its own words do not', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(MovementRow(movement: movement(type: MovementType.scrapLoss, label: 'تلف أثناء الإنتاج', referenceId: 1229))),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تلف أثناء الإنتاج · طلب #1229 · من المخزن الرئيسي'), findsOneWidget);
  });

  testWidgets('a row for an order opens it when tapped', (tester) async {
    // Arrange
    int? opened;
    await tester.pumpWidget(host(MovementRow(movement: movement(), onOpenOrder: (id) => opened = id)));

    // Act
    await tester.tap(find.text('أكياس الشحن 40*35'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened, 1242);
  });

  testWidgets('a row with no order behind it has nothing to open', (tester) async {
    // Arrange
    var opened = false;
    await tester.pumpWidget(
      host(
        MovementRow(
          movement: movement(type: MovementType.purchaseArrival, label: 'توريد', referenceId: null, from: null, to: main),
          onOpenOrder: (_) => opened = true,
        ),
      ),
    );

    // Act
    await tester.tap(find.text('أكياس الشحن 40*35'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened, isFalse);
    expect(find.text('+1.6'), findsOneWidget);
    expect(find.text('توريد · إلى المخزن الرئيسي'), findsOneWidget);
  });

  testWidgets('notes are carried on the row', (tester) async {
    // Arrange
    await tester.pumpWidget(host(MovementRow(movement: movement(notes: 'بقايا رول'))));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('بقايا رول'), findsOneWidget);
  });
}
