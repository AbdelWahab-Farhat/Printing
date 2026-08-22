import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// Writing off the difference, as the app sees it.
///
/// An order of 110 that came back with 105 in the envelope. The five that never arrived is a
/// **fourth kind of ledger entry** — not a payment, so it never touches «المدفوع», and not a
/// discount, so «سعر الطلبية» goes on saying 110.
///
/// Arrange - Act - Assert throughout.
void main() {
  // ── what comes off the wire ───────────────────────────────────────────────────────────

  group('the summary', () {
    Map<String, dynamic> summary([Map<String, dynamic> overrides = const {}]) => {
      'grand_total': '110.00',
      'paid_amount': '105.00',
      'remaining_amount': '0.00',
      'payment_status': 'written_off',
      'payment_status_label': 'مشطوب فرقها',
      'written_off_amount': '5.00',
      ...overrides,
    };

    test('carries what was forgiven beside what was paid, never inside it', () {
      // Arrange
      final json = summary();

      // Act
      final parsed = PaymentSummary.fromJson(json);

      // Assert — 105 is what came in; the 5 is its own number, and nothing owes any more
      expect(parsed.paidAmount, '105.00');
      expect(parsed.writtenOffAmount, '5.00');
      expect(parsed.grandTotal, '110.00');
      expect(parsed.remainingAmount, '0.00');
      expect(parsed.isOutstanding, isFalse);
    });

    test('«مشطوب فرقها» is its own state, not «مدفوعة بالكامل»', () {
      // Arrange
      final json = summary();

      // Act
      final parsed = PaymentSummary.fromJson(json);

      // Assert
      expect(parsed.paymentStatus, PaymentStatus.writtenOff);
      expect(parsed.hasWriteOff, isTrue);
    });

    test('an order with nothing forgiven says so with a zero, not a blank', () {
      // Arrange
      final json = summary({
        'paid_amount': '110.00',
        'payment_status': 'paid',
        'payment_status_label': 'مدفوعة بالكامل',
        'written_off_amount': '0.00',
      });

      // Act
      final parsed = PaymentSummary.fromJson(json);

      // Assert
      expect(parsed.writtenOffAmount, '0.00');
      expect(parsed.hasWriteOff, isFalse);
    });

    test('a server from before the column existed reads as nothing forgiven', () {
      // Arrange — the field is absent entirely, which is what an old API answers with.
      final json = summary({'payment_status': 'paid', 'payment_status_label': 'مدفوعة بالكامل'})
        ..remove('written_off_amount');

      // Act
      final parsed = PaymentSummary.fromJson(json);

      // Assert — an app that crashed here would be one deploy behind its own server
      expect(parsed.writtenOffAmount, '0.00');
      expect(parsed.hasWriteOff, isFalse);
    });
  });

  group('the entry', () {
    test('a write-off is read as its own type and adds nothing to what was paid', () {
      // Arrange
      final json = {
        'id': 12,
        'order_id': 7,
        'type': 'write_off',
        'type_label': 'شطب فرق',
        'amount': '5.00',
        'method': null,
        'notes': 'الفرق لا يُطالَب به',
        'is_reversible': true,
      };

      // Act
      final entry = OrderPayment.fromJson(json);

      // Assert — no method, because no money moved in either direction
      expect(entry.type, OrderPaymentType.writeOff);
      expect(entry.isIncoming, isFalse);
      expect(entry.isVoid, isFalse);
      expect(entry.method, isNull);
    });

    test('a reversed write-off is struck through like any undone entry', () {
      // Arrange
      final json = {
        'id': 12,
        'order_id': 7,
        'type': 'write_off',
        'type_label': 'شطب فرق',
        'amount': '5.00',
        'is_reversed': true,
      };

      // Act
      final entry = OrderPayment.fromJson(json);

      // Assert
      expect(entry.isVoid, isTrue);
    });
  });

  // ── the Cubit ─────────────────────────────────────────────────────────────────────────

  group('the cubit', () {
    late _MockOrderPaymentRepository repository;
    late OrderPaymentsCubit cubit;

    PaymentSummary summaryWith({
      String paid = '105.00',
      String writtenOff = '0.00',
      String remaining = '5.00',
      PaymentStatus status = PaymentStatus.partiallyPaid,
    }) {
      return PaymentSummary(
        grandTotal: '110.00',
        paidAmount: paid,
        writtenOffAmount: writtenOff,
        remainingAmount: remaining,
        paymentStatus: status,
        paymentStatusLabel: 'مدفوعة جزئياً',
      );
    }

    OrderPayment writeOffEntry() => const OrderPayment(
      id: 12,
      orderId: 7,
      type: OrderPaymentType.writeOff,
      typeLabel: 'شطب فرق',
      amount: '5.00',
    );

    setUp(() {
      repository = _MockOrderPaymentRepository();
      cubit = OrderPaymentsCubit(
        orderId: 7,
        getLedger: GetOrderLedger(repository),
        recordPayment: RecordOrderPayment(repository),
        refundPayment: RefundOrderPayment(repository),
        reversePayment: ReverseOrderPayment(repository),
        writeOffBalance: WriteOffOrderBalance(repository),
      );
    });

    tearDown(() => cubit.close());

    blocTest<OrderPaymentsCubit, OrderPaymentsState>(
      'writing off the difference re-reads the ledger and shows the closed remainder',
      setUp: () {
        when(
          () => repository.writeOff(
            7,
            amount: any(named: 'amount'),
            reason: any(named: 'reason'),
          ),
        ).thenAnswer(
          (_) async => Right(
            PaymentResult(
              payment: writeOffEntry(),
              summary: summaryWith(
                writtenOff: '5.00',
                remaining: '0.00',
                status: PaymentStatus.writtenOff,
              ),
            ),
          ),
        );
        when(() => repository.ledger(7)).thenAnswer(
          (_) async => Right(
            OrderLedger(
              payments: [writeOffEntry()],
              summary: summaryWith(
                writtenOff: '5.00',
                remaining: '0.00',
                status: PaymentStatus.writtenOff,
              ),
            ),
          ),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.writeOff(amount: '5.00', reason: 'الفرق لا يُطالَب به'),
      expect: () => [
        isA<OrderPaymentsLoading>(),
        isA<OrderPaymentsLoaded>()
            .having((s) => s.summary?.writtenOffAmount, 'forgiven', '5.00')
            .having((s) => s.summary?.remainingAmount, 'remaining', '0.00')
            .having((s) => s.summary?.paymentStatus, 'state', PaymentStatus.writtenOff),
      ],
    );

    test('the amount is normalised before it leaves the phone', () async {
      // Arrange — «٥٫٥» is what an Arabic keyboard produces, and the server refuses it
      when(
        () => repository.writeOff(
          7,
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer(
        (_) async => Right(PaymentResult(payment: writeOffEntry(), summary: summaryWith())),
      );
      when(
        () => repository.ledger(7),
      ).thenAnswer((_) async => Right(OrderLedger(payments: const [], summary: summaryWith())));

      // Act
      await cubit.writeOff(amount: '٥٫٥', reason: '  فرق التسليم  ');

      // Assert — the digits converted, and the reason trimmed the way a reversal's is
      verify(() => repository.writeOff(7, amount: '5.5', reason: 'فرق التسليم')).called(1);
    });

    test('a refusal comes back to the caller rather than being parked in the state', () async {
      // Arrange — the sheet that asked is still open, and the message belongs beside its field
      const failure = Failure.server(
        message: 'المبلغ أكبر من المتبقي على الطلبية (5.00)',
        statusCode: 422,
        fieldErrors: {
          'amount': ['المبلغ أكبر من المتبقي على الطلبية (5.00)'],
        },
      );
      when(
        () => repository.writeOff(
          7,
          amount: any(named: 'amount'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => const Left(failure));
      when(
        () => repository.ledger(7),
      ).thenAnswer((_) async => Right(OrderLedger(payments: const [], summary: summaryWith())));

      // Act
      final returned = await cubit.writeOff(amount: '50.00', reason: 'خطأ');

      // Assert
      expect(returned, isA<ServerFailure>());
      expect((returned! as ServerFailure).fieldErrors?['amount'], isNotNull);
    });
  });
}
