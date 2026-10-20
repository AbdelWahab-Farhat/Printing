import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_deposit_cubit.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/choose_order_deposit.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockTopUpRepository extends Mock implements TopUpRepository {}

/// العربون على طلبيةٍ قبلها المتجر بعد المراجعة (صاحب العمل، 2026-10-19) — قواعد السلة نفسها.
///
/// Arrange - Act - Assert throughout. البضاعة ٥٠٠ د.ل، وأقلّ عربونٍ ١٢٥.
void main() {
  late _MockOrderRepository orders;
  late _MockWalletRepository wallet;
  late _MockTopUpRepository topUps;

  const offer = DepositOffer(offered: true, minAmount: '125.00', maxAmount: '500.00');
  const accepted = CustomerOrderDetail(id: 9, code: '9', stageLabel: 'قيد التجهيز', depositOffer: offer);
  const waiting = CustomerOrderDetail(id: 9, code: '9', stageLabel: 'بانتظار العربون');

  setUpAll(() => registerFallbackValue(const CheckoutDeposit(payment: CheckoutPayment.office, amount: '0')));

  setUp(() {
    orders = _MockOrderRepository();
    wallet = _MockWalletRepository();
    topUps = _MockTopUpRepository();

    when(() => orders.chooseDeposit(any(), any())).thenAnswer((_) async => const Right(waiting));
    when(() => wallet.balance()).thenAnswer((_) async => const Right('300.00'));
    when(() => topUps.methods()).thenAnswer(
      (_) async => const Right(
        TopUpMethods(
          enabled: true,
          feePayer: 'customer',
          methods: [TopUpMethod(id: 111, label: 'ليبيانا', flow: 'otp', feePercentage: '2.5')],
        ),
      ),
    );
  });

  Future<OrderDepositCubit> loaded() async {
    final cubit = OrderDepositCubit(
      order: accepted,
      choose: ChooseOrderDeposit(orders),
      walletBalance: GetWalletBalance(wallet),
      topUpMethods: GetTopUpMethods(topUps),
    );
    await cubit.load();

    return cubit;
  }

  CheckoutDeposit sent() => verify(() => orders.chooseDeposit(9, captureAny())).captured.last as CheckoutDeposit;

  test('starts at the least deposit in whole dinars, with the wallet and the online methods read', () async {
    // Act
    final cubit = await loaded();

    // Assert
    expect(cubit.state.amount, '125');
    expect(cubit.state.walletBalance, '300.00');
    expect(cubit.state.onlineMethods.map((m) => m.id), [111]);
    expect(cubit.state.isReady, isFalse);
    await cubit.close();
  });

  test('at the office it sends the way and the amount, with no key', () async {
    // Arrange
    final cubit = await loaded();
    cubit
      ..chooseAmount('٢٠٠')
      ..choosePayment(CheckoutPayment.office);

    // Act
    final order = await cubit.submit();

    // Assert
    expect(order, waiting);
    expect(sent().toJson(), {'payment': 'office', 'amount': '200'});
    await cubit.close();
  });

  test('a fraction or less than a quarter cannot be sent', () async {
    // Arrange
    final cubit = await loaded();
    cubit.choosePayment(CheckoutPayment.office);

    // Act - Assert
    cubit.chooseAmount('124');
    expect(cubit.state.isReady, isFalse);
    cubit.chooseAmount('200.5');
    expect(cubit.state.amountError, contains('الدينار الكامل'));
    expect(await cubit.submit(), isNull);
    verifyNever(() => orders.chooseDeposit(any(), any()));
    await cubit.close();
  });

  test('online sends nothing until topped up, then sends from the wallet', () async {
    // Arrange
    final cubit = await loaded();
    cubit.chooseOnline(111);

    // Act - Assert — the owner's rule: the payment first.
    expect(await cubit.submit(), isNull);
    verifyNever(() => orders.chooseDeposit(any(), any()));

    await cubit.toppedUp();
    await cubit.submit();

    final deposit = sent();
    expect(deposit.payment, CheckoutPayment.wallet);
    expect(deposit.amount, '125');
    expect(deposit.clientToken, isNotNull);
    await cubit.close();
  });

  test('a refusal is told under the amount, and the order stays as it was', () async {
    // Arrange
    when(() => orders.chooseDeposit(any(), any())).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          message: 'أقل عربون 125 د.ل',
          statusCode: 422,
          fieldErrors: {
            'amount': ['أقل عربون 125 د.ل (ربع قيمة الطلبية)'],
          },
        ),
      ),
    );
    final cubit = await loaded();
    cubit.choosePayment(CheckoutPayment.office);

    // Act
    final order = await cubit.submit();

    // Assert
    expect(order, isNull);
    expect(cubit.state.amountServerError, 'أقل عربون 125 د.ل (ربع قيمة الطلبية)');
    expect(cubit.state.isSubmitting, isFalse);
    await cubit.close();
  });
}
