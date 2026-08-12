import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/presentation/widgets/edit_shortages_sheet.dart';

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
  }) => OrderItem(
    id: id,
    productId: 1,
    productVariantId: id,
    productName: 'كيس شحن',
    variantLabel: label,
    pricingUnitLabel: 'قطعة',
    quantity: quantity,
    shortageQuantity: shortage,
    billableQuantity: shortage == null ? quantity : null,
    unitPrice: '1.550',
    lineTotal: '465.00',
  );

  Map<int, String?>? saved;

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
    expect(find.text('100.000'), findsOneWidget);
  });

  testWidgets('the line says what it will be charged for as it is typed', (tester) async {
    // Arrange
    await openTheSheet(tester, [line()]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.pumpAndSettle();

    // Assert — the arithmetic is on screen before the save, because finding out afterwards on a
    // total is finding out from the wrong number.
    expect(find.text('يُحاسَب على 200.000 قطعة × 1.550'), findsOneWidget);
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
    expect(saved, {11: ''});
    expect(find.text('يُحاسَب على 300.000 قطعة × 1.550'), findsNothing);
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
    expect(saved, {11: '', 12: '20'});
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
    expect(find.text('الناقص أكبر من المطلوب (300.000)'), findsOneWidget);
  });

  testWidgets('a whole line going missing is a legitimate answer', (tester) async {
    // Arrange
    await openTheSheet(tester, [line()]);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '300');
    await tester.pumpAndSettle();

    // Assert — nothing arrived, nothing is charged, and the sheet says so rather than treating
    // it as the mistake the line above is.
    expect(find.text('يُحاسَب على 0.000 قطعة × 1.550'), findsOneWidget);
  });
}
