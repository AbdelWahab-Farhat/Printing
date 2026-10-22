import 'package:dartz/dartz.dart';
import 'package:dayaa/features/carrier/models/carrier_money_sync.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/carrier_notice_box.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// «لم تُبلَّغ نورس» — what the app reads and says when money moves while a parcel is out.
///
/// **The incident:** a customer paid by transfer while their parcel was with the courier, Nawris
/// refused the change, nobody was told, and the courier collected the full amount anyway. The
/// server now answers with whether Nawris heard; these are the tests that the app reads it and
/// hands it to the screen, before and after the money is taken.
///
/// Arrange - Act - Assert throughout.
void main() {
  PaymentSummary summary() => const PaymentSummary(
    grandTotal: '100.00',
    paidAmount: '40.00',
    remainingAmount: '60.00',
    paymentStatus: PaymentStatus.partiallyPaid,
    paymentStatusLabel: 'مدفوعة جزئياً',
  );

  OrderPayment payment() => const OrderPayment(
    id: 1,
    orderId: 7,
    type: OrderPaymentType.payment,
    typeLabel: 'دفعة',
    amount: '40.00',
    isReversed: false,
    isReversible: true,
    method: PaymentMethod.cash,
    methodLabel: 'كاش',
  );

  // ── reading what the server says ──────────────────────────────────────────────────────

  test('the ledger carries the parcel out with Nawris, for the warning before saving', () {
    // Arrange
    final json = {
      'payments': <Object>[],
      'summary': summary().toJson(),
      'carrier': {
        'parcel_code': '4600741',
        'nawris_asks': '100.00',
        'money_out_of_sync': true,
        'reason': 'مع المندوب',
        'notice': 'الطلبية لدى نورس في الطرد 4600741',
      },
    };

    // Act
    final ledger = OrderLedger.fromJson(json);

    // Assert — and an earlier refusal is said beside the notice.
    expect(ledger.carrier?.parcelCode, '4600741');
    expect(ledger.carrier?.message, contains('الطلبية لدى نورس'));
    expect(ledger.carrier?.message, contains('ما زالت تطلب 100.00'));
  });

  test('a ledger with nothing out says nothing', () {
    // Arrange
    final json = {'payments': <Object>[], 'summary': summary().toJson(), 'carrier': null};

    // Act
    final ledger = OrderLedger.fromJson(json);

    // Assert
    expect(ledger.carrier, isNull);
  });

  test('the order reads the red line off its parcel', () {
    // Arrange
    final json = {
      'code': '4600741',
      'is_open': true,
      'money_out_of_sync': true,
      'nawris_asks': '100.00',
      'sync_error': 'مع المندوب',
    };

    // Act
    final parcel = NawrisParcelRef.fromJson(json);

    // Assert
    expect(parcel.moneyOutOfSync, isTrue);
    expect(parcel.nawrisAsks, '100.00');
    expect(parcel.syncError, 'مع المندوب');
  });

  test('an older server without the fields reads as nothing wrong', () {
    // Act
    final parcel = NawrisParcelRef.fromJson({'code': '4600741'});

    // Assert
    expect(parcel.moneyOutOfSync, isFalse);
    expect(parcel.nawrisAsks, isNull);
  });

  // ── handing it to the screen after saving ─────────────────────────────────────────────

  group('after a payment', () {
    late _MockOrderPaymentRepository repository;
    late OrderPaymentsCubit cubit;

    setUpAll(() => registerFallbackValue(PaymentMethod.cash));

    setUp(() {
      repository = _MockOrderPaymentRepository();
      cubit = OrderPaymentsCubit(
        orderId: 7,
        getLedger: GetOrderLedger(repository),
        recordPayment: RecordOrderPayment(repository),
        refundPayment: RefundOrderPayment(repository),
        reversePayment: ReverseOrderPayment(repository),
        writeOffBalance: WriteOffOrderBalance(repository),
        reviewPayment: ReviewOrderPayment(repository),
        getSettlementAccounts: GetSettlementAccounts(repository),
        settlePayments: SettleOrderPayments(repository),
        unsettlePayment: UnsettleOrderPayment(repository),
      );
      when(
        () => repository.ledger(7),
      ).thenAnswer((_) async => Right(OrderLedger(payments: [payment()], summary: summary())));
    });

    tearDown(() => cubit.close());

    void recordAnswers(CarrierMoneySync? carrier) {
      when(
        () => repository.record(
          7,
          amount: any(named: 'amount'),
          method: any(named: 'method'),
          reference: any(named: 'reference'),
          paidAt: any(named: 'paidAt'),
          notes: any(named: 'notes'),
          receiptPath: any(named: 'receiptPath'),
          receiptFilename: any(named: 'receiptFilename'),
          treasuryAccountId: any(named: 'treasuryAccountId'),
        ),
      ).thenAnswer(
        (_) async => Right(PaymentResult(payment: payment(), summary: summary(), carrier: carrier)),
      );
    }

    test('a refusal is handed to the screen once', () async {
      // Arrange
      recordAnswers(
        const CarrierMoneySync(
          told: false,
          parcelCode: '4600741',
          nawrisAsks: '100.00',
          shouldAsk: '60.00',
          warning: 'لم تقبل نورس تعديل المبلغ',
        ),
      );

      // Act
      final failure = await cubit.record(amount: '40', method: PaymentMethod.cash);

      // Assert — the money stands, the warning is there, and only once.
      expect(failure, isNull);
      expect(cubit.takeCarrierWarning()?.warning, 'لم تقبل نورس تعديل المبلغ');
      expect(cubit.takeCarrierWarning(), isNull);
    });

    test('nothing is said when Nawris took it', () async {
      // Arrange
      recordAnswers(
        const CarrierMoneySync(
          told: true,
          parcelCode: '4600741',
          nawrisAsks: '100.00',
          shouldAsk: '60.00',
        ),
      );

      // Act
      await cubit.record(amount: '40', method: PaymentMethod.cash);

      // Assert
      expect(cubit.takeCarrierWarning(), isNull);
    });

    test('nothing is said when no parcel is out', () async {
      // Arrange
      recordAnswers(null);

      // Act
      await cubit.record(amount: '40', method: PaymentMethod.cash);

      // Assert
      expect(cubit.takeCarrierWarning(), isNull);
    });
  });

  // ── the box in the form ───────────────────────────────────────────────────────────────

  testWidgets('the form says the parcel is with Nawris before anything is saved', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          home: Scaffold(body: CarrierNoticeBox(message: 'الطلبية لدى نورس في الطرد 4600741')),
        ),
      ),
    );

    // Assert
    expect(find.text('الطلبية لدى نورس في الطرد 4600741'), findsOneWidget);
  });
}
