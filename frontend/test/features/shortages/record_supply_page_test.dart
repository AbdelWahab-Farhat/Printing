import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/views/record_supply_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «تسجيل توفير» — a page, and the one screen where the stock rules bite.
///
/// **A supply is the goods arriving, not a note beside them.** It writes a purchase arrival onto
/// a shelf, which is what lets the order draw its full quantity at «جاهزة». So the warehouse is
/// required where there is a shelf and refused where there is not — and the flag that decides is
/// `is_stockable`, read off the payload and never inferred from the variant id, which would put a
/// shelf picker in front of a roll of tape.
///
/// **A page rather than a sheet**: six fields, a picker, an attachment and a keyboard do not fit
/// in a drawer on a phone, and every other form in this app is a page.
///
/// Arrange - Act - Assert throughout.
void main() {
  Shortage shortage({bool isStockable = true, String remaining = '10.000'}) => Shortage(
    id: 41,
    code: 'N41',
    source: ShortageSource.order,
    sourceLabel: 'من طلبية',
    name: 'كيس شحن — 25*35',
    unit: 'kilogram',
    unitLabel: 'كجم',
    requiredQuantity: '30.000',
    suppliedQuantity: '20.000',
    remainingQuantity: remaining,
    totalPaid: '500.00',
    status: ShortageStatus.searching,
    statusLabel: 'جاري البحث',
    isStockable: isStockable,
  );

  Widget host(Shortage subject) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RecordSupplyPage(shortage: subject),
      ),
    ),
  );

  testWidgets('a shortage with a shelf is asked which one', (tester) async {
    // Arrange
    await tester.pumpWidget(host(shortage()));

    // Act - Assert — the very control the order's transition screen draws for this question.
    expect(find.text('المخزن'), findsOneWidget);
    expect(find.text('اختيار المخزن'), findsOneWidget);
  });

  testWidgets('a shortage with no shelf is not asked at all', (tester) async {
    // Arrange — «شريط لاصق عريض»: free text, nothing to put on a shelf.
    await tester.pumpWidget(host(shortage(isStockable: false)));

    // Act - Assert — sending a warehouse for one of these is a 422 in its own right.
    expect(find.text('المخزن'), findsNothing);
    expect(find.text('اختيار المخزن'), findsNothing);
  });

  testWidgets('الواصل is offered, and never demanded', (tester) async {
    // Arrange
    await tester.pumpWidget(host(shortage()));

    // Act - Assert — the one place this parts from a customer's payment: a sack bought from the
    // shop next door often comes with no paper, and refusing the entry for want of one would
    // push the purchase back onto paper.
    expect(find.text('الواصل (اختياري)'), findsOneWidget);
    expect(find.text('اختيار الواصل'), findsOneWidget);
  });

  testWidgets('«رقم العملية» is gone — nobody read it', (tester) async {
    // Arrange
    await tester.pumpWidget(host(shortage()));

    // Act - Assert — a box on a counter form that nothing downstream asks about is a box
    // somebody fills in wrongly in a hurry.
    expect(find.text('رقم العملية'), findsNothing);
  });

  testWidgets('the value is required, because the endpoint requires it', (tester) async {
    // Arrange — it was optional here and mandatory there, so an empty box bought a 422 after
    // the button.
    await tester.pumpWidget(host(shortage()));
    await tester.enterText(find.byType(AppTextField).first, '5');

    // Act
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أدخل القيمة المدفوعة'), findsOneWidget);
  });

  testWidgets('the warehouse is required, not merely offered', (tester) async {
    // Arrange — the order draws the *full* ordered quantity off the shelf at «جاهزة», and
    // nothing about that subtracts the shortage: goods that never reached a warehouse leave the
    // order refused a week later, about a balance that says nothing about the purchase.
    await tester.pumpWidget(host(shortage()));
    await tester.enterText(find.byType(AppTextField).first, '5');

    // Act
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    // Assert — refused here, where somebody can still fix it.
    expect(find.text('اختر المخزن'), findsOneWidget);
  });

  testWidgets('the quantity box does not open pre-filled with the remainder', (tester) async {
    // Arrange — pre-filling turns «كم وصل» into «أكّد ما كنا نأمله»; `receive_arrival_sheet`
    // argues this at length for shipments and it holds here.
    await tester.pumpWidget(host(shortage()));

    // Act
    final box = tester.widget<AppTextField>(find.byType(AppTextField).first);

    // Assert
    expect(box.controller?.text, isEmpty);
  });

  testWidgets('«المتبقي بعد هذه العملية» follows what is typed', (tester) async {
    // Arrange — partial supply is the ordinary case, and the whole point is that the user sees
    // they are leaving the shortage open.
    await tester.pumpWidget(host(shortage()));

    // Act
    await tester.enterText(find.byType(AppTextField).first, '4');
    await tester.pump();

    // Assert
    expect(find.textContaining('المتبقي بعد هذه العملية'), findsOneWidget);
    expect(find.textContaining('6'), findsWidgets);
  });

  testWidgets('a quantity above the remainder is refused before the request', (tester) async {
    // Arrange
    await tester.pumpWidget(host(shortage()));
    await tester.enterText(find.byType(AppTextField).first, '40');

    // Act
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    // Assert — the server checks it again under a lock, so the 422 can still arrive; this only
    // spares the ordinary case a round trip.
    expect(find.textContaining('أكبر من المتبقي'), findsOneWidget);
  });
}
