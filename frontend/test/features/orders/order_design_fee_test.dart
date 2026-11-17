// dartz exports an `Order` of its own; hidden so the model keeps its name.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_message.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/set_order_design_fee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// «أجرة التصميم» on the staff app — Docs/orders/ORDER-DESIGN-FEE.md.
///
/// Employees never read it on a screen (the server sends them `'0.00'`); whoever holds
/// `orders.design_fee` reads it with a pencil; the invoice and the copied message carry the line
/// the customer pays, whoever produces them.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    String designFee = '0.00',
    String? invoiceDesignFee,
    bool isAuto = false,
    bool canSet = false,
  }) => Order(
    id: 1,
    code: '1',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'in_house',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'تصميم من عندنا',
    itemsTotal: '330.00',
    designFee: designFee,
    invoiceDesignFee: invoiceDesignFee,
    designFeeIsAuto: isAuto,
    canSetDesignFee: canSet,
    deliveryPrice: '0.00',
    discount: '0.00',
    additionalCost: '0.00',
    grandTotal: '430.00',
    remainingAmount: '430.00',
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

  group('the totals card', () {
    testWidgets('an employee without the grant reads no design line', (tester) async {
      // Arrange — what the server sends them: `'0.00'`, and the invoice figure beside it.
      final subject = order(invoiceDesignFee: '100.00');

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject)));

      // Assert
      expect(find.text('أجرة التصميم'), findsNothing);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('the holder reads the fee and taps it to change it', (tester) async {
      // Arrange
      var opened = 0;
      final subject = order(designFee: '100.00', invoiceDesignFee: '100.00', canSet: true);

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject, onSetDesignFee: () => opened++)));
      await tester.tap(find.text('أجرة التصميم'));

      // Assert
      expect(find.text('100'), findsOneWidget);
      expect(opened, 1);
    });

    testWidgets('the holder gets the line at zero, since it is where the pencil lives', (tester) async {
      // Arrange
      final subject = order(canSet: true);

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject, onSetDesignFee: () {})));

      // Assert
      expect(find.text('أجرة التصميم'), findsOneWidget);
    });

    testWidgets('a fee filled from the designer\'s pay says so', (tester) async {
      // Arrange
      final subject = order(designFee: '30.00', invoiceDesignFee: '30.00', isAuto: true, canSet: true);

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject, onSetDesignFee: () {})));

      // Assert
      expect(find.text('تلقائية'), findsOneWidget);
    });

    testWidgets('a fee somebody set carries no mark', (tester) async {
      // Arrange
      final subject = order(designFee: '100.00', invoiceDesignFee: '100.00', canSet: true);

      // Act
      await tester.pumpWidget(host(OrderTotals(order: subject, onSetDesignFee: () {})));

      // Assert
      expect(find.text('تلقائية'), findsNothing);
    });
  });

  group('what goes to the customer', () {
    test('the copied message carries the line even for an employee who cannot see it', () {
      // Arrange
      final subject = order(invoiceDesignFee: '100.00');

      // Act
      final message = OrderMessage.of(subject);

      // Assert
      expect(message, contains('التصميم: 100 د'));
    });

    test('an older server without the invoice figure still prints the fee', () {
      // Arrange — before the split, `design_fee` was the charged line for everybody.
      final subject = order(designFee: '25.00');

      // Act
      final message = OrderMessage.of(subject);

      // Assert
      expect(message, contains('التصميم: 25 د'));
    });
  });

  group('SetOrderDesignFee', () {
    late _MockOrderRepository repository;

    setUp(() {
      repository = _MockOrderRepository();
      when(
        () => repository.setDesignFee(any(), fee: any(named: 'fee')),
      ).thenAnswer((_) async => Right<Failure, Order>(order(designFee: '100.00')));
    });

    test('sends the amount as answered', () async {
      // Arrange
      final setFee = SetOrderDesignFee(repository);

      // Act
      await setFee(7, fee: '100');

      // Assert
      verify(() => repository.setDesignFee(7, fee: '100')).called(1);
    });

    test('an emptied box clears the fee as 0, which is still a decision', () async {
      // Arrange
      final setFee = SetOrderDesignFee(repository);

      // Act
      await setFee(7, fee: null);

      // Assert
      verify(() => repository.setDesignFee(7, fee: '0')).called(1);
    });
  });
}
