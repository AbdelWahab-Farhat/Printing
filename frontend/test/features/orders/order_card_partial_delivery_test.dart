import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «تسليم جزئي» مقروءاً من القائمة، دون فتح الطلبية.
///
/// **شارةٌ لا مُرشِّح.** الخادم يشتقّ `is_partially_delivered` من البنود التي تحمّلها القائمة
/// أصلاً، فلا تكلّف الشارة استعلاماً؛ و«كم يكلّفنا هذا؟» — وهو ما يُفتح المُرشِّح لأجله عادةً —
/// يجيب عنه قسم «الخسائر» في تقرير الأرباح، لا قائمةٌ تُقلَّب.
///
/// **وبلا لون إنذار.** الطلبية التي استلم العميل بعضها وسُوّيت فاتورتها ليست مشكلةً تنتظر أحداً:
/// هي واقعةٌ عن طلبيةٍ انتهت. «مستعجل» بجانبها هي الحمراء المملوءة، وهذه رماديةٌ هادئة — طبقةٌ
/// فوق الحالة لا حالةٌ ثانية تنازعها.
///
/// **وتغيب حين لا يُسأل السؤال.** المفتاح لا يصل إطلاقاً في حمولةٍ لم تُحمَّل بنودها، و«لم
/// يُسأل» ليست «لا».
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget card) {
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
            child: SingleChildScrollView(child: card),
          ),
        ),
      ),
    );
  }

  Order orderWith({bool? partiallyDelivered, bool urgent = false}) => Order(
    id: 52,
    code: '1220',
    status: OrderStatus.delivered,
    statusLabel: 'تم الاستلام',
    isFinal: false,
    isUrgent: urgent,
    isPartiallyDelivered: partiallyDelivered,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'زليتن',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '430.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '450.00',
    paidAmount: '450.00',
    remainingAmount: '0.00',
  );

  /// داخل الورقة وحدها: البطاقة تحتها تطبع كمّية البند أيضاً، وباحثٌ غير محصور يقول شيئاً عن
  /// أيّهما صادفه أوّلاً.
  Finder inSheet(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('an order the customer took part of says so on the card', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(partiallyDelivered: true))));

    // Act - Assert
    expect(find.text('استلام جزئي'), findsOneWidget);
  });

  testWidgets('an order delivered whole carries no badge', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(partiallyDelivered: false))));

    // Act - Assert
    expect(find.text('استلام جزئي'), findsNothing);
  });

  testWidgets('a payload that was never asked the question is not answered for it', (
    tester,
  ) async {
    // Arrange — the key is absent whenever the lines were not loaded, which is not «لا».
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('استلام جزئي'), findsNothing);
  });

  testWidgets('the badge costs the list no height', (tester) async {
    // Arrange — the same card twice, once with the badge and once without.
    await tester.pumpWidget(host(OrderCard(order: orderWith(partiallyDelivered: false))));
    final plain = tester.getSize(find.byType(OrderCard)).height;

    // Act
    await tester.pumpWidget(host(OrderCard(order: orderWith(partiallyDelivered: true))));
    final badged = tester.getSize(find.byType(OrderCard)).height;

    // Assert — it shares the status band's own row, so a list of twenty scrolls the same.
    expect(badged, plain);
  });

  testWidgets('an urgent order that was partly collected fits both badges beside the status', (
    tester,
  ) async {
    // Arrange — the widest the row can get: two badges and the band, on the narrowest phone
    // the app supports.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(
      host(OrderCard(order: orderWith(partiallyDelivered: true, urgent: true))),
    );

    // Assert — both are readable, and nothing runs off the edge of the card.
    expect(find.text('مستعجل'), findsOneWidget);
    expect(find.text('استلام جزئي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the badge opens what it is a badge of, without opening the order', (tester) async {
    // Arrange — a line the customer took two hundred of and left a hundred behind, priced so the
    // sheet has a «قبل» to build and an «بعد» to compare it with.
    var opened = false;

    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(partiallyDelivered: true).copyWith(
            items: [
              const OrderItem(
                id: 31,
                productId: 4,
                productVariantId: 9,
                productName: 'أكياس ورقية',
                variantLabel: '31*40',
                pricingUnitLabel: 'قطعة',
                quantity: '300.000',
                undeliveredQuantity: '100.000',
                undeliveredDisposition: 'restocked',
                undeliveredDispositionLabel: 'أُعيد إلى المخزن',
                restockedQuantity: '6.800',
                stockUnitLabel: 'كجم',
                billableQuantity: '200.000',
                unitPrice: '1.100',
                lineTotal: '220.00',
              ),
            ],
          ),
          onTap: () => opened = true,
        ),
      ),
    );

    // Act
    await tester.tap(find.text('استلام جزئي'));
    await tester.pumpAndSettle();

    // Assert — the sheet answers «قبل وبعد» in the two units the two facts are counted in, and
    // the card underneath stayed put: this is the one press inside it that is not the order.
    //
    // Scoped to the sheet, because the card behind it prints the line's own quantity too and an
    // unscoped finder would be asserting about whichever of the two it met first.
    expect(opened, isFalse);
    expect(inSheet('300 قطعة'), findsOneWidget);
    expect(inSheet('200 قطعة'), findsOneWidget);
    expect(inSheet('330'), findsOneWidget);
    expect(inSheet('220'), findsOneWidget);
    expect(inSheet('(-110)'), findsOneWidget);
    expect(inSheet('6.8 كجم'), findsOneWidget);
  });

  testWidgets('«قبل» is read first, which on an Arabic screen means it sits to the right', (
    tester,
  ) async {
    // Arrange — the bug this pins: the pair was one string with the Latin direction forced onto
    // it, so «قبل» landed on the left and the reader met «صار» before «كان». The arrow made it
    // worse — `←` is a mirrored character, so the engine was free to turn it round inside the
    // Arabic line and point it back at the figure it came from.
    await tester.pumpWidget(
      host(
        OrderCard(
          order: orderWith(partiallyDelivered: true).copyWith(
            items: [
              const OrderItem(
                id: 31,
                productId: 4,
                productVariantId: 9,
                productName: 'أكياس ورقية',
                variantLabel: '31*40',
                pricingUnitLabel: 'قطعة',
                quantity: '300.000',
                undeliveredQuantity: '100.000',
                undeliveredDisposition: 'restocked',
                undeliveredDispositionLabel: 'أُعيد إلى المخزن',
                restockedQuantity: '6.800',
                stockUnitLabel: 'كجم',
                billableQuantity: '200.000',
                unitPrice: '1.100',
                lineTotal: '220.00',
              ),
            ],
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.text('استلام جزئي'));
    await tester.pumpAndSettle();

    // Assert — right to left: «كان» ثم «صار», on both rows. Positions rather than a string,
    // because the string was never the thing that was wrong.
    expect(
      tester.getCenter(inSheet('330')).dx,
      greaterThan(tester.getCenter(inSheet('220')).dx),
    );
    expect(
      tester.getCenter(inSheet('300 قطعة')).dx,
      greaterThan(tester.getCenter(inSheet('200 قطعة')).dx),
    );
  });
}
