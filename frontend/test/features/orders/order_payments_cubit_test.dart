import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:printing/features/orders/repositories/order_payment_repository.dart';
import 'package:printing/features/orders/usecases/manage_order_payments.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

void main() {
  late _MockOrderPaymentRepository repository;
  late OrderPaymentsCubit cubit;

  PaymentSummary summaryWith({
    String paid = '0.00',
    String remaining = '450.00',
    PaymentStatus status = PaymentStatus.unpaid,
    bool unrecorded = false,
  }) {
    return PaymentSummary(
      grandTotal: '450.00',
      paidAmount: paid,
      remainingAmount: remaining,
      paymentStatus: status,
      paymentStatusLabel: 'غير مدفوعة',
      hasUnrecordedMoney: unrecorded,
    );
  }

  OrderPayment paymentWith({
    int id = 1,
    OrderPaymentType type = OrderPaymentType.payment,
    String amount = '150.00',
    bool isReversed = false,
    bool isReversible = true,
  }) {
    return OrderPayment(
      id: id,
      orderId: 7,
      type: type,
      typeLabel: 'دفعة',
      amount: amount,
      isReversed: isReversed,
      isReversible: isReversible,
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
    );
  }

  OrderLedger ledgerWith({List<OrderPayment> payments = const [], PaymentSummary? summary}) {
    return OrderLedger(payments: payments, summary: summary ?? summaryWith());
  }

  setUpAll(() => registerFallbackValue(PaymentMethod.cash));

  setUp(() {
    repository = _MockOrderPaymentRepository();
    cubit = OrderPaymentsCubit(
      orderId: 7,
      getLedger: GetOrderLedger(repository),
      recordPayment: RecordOrderPayment(repository),
      refundPayment: RefundOrderPayment(repository),
      reversePayment: ReverseOrderPayment(repository),
    );
  });

  tearDown(() => cubit.close());

  // ───────────────────────────── loading ─────────────────────────────

  blocTest<OrderPaymentsCubit, OrderPaymentsState>(
    'loading the ledger emits it with its summary',
    setUp: () {
      when(
        () => repository.ledger(7),
      ).thenAnswer((_) async => Right(ledgerWith(payments: [paymentWith()])));
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<OrderPaymentsLoading>(),
      isA<OrderPaymentsLoaded>()
          .having((s) => s.payments.length, 'entries', 1)
          .having((s) => s.summary?.grandTotal, 'total', '450.00'),
    ],
  );

  blocTest<OrderPaymentsCubit, OrderPaymentsState>(
    'a failed load keeps nothing on screen when there was nothing to keep',
    setUp: () {
      when(
        () => repository.ledger(7),
      ).thenAnswer((_) async => const Left(Failure.network(message: 'انقطع الاتصال')));
    },
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<OrderPaymentsLoading>(),
      isA<OrderPaymentsFailure>().having((s) => s.ledger, 'ledger', isNull),
    ],
  );

  // ───────────────────────────── writing ─────────────────────────────

  test('recording a payment re-reads the ledger rather than appending to it', () async {
    // Arrange — the write answers with one entry; the re-read is what the screen shows.
    when(
      () => repository.ledger(7),
    ).thenAnswer((_) async => Right(ledgerWith(payments: [paymentWith()])));
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
      ),
    ).thenAnswer((_) async => Right(PaymentResult(payment: paymentWith(), summary: summaryWith())));

    // Act
    final failure = await cubit.record(amount: '150', method: PaymentMethod.cash);

    // Assert
    expect(failure, isNull);
    expect(cubit.state.payments, hasLength(1));
    verify(() => repository.ledger(7)).called(1);
  });

  test('the amount is normalised before it reaches the API', () async {
    // Arrange — Arabic-Indic digits are what an Arabic keyboard produces.
    when(() => repository.ledger(7)).thenAnswer((_) async => Right(ledgerWith()));
    when(
      () => repository.record(
        any(),
        amount: any(named: 'amount'),
        method: any(named: 'method'),
        reference: any(named: 'reference'),
        paidAt: any(named: 'paidAt'),
        notes: any(named: 'notes'),
        receiptPath: any(named: 'receiptPath'),
        receiptFilename: any(named: 'receiptFilename'),
      ),
    ).thenAnswer((_) async => Right(PaymentResult(payment: paymentWith(), summary: summaryWith())));

    // Act
    await cubit.record(amount: '١٥٠٫٥٠', method: PaymentMethod.cash);

    // Assert
    verify(
      () => repository.record(
        7,
        amount: '150.50',
        method: PaymentMethod.cash,
        reference: null,
        paidAt: null,
        notes: null,
        receiptPath: null,
        receiptFilename: null,
      ),
    ).called(1);
  });

  test('a refused write is reported and the ledger is still re-read', () async {
    // Arrange — the refusal may be *because* somebody else wrote an entry a second earlier, so
    // what is on screen must catch up either way.
    when(() => repository.ledger(7)).thenAnswer((_) async => Right(ledgerWith()));
    when(
      () => repository.record(
        any(),
        amount: any(named: 'amount'),
        method: any(named: 'method'),
        reference: any(named: 'reference'),
        paidAt: any(named: 'paidAt'),
        notes: any(named: 'notes'),
        receiptPath: any(named: 'receiptPath'),
        receiptFilename: any(named: 'receiptFilename'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'المبلغ أكبر من المتبقي على الطلبية')),
    );

    // Act
    final failure = await cubit.record(amount: '5000', method: PaymentMethod.cash);

    // Assert
    expect(failure?.message, 'المبلغ أكبر من المتبقي على الطلبية');
    verify(() => repository.ledger(7)).called(1);
  });

  test(
    'reversing an entry re-reads, because it strikes through a row it does not return',
    () async {
      // Arrange
      when(() => repository.ledger(7)).thenAnswer(
        (_) async => Right(
          ledgerWith(
            payments: [
              paymentWith(isReversed: true, isReversible: false),
              paymentWith(id: 2, type: OrderPaymentType.reversal, isReversible: false),
            ],
          ),
        ),
      );
      when(() => repository.reverse(7, 1, reason: any(named: 'reason'))).thenAnswer(
        (_) async => Right(
          PaymentResult(
            payment: paymentWith(id: 2, type: OrderPaymentType.reversal),
            summary: summaryWith(),
          ),
        ),
      );

      // Act
      final failure = await cubit.reverse(1, reason: '  خطأ في المبلغ  ');

      // Assert
      expect(failure, isNull);
      // Trimmed on the way out: a sentence of spaces satisfies a required check and tells the
      // next reader nothing.
      verify(() => repository.reverse(7, 1, reason: 'خطأ في المبلغ')).called(1);
      expect(cubit.state.payments.first.isReversed, isTrue);
      expect(cubit.state.payments.first.isReversible, isFalse);
    },
  );

  // ───────────────────────────── the model's own answers ─────────────────────────────

  group('normaliseAmount', () {
    test('converts Arabic-Indic digits and the Arabic decimal separator', () {
      // Arrange - Act - Assert
      expect(normaliseAmount('١٥٠٫٥٠'), '150.50');
      expect(normaliseAmount('٥٠'), '50');
    });

    test('drops a comma rather than reading it as a decimal point', () {
      // Arrange — `1,500` is fifteen hundred to whoever typed it, and guessing the other way
      // would turn it into one and a half.
      // Act - Assert
      expect(normaliseAmount('1,500'), '1500');
    });

    test('leaves a plain decimal alone and trims what surrounds it', () {
      expect(normaliseAmount('  150.50  '), '150.50');
    });
  });

  group('PaymentMethod', () {
    test('only a transfer demands a receipt', () {
      // Arrange - Act - Assert
      expect(PaymentMethod.bankTransfer.requiresReceipt, isTrue);
      expect(PaymentMethod.cash.requiresReceipt, isFalse);
      expect(PaymentMethod.bankCard.requiresReceipt, isFalse);
      expect(PaymentMethod.libyana.requiresReceipt, isFalse);
    });

    test('the unknown case is never offered to a person', () {
      // Arrange — it exists so an entry written by a newer server still renders.
      // Act
      final selectable = PaymentMethod.selectable;

      // Assert
      expect(selectable, hasLength(4));
      expect(selectable.contains(PaymentMethod.unknown), isFalse);
    });
  });

  group('OrderPayment', () {
    test('a reversal and a reversed entry both count for nothing', () {
      // Arrange - Act - Assert
      expect(paymentWith(isReversed: true).isVoid, isTrue);
      expect(paymentWith(type: OrderPaymentType.reversal).isVoid, isTrue);
      expect(paymentWith().isVoid, isFalse);
    });

    test('only a payment is incoming', () {
      expect(paymentWith().isIncoming, isTrue);
      expect(paymentWith(type: OrderPaymentType.refund).isIncoming, isFalse);
      expect(paymentWith(type: OrderPaymentType.reversal).isIncoming, isFalse);
    });
  });

  group('PaymentSummary', () {
    test('something is outstanding while the order is unpaid or part-paid', () {
      // Arrange - Act - Assert
      expect(summaryWith().isOutstanding, isTrue);
      expect(summaryWith(status: PaymentStatus.partiallyPaid).isOutstanding, isTrue);
      expect(summaryWith(status: PaymentStatus.paid).isOutstanding, isFalse);
      expect(summaryWith(status: PaymentStatus.overpaid).isOutstanding, isFalse);
    });
  });
}
