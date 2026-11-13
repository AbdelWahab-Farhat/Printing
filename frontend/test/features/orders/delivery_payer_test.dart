import 'package:dayaa/features/orders/models/delivery_payer_change.dart';
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_message.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «التوصيل على: المستلم / علينا» on the staff app — Docs/orders/DELIVERY-PAYER.md.
///
/// Every figure is the server's string: when we pay, the cost is already inside `gross_profit`,
/// and these tests only check that it is *shown*, never that the widget subtracts it.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  Order orderPaidBy(String paidBy, {NawrisParcelRef? parcel}) => Order(
    id: 7,
    code: '7',
    status: OrderStatus.outForDelivery,
    statusLabel: 'جاري التوصيل',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '100.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    deliveryPaidBy: paidBy,
    deliveryCost: paidBy == 'us' ? '20.00' : '0.00',
    discount: '0.00',
    grandTotal: '100.00',
    paidAmount: '0.00',
    remainingAmount: '100.00',
    totalCogs: '60.00',
    grossProfit: paidBy == 'us' ? '20.00' : '40.00',
    nawrisParcel: parcel,
  );

  group('the account card', () {
    testWidgets('the recipient paying is said on the delivery line', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderTotals(order: orderPaidBy('recipient'), showCosts: true)));

      // Assert
      expect(find.text('التوصيل (على الزبون)'), findsOneWidget);
      expect(find.text('التوصيل علينا'), findsNothing);
    });

    testWidgets('delivery on us is a second subtraction on the way to the profit', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderTotals(order: orderPaidBy('us'), showCosts: true)));

      // Assert — the cost line, and the server's profit beside it
      expect(find.text('التوصيل (علينا — مجاني للزبون)'), findsOneWidget);
      expect(find.text('التوصيل علينا'), findsOneWidget);
      expect(find.textContaining('20'), findsWidgets);
    });

    testWidgets('the cost line stays behind the cost grant', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderTotals(order: orderPaidBy('us'))));

      // Assert
      expect(find.text('التوصيل علينا'), findsNothing);
      expect(find.text('التوصيل (علينا — مجاني للزبون)'), findsOneWidget);
    });

    testWidgets('a change Nawris never heard about is said in red under the line', (tester) async {
      // Arrange — the order says us, the open parcel still has the recipient paying
      final order = orderPaidBy(
        'us',
        parcel: const NawrisParcelRef(code: 'P-1', isOpen: true, nawrisPayer: 'recipient'),
      );
      await tester.pumpWidget(host(OrderTotals(order: order)));

      // Assert
      expect(find.textContaining('نورس ما زالت تحمّل أجرتها على المستلم'), findsOneWidget);
    });

    testWidgets('no red line when Nawris agrees', (tester) async {
      // Arrange
      final order = orderPaidBy(
        'us',
        parcel: const NawrisParcelRef(code: 'P-1', isOpen: true, nawrisPayer: 'us'),
      );
      await tester.pumpWidget(host(OrderTotals(order: order)));

      // Assert
      expect(find.textContaining('نورس ما زالت'), findsNothing);
    });

    testWidgets('the change button is drawn only when it is offered', (tester) async {
      // Arrange
      var tapped = false;
      await tester.pumpWidget(
        host(OrderTotals(order: orderPaidBy('recipient'), onChangeDeliveryPayer: () => tapped = true)),
      );

      // Act
      await tester.tap(find.text('تغيير من يدفع التوصيل'));

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('no button without a callback', (tester) async {
      // Arrange
      await tester.pumpWidget(host(OrderTotals(order: orderPaidBy('recipient'))));

      // Assert
      expect(find.text('تغيير من يدفع التوصيل'), findsNothing);
    });
  });

  group('the customer\'s message', () {
    test('free delivery is said, not left for the customer to guess', () {
      // Act
      final message = OrderMessage.of(orderPaidBy('us'));

      // Assert
      expect(message, contains('التوصيل: مجاني'));
      expect(message, isNot(contains('يُدفع للمندوب')));
    });

    test('the recipient paying still names the courier\'s fee', () {
      // Act
      final message = OrderMessage.of(orderPaidBy('recipient'));

      // Assert
      expect(message, contains('يُدفع للمندوب'));
    });
  });

  group('the wire', () {
    test('a new order says us only when we pay', () {
      // Arrange
      const base = NewOrder(customerId: 3, cityId: 1, designSource: 'none', items: []);

      // Act - Assert
      expect(base.toJson().containsKey('delivery_paid_by'), isFalse);
      expect(base.copyWith(deliveryPaidBy: 'us').toJson()['delivery_paid_by'], 'us');
    });

    test('the change answer carries the order, the carrier and the shared parcel', () {
      // Arrange
      final json = <String, dynamic>{
        'order': orderPaidBy('us').toJson(),
        'carrier': {
          'told': false,
          'parcel_code': 'P-1',
          'nawris_asks': '100.00',
          'should_ask': '100.00',
          'warning': 'لم تقبل نورس',
        },
        'also_changed': ['8'],
      };

      // Act
      final change = DeliveryPayerChange.fromJson(json);

      // Assert
      expect(change.order.wePayDelivery, isTrue);
      expect(change.carrier?.warning, 'لم تقبل نورس');
      expect(change.alsoChanged, ['8']);
    });

    test('an order from an older server reads as the recipient paying', () {
      // Arrange
      final json = orderPaidBy('recipient').toJson()
        ..remove('delivery_paid_by')
        ..remove('delivery_cost');

      // Act
      final order = Order.fromJson(json);

      // Assert
      expect(order.wePayDelivery, isFalse);
      expect(order.deliveryCost, '0.00');
    });
  });
}
