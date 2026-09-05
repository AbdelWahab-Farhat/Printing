import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/ledger_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One line of a shelf's ledger.
///
/// What the row has to get right, each of which the old feed got wrong:
///
///   * **the two balances are the number.** «1,000 ← 0» says how much moved and where it left
///     the shelf standing; the signed figure that used to shout beside it was the same thousand
///     a third time, and «كان»/«صار» were words an arrow does not need.
///   * **the balance after each row is on the row — once.** The header said 300 and nothing
///     below it proved it; checking meant adding ten cards in your head. It is inside «كان ←
///     صار» rather than beside it, because one fact printed on both sides of a row is one fact
///     a person has to reconcile with itself.
///   * **a count says «كان ← صار».** The person entered a count, not a difference, and
///     «105,250 من المخزن» read as if somebody had wheeled that much out of the door.
///   * **the warehouse is not repeated.** A ledger about one shelf in one place does not say the
///     place on every line.
///   * **cost is drawn on the session's say-so, not the payload's.** Absent figures on a row
///     mean «unknown» to someone entitled to know and nothing at all to someone who is not.
///
/// Arrange - Act - Assert throughout.
void main() {
  const main = MovementPlace(id: 1, name: 'المخزن الرئيسي');
  const floor = MovementPlace(id: 2, name: 'صالة العرض');

  StockMovement movement({
    MovementType type = MovementType.purchaseArrival,
    String label = 'توريد',
    String quantity = '1000.000',
    String? signed,
    String? after,
    String? unitCost,
    String? totalCost,
    String? uncosted,
    int? referenceId,
    String? notes,
    List<MovementDraw> draws = const [],
    MovementPlace? from,
    MovementPlace? to = main,
  }) => StockMovement(
    id: 1,
    movementType: type,
    movementTypeLabel: label,
    quantity: quantity,
    stockItemId: 7,
    investorDraws: draws,
    fromWarehouseId: from?.id,
    fromWarehouse: from,
    toWarehouseId: to?.id,
    toWarehouse: to,
    referenceId: referenceId,
    signedQuantity: signed,
    balanceAfter: after,
    unitCost: unitCost,
    totalCost: totalCost,
    uncostedQuantity: uncosted,
    notes: notes,
    employee: const MovementActor(id: 1, name: 'المدير'),
    createdAt: DateTime(2026, 9, 2, 1, 0),
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

  testWidgets('the row is the two balances, and the movement is the space between', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(signed: '1000.000', after: '1300.000'),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — one fact, once. «الرصيد» beside it and «+1,000» opposite it were the same
    // thousand said three times.
    expect(find.text('300 ← 1,300'), findsOneWidget);
    expect(find.textContaining('الرصيد'), findsNothing);
    expect(find.text('+1,000'), findsNothing);
  });

  testWidgets('an issue is drawn negative and named by its order', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.orderFulfillment,
            label: 'صرف لطلب',
            signed: '-1000.000',
            after: '300.000',
            referenceId: 4,
            from: main,
            to: null,
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert — and the warehouse is not repeated: the ledger is about this shelf in this place
    expect(find.text('1,300 ← 300'), findsOneWidget);
    expect(find.text('صرف لطلب #4'), findsOneWidget);
    expect(find.textContaining('المخزن الرئيسي'), findsNothing);
  });

  testWidgets('a count hands back the number the person saw', (tester) async {
    // Arrange — the screenshot's adjustment: 105,250 on the books, nothing on the shelf
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.adjustment,
            label: 'تسوية جرد',
            quantity: '105250.000',
            signed: '-105250.000',
            after: '0.000',
            notes: 'جرد',
            from: main,
            to: null,
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('105,250 ← 0'), findsOneWidget);
    expect(find.text('جرد'), findsOneWidget);
  });

  testWidgets('only a transfer names its other end', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.internalTransfer,
            label: 'تحويل داخلي',
            signed: '-200.000',
            after: '300.000',
            from: main,
            to: floor,
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('تحويل داخلي ← صالة العرض'), findsOneWidget);
  });

  group('the cost line', () {
    testWidgets('is drawn for a reader who may know: the price, on arriving stock', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          LedgerRow(
            movement: movement(
              quantity: '300.000',
              signed: '300.000',
              after: '1300.000',
              unitCost: '3.500',
              totalCost: '1050.00',
              uncosted: '0.000',
            ),
            warehouseId: main.id,
            unitLabel: 'قطعة',
            showCost: true,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('3.5 د.ل/قطعة'), findsOneWidget);
      expect(find.textContaining('1,050'), findsNothing);
    });

    testWidgets('is not drawn at all for a reader who may not, even when the figures came', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        host(
          LedgerRow(
            movement: movement(signed: '300.000', unitCost: '3.500', totalCost: '1050.00', uncosted: '0.000'),
            warehouseId: main.id,
            unitLabel: 'قطعة',
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.textContaining('د.ل'), findsNothing);
      expect(find.textContaining('التكلفة'), findsNothing);
    });

    testWidgets('says «unknown» to a reader who may know when nobody recorded it', (tester) async {
      // Arrange — a row older than the cost ledger: no figures, and silence would read as free
      await tester.pumpWidget(
        host(
          LedgerRow(
            movement: movement(signed: '300.000'),
            warehouseId: main.id,
            unitLabel: 'قطعة',
            showCost: true,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('التكلفة غير معروفة'), findsOneWidget);
    });

    testWidgets('names unpriced stock in words, never as a zero', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          LedgerRow(
            movement: movement(signed: '1000.000', totalCost: '0.00', uncosted: '1000.000'),
            warehouseId: main.id,
            unitLabel: 'قطعة',
            showCost: true,
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.text('بلا تكلفة'), findsOneWidget);
      expect(find.textContaining('0 د.ل'), findsNothing);
    });
  });

  testWidgets('a shared shelf says whose goods went out, and how much of each', (tester) async {
    // Arrange — the case the ledger could not be read for: 3,000 off one pile, 2,000 of it ours
    // and 1,000 financed by a deal. FIFO wrote both rows months ago; no screen said so.
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.orderFulfillment,
            label: 'صرف لطلب',
            referenceId: 1206,
            quantity: '3000.000',
            signed: '-3000.000',
            draws: const [
              MovementDraw(quantity: '2000.000'),
              MovementDraw(investorDealId: 22, code: 'D22', quantity: '1000.000'),
            ],
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.text('الشركة 2,000 · D22 1,000'), findsOneWidget);
  });

  testWidgets('a whole movement off one deal names it, and our own says nothing', (tester) async {
    // Arrange — one owner. Naming the company on every ordinary line would be noise on most of
    // them; naming the deal is the fact the shelf cannot be read for.
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.orderFulfillment,
            label: 'صرف لطلب',
            signed: '-1000.000',
            draws: const [MovementDraw(investorDealId: 22, code: 'D22', quantity: '1000.000')],
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );
    await tester.pump();

    // Assert
    expect(find.text('من D22'), findsOneWidget);

    // Act — the same row, off our own stock.
    await tester.pumpWidget(
      host(
        LedgerRow(
          movement: movement(
            type: MovementType.orderFulfillment,
            label: 'صرف لطلب',
            signed: '-1000.000',
            draws: const [MovementDraw(quantity: '1000.000')],
          ),
          warehouseId: main.id,
          unitLabel: 'قطعة',
        ),
      ),
    );
    await tester.pump();

    // Assert
    expect(find.textContaining('الشركة'), findsNothing);
  });
}
