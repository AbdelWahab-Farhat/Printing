import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/revalue_batch_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one write a cost layer accepts, and the sentence it puts in front of somebody first.
///
/// **What is tested here is mostly the warning**, because that is what the sheet is for: a price
/// typed into a box is trivial, and the two things a person cannot see from the shelf are that
/// the stock already issued keeps its old cost, and that repricing part of a layer leaves a
/// second layer behind at the old one.
///
/// Arrange - Act - Assert throughout.
void main() {
  StockBatch batch({
    String unitCost = '0.000',
    String received = '500.000',
    String remaining = '300.000',
    String consumed = '200.000',
    bool partlyConsumed = true,
    int? purchaseOrderId,
  }) => StockBatch(
    id: 40,
    warehouseId: 1,
    stockItemId: 7,
    unitCost: unitCost,
    quantityReceived: received,
    quantityRemaining: remaining,
    quantityConsumed: consumed,
    unit: 'piece',
    unitLabel: 'قطعة',
    sourceType: 'purchase_arrival',
    sourceTypeLabel: 'توريد',
    receivedAt: DateTime(2026, 8, 31),
    purchaseOrderId: purchaseOrderId,
    canBeRevalued: true,
    isPartlyConsumed: partlyConsumed,
    isUncosted: unitCost == '0.000',
  );

  /// Opens the sheet over a bare screen. Whatever it answers with lands in [answers] — a list
  /// rather than a variable, because the answer arrives only when the sheet closes and half of
  /// these tests go on typing into it first.
  Future<void> open(
    WidgetTester tester,
    StockBatch layer,
    List<RevaluationDraft?> answers,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async =>
                      answers.add(await showRevalueBatchSheet(context: context, batch: layer)),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('a layer half issued says the issued half keeps its old cost', (tester) async {
    // Arrange
    final answers = <RevaluationDraft?>[];

    // Act
    await open(tester, batch(), answers);

    // Assert — the whole point of the warning: this corrects the 300 still on the shelf, and
    // the 200 that left are not restated on the orders that took them.
    expect(find.textContaining('صُرف منها 200'), findsOneWidget);
    expect(find.textContaining('لا تتغيّر'), findsOneWidget);
  });

  testWidgets('correcting part of a layer says what stays behind at the old price', (
    tester,
  ) async {
    // Arrange
    final answers = <RevaluationDraft?>[];
    await open(tester, batch(unitCost: '1.000'), answers);

    // Act — 100 of the 300 still on the shelf.
    await tester.enterText(find.byKey(const Key('revalue-cost')), '3.5');
    await tester.enterText(find.byKey(const Key('revalue-quantity')), '100');
    await tester.pump();

    // Assert — «سيُصحَّح 100 … ويبقى 200 بسعرها القديم في دفعة منفصلة», said before it happens.
    expect(find.textContaining('100 قطعة'), findsWidgets);
    expect(find.textContaining('200 قطعة'), findsWidgets);
    expect(find.textContaining('دفعة منفصلة'), findsOneWidget);
  });

  testWidgets('an empty quantity box corrects all of what is left, and says so', (tester) async {
    // Arrange
    final answers = <RevaluationDraft?>[];
    await open(tester, batch(), answers);

    await tester.enterText(find.byKey(const Key('revalue-cost')), '3.5');
    await tester.enterText(
      find.byKey(const Key('revalue-reason')),
      'فاتورة المورد وصلت بسعر مختلف',
    );
    await tester.pump();

    expect(find.textContaining('سيُصحَّح كل المتبقي 300 قطعة'), findsOneWidget);
    expect(find.textContaining('دفعة منفصلة'), findsNothing);

    // Act
    await tester.ensureVisible(find.text('تصحيح التكلفة'));
    await tester.tap(find.text('تصحيح التكلفة'));
    await tester.pumpAndSettle();

    // Assert — no quantity at all, which is what asks the server for the whole layer.
    expect(answers.single?.unitCost, '3.5');
    expect(answers.single?.quantity, isNull);
    expect(answers.single?.reason, 'فاتورة المورد وصلت بسعر مختلف');
  });

  testWidgets('nothing is sent without a reason', (tester) async {
    // Arrange
    final answers = <RevaluationDraft?>[];
    await open(tester, batch(), answers);

    await tester.enterText(find.byKey(const Key('revalue-cost')), '3.5');

    // Act
    await tester.ensureVisible(find.text('تصحيح التكلفة'));
    await tester.tap(find.text('تصحيح التكلفة'));
    await tester.pumpAndSettle();

    // Assert — the sheet is still open and holding the figure; the API's own rule, one round
    // trip earlier.
    expect(answers, isEmpty);
    expect(find.text('تصحيح التكلفة'), findsOneWidget);

    await tester.ensureVisible(find.text('إلغاء'));
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(answers.single, isNull);
  });

  testWidgets('a layer that came in on a purchase order names it', (tester) async {
    // Arrange
    final answers = <RevaluationDraft?>[];

    // Act
    await open(tester, batch(purchaseOrderId: 12), answers);

    // Assert — repricing it is allowed, and the invoice behind it may say something else.
    expect(find.textContaining('أمر شراء #12'), findsOneWidget);
  });
}
