import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/widgets/order_customer_card.dart';

/// Who the order is for, on the order's own screen — and the way into their file.
///
/// The three things a customer is looked up by are the three things this card shows: the code
/// said on the phone, the name, and the number rung. Anything less sends somebody to the
/// customers tab to search for a person the order already knows.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// The same frame the app boots into: ScreenUtil at the reference size, Arabic, RTL.
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

  Order orderWith({Customer? customer}) {
    return Order(
      id: 52,
      code: '52',
      status: OrderStatus.ready,
      statusLabel: 'جاهزة',
      isFinal: false,
      customerId: 5,
      customer: customer,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '124.00',
      designFee: '0.00',
      deliveryPrice: '0.00',
      discount: '0.00',
      grandTotal: '124.00',
    );
  }

  const customer = Customer(
    id: 5,
    code: 'C5',
    name: 'سوق المدينة',
    phone: '0900000002',
    isActive: true,
  );

  testWidgets('the code, the name and the number are all three on the card', (tester) async {
    // Arrange
    await tester.pumpWidget(host(OrderCustomerCard(order: orderWith(customer: customer))));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('C5'), findsOneWidget);
    expect(find.text('سوق المدينة'), findsOneWidget);
    expect(find.text('0900000002'), findsOneWidget);
  });

  testWidgets('a tap reaches the caller', (tester) async {
    // Arrange
    var taps = 0;
    await tester.pumpWidget(
      host(
        OrderCustomerCard(order: orderWith(customer: customer), onTap: () => taps++),
      ),
    );

    // Act
    await tester.tap(find.byType(OrderCustomerCard));
    await tester.pump();

    // Assert
    expect(taps, 1);
  });

  testWidgets('without a way in, nothing on the card offers one', (tester) async {
    // Arrange — somebody without `customers.view` gets the facts and no chevron promising a
    // screen that would answer 403.
    await tester.pumpWidget(host(OrderCustomerCard(order: orderWith(customer: customer))));

    // Act
    await tester.pump();

    // Assert
    expect(find.byType(OrderCustomerCard), findsOneWidget);
    expect(find.byKey(OrderCustomerCard.chevronKey), findsNothing);
  });

  testWidgets('a way in is advertised by the chevron', (tester) async {
    // Arrange
    await tester.pumpWidget(
      host(OrderCustomerCard(order: orderWith(customer: customer), onTap: () {})),
    );

    // Act
    await tester.pump();

    // Assert
    expect(find.byKey(OrderCustomerCard.chevronKey), findsOneWidget);
  });

  testWidgets('an order whose customer was not sent still says which one it is', (tester) async {
    // Arrange — the list endpoint does not load the customer, and a blank card would be worse
    // than the id nobody says out loud.
    await tester.pumpWidget(host(OrderCustomerCard(order: orderWith())));

    // Act
    await tester.pump();

    // Assert
    expect(find.text('عميل #5'), findsOneWidget);
  });
}
