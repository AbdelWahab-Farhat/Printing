import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «كم تزن الطلبية؟» مقروءاً من القائمة، دون فتح الطلبية.
///
/// **الوزن خانةٌ في الشبكة، لا سطرٌ زائد تحتها.** الصفّ الثالث من البطاقة كان خانتين وثالثةً
/// فارغة محجوزةً لتستقيم الأعمدة، والوزن هو ما يملؤها: يقف تحت ما فوقه، ولا يطيل البطاقة بسطر،
/// ولا يزاحم المال في وسطها.
///
/// **ويغيب كما يغيب في الخادم.** `total_weight` تصل `null` في طلبيةٍ لا شيء فيها يُوزن، وفي
/// طلبيةٍ لم يقف أحدٌ بها على ميزان بعد — والخانة تعود فارغةً في الحالتين، لأن «٠ كيلوغرام»
/// تحت اسمٍ عريض تُقرأ كوزنٍ قيس فوجد صفراً.
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

  Order orderWith({String? totalWeight}) => Order(
    id: 52,
    code: '1220',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
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
    paidAmount: '150.00',
    remainingAmount: '300.00',
    totalWeight: totalWeight,
  );

  testWidgets('a weighed order states its weight on the card, under its own name', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(totalWeight: '12.500'))));

    // Act - Assert — the same string the order screen prints, trimmed of the column's padding
    // zeros and carrying its unit.
    expect(find.text('وزن الطلبية'), findsOneWidget);
    expect(find.text('12.5 كيلوغرام'), findsOneWidget);
  });

  testWidgets('an order with no weight to state draws no weight cell', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith())));

    // Act - Assert — and no «٠» standing in for the answer nobody has yet.
    expect(find.text('وزن الطلبية'), findsNothing);
  });

  testWidgets('the weight fills the third column rather than adding a row', (tester) async {
    // Arrange — the same card twice, one weighed and one not.
    await tester.pumpWidget(host(OrderCard(order: orderWith())));
    final bare = tester.getSize(find.byType(OrderCard)).height;

    // Act
    await tester.pumpWidget(host(OrderCard(order: orderWith(totalWeight: '12.500'))));
    final weighed = tester.getSize(find.byType(OrderCard)).height;

    // Assert — the cell was already reserved by the empty third column, so stating the weight
    // costs the list no height at all.
    expect(weighed, bare);
  });

  testWidgets('the weight sits under «تاريخ الإنشاء», in the last row', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCard(order: orderWith(totalWeight: '12.500'))));

    // Act
    final placed = tester.getCenter(find.text('تاريخ الإنشاء'));
    final weight = tester.getCenter(find.text('وزن الطلبية'));

    // Assert — same row, and to its left: in an Arabic layout the third column is the leftmost.
    expect(weight.dy, placed.dy);
    expect(weight.dx, lessThan(placed.dx));
  });
}
