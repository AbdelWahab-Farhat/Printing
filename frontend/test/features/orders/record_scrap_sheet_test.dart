import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/record_scrap_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The form for writing off bags that were ruined making a line.
///
/// **Two boxes, and neither of them is a price.** The storekeeper counts what went in the bin;
/// the server draws those bags off the shelf and reads what they cost out of the batches they
/// came from. A unit-cost field here would invite somebody to type a number the batches already
/// know better than they do, so the test that matters most is the one that counts the fields.
///
/// **The reason is required, and three characters is the floor** — the same one the API keeps,
/// asked one round trip earlier. A scrap row is a quantity that left a shelf with nothing to show
/// for it; without the why, whoever reads the ledger next month has a hole and nobody to ask.
///
/// Arrange - Act - Assert throughout.
void main() {
  const item = OrderItem(
    id: 11,
    productId: 1,
    productVariantId: 12,
    productName: 'كيس شحن',
    variantLabel: '25*35',
    pricingUnitLabel: 'قطعة',
    quantity: '300.000',
    unitPrice: '1.550',
    lineTotal: '465.00',
  );

  ScrapDraft? saved;

  Widget host() => ScreenUtilInit(
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
              saved = await showRecordScrapSheet(context: context, item: item);
            },
            child: const Text('افتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openTheSheet(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    saved = null;
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the form asks for a quantity and a reason, and for nothing else', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act - Assert — a third box would be a price, and the price is not ours to know.
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('الكمية التالفة (قطعة)'), findsOneWidget);
    expect(find.text('سبب التلف'), findsOneWidget);
  });

  testWidgets('the sheet says what moves and what does not', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act - Assert — scrap never rewrites the line's own cost or the order's total, so promising
    // that it will would be promising something that does not happen.
    expect(find.textContaining('تكلفة البند وسعر الطلبية لا يتغيّران'), findsOneWidget);
    expect(find.textContaining('دفعات الشراء'), findsOneWidget);
  });

  testWidgets('the line being written off is named on the form', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act - Assert — «تلف من أي بند» is the question, and the answer has to be visible while the
    // number is being typed.
    expect(find.text('كيس شحن — 25*35'), findsOneWidget);
  });

  testWidgets('what was typed travels exactly as typed', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, 'انحراف في طباعة الشعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert — a form's answer is what the person entered; cleaning the digits belongs beside
    // the API call, where a test can reach it without a widget tree.
    expect(saved?.quantity, '10');
    expect(saved?.notes, 'انحراف في طباعة الشعار');
  });

  testWidgets('a quantity in Arabic-Indic digits is accepted and handed over unchanged', (
    tester,
  ) async {
    // Arrange — `١٠` is what a keyboard set to Arabic produces, and refusing it would be
    // refusing the digits the storekeeper is reading off their own screen.
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '١٠');
    await tester.enterText(find.byType(TextFormField).last, 'انحراف في طباعة الشعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved?.quantity, '١٠');
  });

  testWidgets('half a kilo typed on an Arabic keyboard stays half a kilo', (tester) async {
    // Arrange — «٢٫٥» uses U+066B, the decimal mark those keyboards actually offer. The box's
    // formatter drops every character it does not list, so leaving the separator out did not
    // refuse the entry — it silently turned two and a half into twenty-five.
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '٢٫٥');
    await tester.enterText(find.byType(TextFormField).last, 'انحراف في طباعة الشعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert — handed over exactly as typed, separator and all. The conversion happens beside
    // the API call, not under the person's finger.
    expect(saved?.quantity, '٢٫٥');
  });

  testWidgets('Persian digits the box lets through are not then called not-a-number', (
    tester,
  ) async {
    // Arrange — the formatter admits ۰-۹, so the validator underneath has to read them too. It
    // did not, and «۱۰» was refused as «الكمية يجب أن تكون رقماً» on a screen that had just
    // accepted every keystroke of it.
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '۱۰');
    await tester.enterText(find.byType(TextFormField).last, 'انحراف في طباعة الشعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved?.quantity, '۱۰');
    expect(find.text('الكمية يجب أن تكون رقماً'), findsNothing);
  });

  testWidgets('a line weighed onto the shelf is asked in the shelf own unit', (tester) async {
    // Arrange — forty bags sold by the piece that went onto the shelf as ten kilos. The server
    // draws a scrap straight out of that balance, so «قطعة» would be the wrong word and «١٠
    // قطع» would take ten kilos off the floor.
    const weighed = OrderItem(
      id: 11,
      productId: 1,
      productVariantId: 12,
      productName: 'كيس شحن',
      variantLabel: '25*35',
      pricingUnitLabel: 'قطعة',
      quantity: '40.000',
      warehouseQuantity: '10.000',
      unitPrice: '1.550',
      lineTotal: '62.00',
    );

    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Act
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showRecordScrapSheet(context: context, item: weighed),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert — the box names the basis it means and anchors on what actually left the shelf,
    // never on the invoice quantity.
    expect(find.text('الكمية التالفة (بوحدة المخزن)'), findsOneWidget);
    expect(find.text('الكمية التالفة (قطعة)'), findsNothing);
    expect(find.textContaining('خرج من المخزن لهذا البند 10.000'), findsOneWidget);
  });

  testWidgets('a loss with no reason is refused before it is sent', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert — the server refuses it too; this is the half that refuses it without a round trip.
    expect(saved, isNull);
    expect(find.text('سبب التلف مطلوب'), findsOneWidget);
  });

  testWidgets('a reason of two letters is as short as the API says it is', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, 'اب');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved, isNull);
    expect(find.text('سبب التلف قصير جداً'), findsOneWidget);
  });

  testWidgets('nothing spoiled is not a loss worth recording', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.enterText(find.byType(TextFormField).last, 'انحراف في طباعة الشعار');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved, isNull);
    expect(find.text('الكمية يجب أن تكون أكبر من صفر'), findsOneWidget);
  });

  testWidgets('a fraction is left for the server to judge', (tester) async {
    // Arrange — bags sold by the piece refuse a half; anything sold by weight does not, and the
    // product is what decides. Blocking the decimal point here would refuse the legitimate case
    // on a screen that cannot tell them apart.
    await openTheSheet(tester);

    // Act
    await tester.enterText(find.byType(TextFormField).first, '10.5');
    await tester.enterText(find.byType(TextFormField).last, 'تلف أثناء القص');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل التلف'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved?.quantity, '10.5');
  });

  testWidgets('backing out of the sheet records nothing', (tester) async {
    // Arrange
    await openTheSheet(tester);

    // Act
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(saved, isNull);
  });
}
