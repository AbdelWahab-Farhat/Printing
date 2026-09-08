import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «التوصيل» is stated on the order and added to nothing.
///
/// The owner's instruction: the fee is not our revenue and not our cost — the courier collects it
/// from the customer at their door. So «سعر الطلبية» is the goods and our own charges, and the
/// delivery line stands under the total rather than among the charges that reach it.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({String delivery = '15.00', String grandTotal = '120.00'}) => Order(
    id: 1,
    code: '1',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '10.00',
    deliveryPrice: delivery,
    discount: '0.00',
    additionalCost: '0.00',
    grandTotal: grandTotal,
    remainingAmount: grandTotal,
    paymentStatusLabel: 'غير مدفوعة',
  );

  Widget host(Widget child) => ScreenUtilInit(
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
          child: Center(child: SizedBox(width: 400, child: child)),
        ),
      ),
    ),
  );

  group('the account on the order screen', () {
    testWidgets('the delivery is read after the total, not before it', (tester) async {
      // Arrange
      final subject = order();

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject)));

      // Assert — a charge printed above «الإجمالي» is a charge the reader adds into it. Below
      // the total it reads as what it is: the courier's own bill, stated for the clerk quoting
      // it and part of no sum on this screen.
      final total = tester.getTopLeft(find.text('الإجمالي')).dy;
      final delivery = tester.getTopLeft(find.text('التوصيل (على الزبون)')).dy;
      expect(delivery, greaterThan(total));
    });

    testWidgets('an office pickup states its nothing all the same', (tester) async {
      // Arrange — «0.00» is what a pickup costs, and a clerk asked «كم التوصيل؟» wants to read
      // it rather than infer it from a missing line.
      final subject = order(delivery: '0.00');

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject)));

      // Assert
      expect(find.text('التوصيل (على الزبون)'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('the estimate while somebody is typing', () {
    test('the delivery does not move it', () {
      // Arrange — the same line, one copy going somewhere that costs 15 to reach and one to a
      // counter that costs nothing.
      OrderInvoiceState estimateFor(String delivery) => OrderInvoiceState(
        orderId: 1,
        lines: const [
          InvoiceLine(
            id: 1,
            productId: 1,
            variantId: 1,
            productName: 'أكياس شحن',
            variantLabel: '25*35',
            pricingUnitLabel: 'كيس',
            unitPrice: '1.100',
            quantity: '100',
          ),
        ],
        discount: '0.00',
        designFee: '10.00',
        deliveryPrice: delivery,
        cityId: 1,
        cityName: 'طرابلس',
      );

      final shipped = estimateFor('15.00');
      final collected = estimateFor('0.00');

      // Act
      final withFee = shipped.estimatedTotal;
      final withoutFee = collected.estimatedTotal;

      // Assert — the phone's guess has to reach the server's answer, and the server stopped
      // adding the fee.
      expect(withFee, withoutFee);
    });
  });
}
