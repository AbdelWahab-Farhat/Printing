import 'package:dayaa/features/orders/models/line_shortage_entry.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/edit_shortages_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Correcting what is missing — the form the money moves from.
///
/// A shortage is no longer a note: it comes off the invoice. So this sheet has to say what each
/// line will be charged **before** anybody saves, has to show every line and not only the short
/// ones — the set is replaced on the way out, and a line it never showed could not be cleared —
/// and has to treat an emptied box as the answer it is: «وصلت الكمية»، and the money comes back.
///
/// Arrange - Act - Assert throughout.
void main() {
  OrderItem line({
    int id = 11,
    String label = '25*35',
    String quantity = '300.000',
    String? shortage,
    bool weighed = false,
    String? warehouseShortage,
  }) => OrderItem(
    id: id,
    productId: 1,
    productVariantId: id,
    productName: 'كيس شحن',
    variantLabel: label,
    pricingUnitLabel: 'قطعة',
    quantity: quantity,
    shortageQuantity: shortage,
    // The shelf's opinion. `weighed` is the case where it disagrees with the invoice — sold by
    // the piece off a pile counted by the kilo — which is the only case asked for two numbers.
    stockUnitLabel: weighed ? 'كجم' : 'قطعة',
    isStockedInAnotherUnit: weighed,
    shortageWarehouseQuantity: warehouseShortage,
    billableQuantity: shortage == null ? quantity : null,
    unitPrice: '1.550',
    lineTotal: '465.00',
  );

  Map<int, LineShortageEntry>? saved;

  Widget host(List<OrderItem> items) => ScreenUtilInit(
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
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await showEditShortagesSheet(context: context, items: items);
            },
            child: const Text('افتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester, List<OrderItem> items) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    saved = null;
    await tester.pumpWidget(host(items));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('every line is offered, not only the ones already short', (tester) async {
    // Arrange — one line short, one whole.
    await openTheSheet(tester, [
      line(id: 11, label: '25*35', shortage: '100.000'),
      line(id: 12, label: '45*50'),
    ]);

    // Assert — «أي بند نقص» is a question about the order, so the answer has to be able to move
    // from one line to another.
    expect(find.text('كيس شحن — 25*35'), findsOneWidget);
    expect(find.text('كيس شحن — 45*50'), findsOneWidget);
  });

  testWidgets('a box opens holding what is recorded against its line', (tester) async {
    // Arrange
    await openTheSheet(tester, [line(shortage: '100.000')]);

    // Assert
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('the line says what it will be charged for as it is typed', (tester) async {
    // Arrange
    await openTheSheet(tester, [line()]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.pumpAndSettle();

    // Assert — the arithmetic is on screen before the save, because finding out afterwards on a
    // total is finding out from the wrong number.
    expect(find.text('يُحاسَب على 200 قطعة × 1.55'), findsOneWidget);
  });

  testWidgets('emptying a box is the gesture that puts the money back', (tester) async {
    // Arrange — a line that is short today.
    await openTheSheet(tester, [line(shortage: '100.000')]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — the key travels holding nothing, which is what clears the shortage. Dropping it
    // would leave the old number standing and the invoice short with it.
    expect(saved!.map((id, v) => MapEntry(id, v.quantity)), {11: ''});
    expect(find.text('يُحاسَب على 300 قطعة × 1.55'), findsNothing);
  });

  testWidgets('what every line says travels, short or not', (tester) async {
    // Arrange
    await openTheSheet(tester, [
      line(id: 11, label: '25*35'),
      line(id: 12, label: '45*50'),
    ]);

    // Act
    await tester.enterText(find.byType(TextFormField).at(1), '20');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — the whole set, because the server replaces the whole set.
    expect(saved!.map((id, v) => MapEntry(id, v.quantity)), {11: '', 12: '20'});
  });

  testWidgets('more missing than was ordered is refused before it is sent', (tester) async {
    // Arrange
    await openTheSheet(tester, [line()]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — «ناقص ٤٠٠ من ٣٠٠» is a typo, and it would have produced a negative line. The
    // server refuses it too; this is the half that refuses it without a round trip.
    expect(saved, isNull);
    expect(find.text('الناقص أكبر من المطلوب (300)'), findsOneWidget);
  });

  testWidgets('a whole line going missing is a legitimate answer', (tester) async {
    // Arrange
    await openTheSheet(tester, [line()]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();

    // Assert — nothing arrived, nothing is charged, and the sheet says so rather than treating
    // it as the mistake the line above is.
    expect(find.text('يُحاسَب على 0 قطعة × 1.55'), findsOneWidget);
  });

  // ── the second unit ───────────────────────────────────────────────────────────────────

  testWidgets('a size stocked in its own unit is asked once', (tester) async {
    // Arrange — sold and stocked by the piece, which is most sizes.
    await openTheSheet(tester, [line()]);

    // Act - Assert — a second box would ask somebody to weigh what needs no weighing, and the
    // server refuses a figure there.
    expect(find.textContaining('الناقص من المخزن'), findsNothing);
  });

  testWidgets('a size the warehouse weighs is asked for both figures', (tester) async {
    // Arrange — «٣٠ قطعة» off a pile counted in kilograms.
    await openTheSheet(tester, [line(weighed: true)]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.pumpAndSettle();

    // Assert — both units named, because the whole difficulty is that they differ and nothing
    // converts one into the other.
    expect(find.text('الناقص من المخزن (كجم)'), findsOneWidget);
    expect(find.textContaining('يُباع بـقطعة ويُخزَّن بـكجم'), findsOneWidget);
  });

  testWidgets('the weight travels beside the count', (tester) async {
    // Arrange
    await openTheSheet(tester, [line(weighed: true)]);

    // Act
    await tester.enterText(find.byType(TextFormField).at(0), '30');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '12.5');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — one is what comes off the invoice, the other is what will be bought.
    expect(saved![11]!.quantity, '30');
    expect(saved![11]!.warehouseQuantity, '12.5');
  });

  testWidgets('the weight may be left blank, because nobody can weigh missing bags', (tester) async {
    // Arrange — the bags are missing, so there is nothing to put on a scale and no factor that
    // converts the count. Demanding a figure would ask for a measurement of goods that do not
    // exist.
    await openTheSheet(tester, [line(weighed: true)]);

    // Act — the invoice's figure alone.
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — the shortage is declared, and the weight travels as nothing. What the gap blocks
    // is recording a purchase against it, which the server refuses until somebody knows.
    expect(saved![11]!.quantity, '30');
    expect(saved![11]!.warehouseQuantity, isNull);
  });

  testWidgets('clearing the line hides the weight rather than demanding one', (tester) async {
    // Arrange — a two-unit line that is short today.
    await openTheSheet(tester, [line(weighed: true, shortage: '30.000', warehouseShortage: '12.500')]);
    expect(find.text('الناقص من المخزن (كجم)'), findsOneWidget);

    // Act — «وصلت الكمية».
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pumpAndSettle();

    // Assert — a measurement beside no shortage is a measurement of nothing, and the server
    // refuses the pairing. Shouting for a number on a line just cleared would be the sheet
    // arguing with what it was told.
    expect(find.text('الناقص من المخزن (كجم)'), findsNothing);
  });
}
