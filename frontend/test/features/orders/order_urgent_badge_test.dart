import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مستعجل» على بطاقة الطلبية.
///
/// **ما يستحقّ الإثبات هو أنّ الشارة تُلمَح ولا تُزاحم.** الوسم قيمةٌ يرسلها الخادم — لا يُشتقّ
/// هنا من عمر الطلبية — فالمُختبَر هو ثلاثة أشياء: أنّها تظهر حين يقول الخادم إنّها مستعجلة،
/// وأنّها تغيب تماماً حين لا يقول (لا مكان محجوز ولا شرطة)، وأنّ لونها هو الأحمر المملوء لا
/// الباهت الذي تلبسه «نواقص» و«الرواجع» على الشريط نفسه.
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

  Order orderWith({
    bool isUrgent = false,
    OrderStatus status = OrderStatus.printing,
    String statusLabel = 'قيد الطباعة',
  }) {
    return Order(
      id: 52,
      code: '52',
      status: status,
      statusLabel: statusLabel,
      isFinal: false,
      isUrgent: isUrgent,
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
    );
  }

  testWidgets('an urgent order wears the word', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(isUrgent: true))));

    // Act - Assert
    expect(find.text('مستعجل'), findsOneWidget);
  });

  testWidgets('an ordinary order is the card as it always was', (tester) async {
    // Arrange — لا شارةَ ولا مكانٌ محجوزٌ لها: بطاقةٌ نصفها فارغٌ في انتظار وسمٍ لم يُوضع تقرأ
    // كعطبٍ في الرسم.
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert
    expect(find.text('مستعجل'), findsNothing);
    expect(find.byIcon(AppIcons.urgent), findsNothing);
  });

  testWidgets('the badge is filled red, not the pale red a status wears', (tester) async {
    // Arrange — «نواقص» و«الرواجع» تلبسان `errorContainer` على الشريط الذي تقف الشارة بجانبه،
    // فشارةٌ بالدرجة نفسها تذوب فيه. المملوء هو اللون الوحيد على البطاقة الذي لا تلبسه حالة.
    await tester.pumpWidget(host(OrderCard(order: orderWith(isUrgent: true))));
    final scheme = Theme.of(tester.element(find.byType(OrderCard))).colorScheme;

    // Act
    final badge = tester.widget<Container>(
      find.ancestor(of: find.text('مستعجل'), matching: find.byType(Container)).first,
    );

    // Assert
    expect((badge.decoration! as BoxDecoration).color, scheme.error);
    expect(
      (badge.decoration! as BoxDecoration).color,
      isNot(OrderStatusChip.toneColour(scheme, OrderStatusTone.attention).$1),
    );
  });

  testWidgets('it stands beside the status band, not over it', (tester) async {
    // Arrange — الحالة تبقى ما تُقرأ أولاً، والشارة طبقةٌ فوقها على السطر نفسه: صفٌّ واحد،
    // فلا تطول البطاقة بسطرٍ لأجل كلمتين.
    await tester.pumpWidget(host(OrderCard(order: orderWith(isUrgent: true))));

    // Act
    final badge = tester.getCenter(find.text('مستعجل'));
    final band = tester.getCenter(find.text('قيد الطباعة'));

    // Assert
    expect(badge.dy, moreOrLessEquals(band.dy));
    // وفي أوّل السطر كما يُقرأ العربي: من اليمين.
    expect(badge.dx, greaterThan(band.dx));
  });
}
