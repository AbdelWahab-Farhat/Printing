import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_payments_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// «المحفظة» على دفعات الطلبية — Docs/payments/CUSTOMER-WALLET.md.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> summary({String? walletBalance}) => {
    'grand_total': '100.00',
    'paid_amount': '0.00',
    'remaining_amount': '100.00',
    'payment_status': 'unpaid',
    'payment_status_label': 'غير مدفوعة',
    'wallet_balance': ?walletBalance,
  };

  test('رصيد المحفظة يُقرأ من الملخّص، وزرّها لا يظهر لمحفظةٍ فارغة', () {
    // Arrange & Act
    final full = PaymentSummary.fromJson(summary(walletBalance: '40.00'));
    final empty = PaymentSummary.fromJson(summary(walletBalance: '0.00'));
    // A server from before the wallet sends nothing — read as an empty wallet.
    final old = PaymentSummary.fromJson(summary());

    // Assert
    expect(full.walletBalance, '40.00');
    expect(full.hasWalletMoney, isTrue);
    expect(empty.hasWalletMoney, isFalse);
    expect(old.walletBalance, '0.00');
    expect(old.hasWalletMoney, isFalse);
  });

  test('«المحفظة» لا تُعرض في الدفعة، وتُعرض في الردّ', () {
    // Act & Assert
    expect(PaymentMethod.selectable, isNot(contains(PaymentMethod.wallet)));
    expect(PaymentMethod.selectable, isNot(contains(PaymentMethod.unknown)));
    expect(PaymentMethod.refundable, contains(PaymentMethod.wallet));
    expect(PaymentMethod.refundable, containsAll(PaymentMethod.selectable));
  });

  group('the request key', () {
    late _MockOrderPaymentRepository repository;
    late List<String> issued;

    OrderPaymentsCubit build() {
      var next = 0;

      return OrderPaymentsCubit(
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
        payFromWallet: PayOrderFromWallet(repository),
        newToken: () {
          final token = 'key-${++next}';
          issued.add(token);

          return token;
        },
      );
    }

    setUp(() {
      repository = _MockOrderPaymentRepository();
      issued = [];
      when(() => repository.ledger(7)).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );
    });

    test('a lost answer is retried with the same key, and a success retires it', () async {
      // Arrange — the first attempt never hears back; the retry does.
      const payment = OrderPayment(
        id: 1,
        orderId: 7,
        type: OrderPaymentType.payment,
        typeLabel: 'دفعة',
        amount: '40.00',
        isReversed: false,
        isReversible: true,
        method: PaymentMethod.wallet,
        methodLabel: 'المحفظة',
      );
      final after = PaymentSummary.fromJson(summary(walletBalance: '60.00'));
      var calls = 0;
      when(
        () => repository.payFromWallet(
          7,
          amount: any(named: 'amount'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer((_) async {
        calls++;

        return calls == 1
            ? const Left(Failure.network(message: FailureMessages.noConnection))
            : Right(PaymentResult(payment: payment, summary: after));
      });
      final cubit = build();

      // Act
      final lost = await cubit.payFromWallet(amount: '40');
      final retried = await cubit.payFromWallet(amount: '40');
      await cubit.payFromWallet(amount: '10');

      // Assert
      expect(lost, isNotNull);
      expect(retried, isNull);
      final sent = verify(
        () => repository.payFromWallet(
          7,
          amount: any(named: 'amount'),
          clientToken: captureAny(named: 'clientToken'),
        ),
      ).captured;
      expect(sent, ['key-1', 'key-1', 'key-2']);

      await cubit.close();
    });
  });

  test('دفعةٌ من المحفظة تُقرأ بطريقتها لا «غير معروفة»', () {
    // Arrange
    final json = <String, dynamic>{
      'id': 1,
      'order_id': 2,
      'type': 'payment',
      'type_label': 'دفعة',
      'amount': '40.00',
      'method': 'wallet',
      'method_label': 'المحفظة',
      'is_reversed': false,
      'is_reversible': true,
    };

    // Act
    final payment = OrderPayment.fromJson(json);

    // Assert
    expect(payment.method, PaymentMethod.wallet);
  });
}
