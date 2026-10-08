import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_payments_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_money_row.dart';
import 'package:dayaa/features/orders/presentation/widgets/overpayment_confirmation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentsCubit extends MockCubit<OrderPaymentsState> implements OrderPaymentsCubit {}

/// «الزائد إيراد» on the phone — 100 handed over on 99, and the dinar is the shop's at once.
///
/// **The arithmetic is fixed-point and the wording lives in one place.** The excess is a figure
/// somebody reads aloud, so it is asserted to the cent; and the question is asked the same way
/// from the payments screen and the status screen. Since 2026-10-07 nothing is owed back to the
/// customer, so no screen says so and no button decides it.
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
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  group('how much is beyond the debt', () {
    test('100 on 99 is one dinar beyond', () {
      expect(overpaymentExcess('100', '99.00'), '1.00');
    });

    test('exactly what is owed, or less, is nothing beyond', () {
      expect(overpaymentExcess('99', '99.00'), isNull);
      expect(overpaymentExcess('50.5', '99.00'), isNull);
    });

    test('Arabic digits and the Arabic decimal point read as the clerk typed them', () {
      expect(overpaymentExcess('١٠٠٫٥', '99.00'), '1.50');
    });

    test('an order already overpaid owes nothing, so all of it is beyond', () {
      expect(overpaymentExcess('3', '-5.00'), '3.00');
    });

    test('an empty box asks nothing', () {
      expect(overpaymentExcess('', '99.00'), isNull);
    });
  });

  testWidgets('the question says the figure, and a yes is a yes', (tester) async {
    // Arrange
    bool? answer;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await confirmOverpayment(context, excess: '1.00'),
            child: const Text('سجّل'),
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.text('سجّل'));
    await tester.pumpAndSettle();
    final asked = find.textContaining('الزائد 1 يُسجَّل إيراداً').evaluate().isNotEmpty;
    final saysOwed = find.textContaining('للزبون').evaluate().isNotEmpty;
    await tester.tap(find.byKey(const ValueKey('accept-overpayment')));
    await tester.pumpAndSettle();

    // Assert
    expect(asked, isTrue);
    expect(saysOwed, isFalse);
    expect(answer, isTrue);
  });

  testWidgets('declining sends nothing', (tester) async {
    // Arrange
    bool? answer;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer = await confirmOverpayment(context, excess: '1.00'),
            child: const Text('سجّل'),
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.text('سجّل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer, isFalse);
  });

  testWidgets('the order never says it owes the customer, even with an excess from before', (tester) async {
    // Arrange — طلبيةٌ حملت زائداً قبل ٢٠٢٦-١٠-٠٧ ولم تُحسب بعدُ من جديد.
    const summary = PaymentSummary(
      grandTotal: '99.00',
      paidAmount: '99.00',
      excessAmount: '1.00',
      remainingAmount: '0.00',
      paymentStatus: PaymentStatus.overpaid,
      paymentStatusLabel: 'مدفوعة بالزيادة',
    );

    // Act
    await tester.pumpWidget(host(const SingleChildScrollView(child: OrderMoneyRow(summary: summary))));

    // Assert
    expect(find.byKey(const ValueKey('excess-line')), findsNothing);
    expect(find.textContaining('زائد للزبون'), findsNothing);
  });

  group('the payments screen', () {
    late _MockOrderPaymentsCubit cubit;

    setUp(() async {
      await Injector.reset();
      cubit = _MockOrderPaymentsCubit();
      when(() => cubit.load()).thenAnswer((_) async {});
      sl
        ..registerFactoryParam<OrderPaymentsCubit, int, void>((_, _) => cubit)
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              AuthUser(
                id: 1,
                name: 'فرحات',
                phone: '0911234567',
                permissions: [for (final permission in AppPermission.values) permission.wire],
              ),
            ),
        );
    });

    tearDown(Injector.reset);

    Future<void> open(WidgetTester tester, {required String excessOnOrder}) async {
      final ledger = OrderLedger(
        payments: const [
          OrderPayment(
            id: 1,
            orderId: 7,
            type: OrderPaymentType.payment,
            typeLabel: 'دفعة',
            amount: '140.00',
            excessAmount: '5.00',
            method: PaymentMethod.cash,
            methodLabel: 'كاش',
          ),
        ],
        summary: PaymentSummary(
          grandTotal: '185.00',
          paidAmount: '185.00',
          excessAmount: excessOnOrder,
          remainingAmount: '0.00',
          paymentStatus: PaymentStatus.paid,
          paymentStatusLabel: 'مدفوعة بالكامل',
        ),
      );
      when(() => cubit.state).thenReturn(OrderPaymentsState.loaded(ledger: ledger));

      await tester.pumpWidget(host(const OrderPaymentsPage(orderId: 7, orderCode: '1294')));
      await tester.pump();
    }

    testWidgets('the row that carried an excess calls it revenue', (tester) async {
      // Act
      await open(tester, excessOnOrder: '0.00');

      // Assert
      expect(find.text('منها زائد 5 د.ل · إيراد'), findsOneWidget);
      expect(find.textContaining('زائد للزبون'), findsNothing);
    });

    testWidgets('there is no button that decides the excess, even for somebody holding everything', (
      tester,
    ) async {
      // Act — حتى طلبيةٌ تحمل زائداً من قبل القرار.
      await open(tester, excessOnOrder: '5.00');

      // Assert
      expect(find.text('اعتبار الزائد إيراداً'), findsNothing);
      expect(find.text('تسجيل دفعة'), findsOneWidget);
    });
  });

  test('«مدفوعة بالزيادة» can be filtered by now', () {
    expect(PaymentStatus.filterable, contains(PaymentStatus.overpaid));
  });
}
