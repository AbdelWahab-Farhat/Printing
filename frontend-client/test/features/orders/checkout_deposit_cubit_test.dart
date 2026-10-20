import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/place_order_cubit.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/place_order.dart';
import 'package:dayaa_client/features/orders/usecases/quote_basket.dart';
import 'package:dayaa_client/features/shops/models/shop.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

class _MockDesignRepository extends Mock implements DesignRepository {}

class _MockShopRepository extends Mock implements ShopRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockTopUpRepository extends Mock implements TopUpRepository {}

/// خطوة «العربون» في السلة (صاحب العمل، 2026-10-19).
///
/// **ما يُمسك به**: الخطوة تُفتح حين يعرضها الخادم وحده، وتبدأ بأقلّ عربون؛ المبلغ بين الحدّين
/// والمحفظة تكفي إن كانت الطريق؛ وما يُرسل عربونٌ بطريقه ومبلغه، بمفتاحٍ لدفعة المحفظة لا يتغيّر
/// في إعادةٍ بعد انقطاع.
///
/// Arrange - Act - Assert throughout. البضاعة ٥٠٠ د.ل، وأقلّ عربونٍ ١٢٥.
void main() {
  late _MockDeliveryRepository delivery;
  late _MockDesignRepository designs;
  late _MockShopRepository shops;
  late _MockAuthRepository auth;
  late _MockOrderRepository orders;
  late _MockWalletRepository wallet;
  late _MockTopUpRepository topUps;
  late CartCubit cart;

  const benghazi = City(id: 1, name: 'بنغازي', deliveryPrice: '20.00');
  const noor = Shop(id: 5, name: 'متجر النور', cityId: 1, cityName: 'بنغازي');
  const me = CustomerAccount(id: 1, name: 'محمد', phone: '0912345678');

  const bag = OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 2, quantity: '1000'),
    title: 'كيس شحن',
  );

  const offered = BasketQuote(
    lines: [BasketLineQuote(productId: 1, productVariantId: 2, unitPrice: '0.500', lineTotal: '500.00')],
    itemsTotal: '500.00',
    deliveryPrice: '20.00',
    totalWithDelivery: '520.00',
    deposit: DepositOffer(offered: true, minAmount: '125.00', maxAmount: '500.00'),
  );

  const notOffered = BasketQuote(
    lines: [BasketLineQuote(productId: 1, productVariantId: 2)],
    deliveryPrice: '20.00',
  );

  const placed = CustomerOrderDetail(id: 77, code: 'O-77', stageLabel: 'بانتظار العربون');

  TopUpMethods methods({String flow = 'otp', bool enabled = true, String? maxAmount}) => TopUpMethods(
    enabled: enabled,
    feePayer: 'customer',
    methods: [
      TopUpMethod(id: 111, label: 'ليبيانا', flow: flow, feePercentage: '2.5', maxAmount: maxAmount),
    ],
  );

  setUpAll(() {
    registerFallbackValue(const NewOrder(cityId: 0, items: []));
    registerFallbackValue(<NewOrderLine>[]);
  });

  setUp(() {
    delivery = _MockDeliveryRepository();
    designs = _MockDesignRepository();
    shops = _MockShopRepository();
    auth = _MockAuthRepository();
    orders = _MockOrderRepository();
    wallet = _MockWalletRepository();
    topUps = _MockTopUpRepository();
    cart = CartCubit()..add(bag);

    when(() => delivery.cities()).thenAnswer((_) async => const Right([benghazi]));
    when(() => designs.list()).thenAnswer((_) async => const Right(<CustomerDesign>[]));
    when(() => shops.list()).thenAnswer((_) async => const Right([noor]));
    when(() => auth.currentCustomer()).thenAnswer((_) async => const Right(me));
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer((_) async => const Right(offered));
    when(() => orders.place(any())).thenAnswer((_) async => const Right(placed));
    when(() => wallet.balance()).thenAnswer((_) async => const Right('300.00'));
    when(() => topUps.methods()).thenAnswer((_) async => Right(methods()));
  });

  tearDown(() => cart.close());

  PlaceOrderCubit build() => PlaceOrderCubit(
    cities: ListCities(delivery),
    designs: ListDesigns(designs),
    shops: ListShops(shops),
    customer: GetCurrentCustomer(auth),
    quote: QuoteBasket(orders),
    place: PlaceOrder(orders),
    cart: cart,
    walletBalance: GetWalletBalance(wallet),
    topUpMethods: GetTopUpMethods(topUps),
  );

  /// السلة مفتوحةً على «العربون».
  Future<PlaceOrderCubit> onDeposit() async {
    final cubit = build();
    await cubit.load();
    cubit
      ..proceed()
      ..toDeposit();
    await Future<void>.delayed(Duration.zero);

    return cubit;
  }

  PlaceOrderReady stateOf(PlaceOrderCubit cubit) => cubit.state as PlaceOrderReady;

  NewOrder sent() => verify(() => orders.place(captureAny())).captured.last as NewOrder;

  group('opening the step', () {
    test('a basket the server offers a deposit for opens it at the least deposit', () async {
      // Act
      final cubit = await onDeposit();

      // Assert
      final state = stateOf(cubit);
      expect(state.step, CheckoutStep.deposit);
      // بالدينار الكامل: «125.00» من الخادم يُكتب «125».
      expect(state.depositAmount, '125');
      expect(state.walletBalance, '300.00');
      expect(state.payment, isNull);
      expect(state.canSubmit, isFalse);
      await cubit.close();
    });

    test('a basket that is not offered one stays on the details and is sent for review', () async {
      // Arrange
      when(
        () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
      ).thenAnswer((_) async => const Right(notOffered));
      final cubit = build();
      await cubit.load();
      cubit.proceed();

      // Act
      cubit.toDeposit();
      await cubit.submit(recipientPhone: '0912345678');

      // Assert
      final order = sent();
      expect(stateOf(cubit).hasDepositStep, isFalse);
      expect(order.deposit, isNull);
      expect(order.toJson().keys, isNot(contains('deposit')));
      await cubit.close();
    });

    test('«ادفع كامل القيمة» makes the deposit the whole of the goods', () async {
      // Arrange
      final cubit = await onDeposit();

      // Act
      cubit.payFull();

      // Assert
      expect(stateOf(cubit).depositAmount, '500');
      await cubit.close();
    });

    test('each online method the app can use is a row of its own, and QR is not one', () async {
      // Arrange — QR needs a scanner the app has not got.
      when(() => topUps.methods()).thenAnswer((_) async => Right(methods(flow: 'qr')));

      // Act
      final qrOnly = await onDeposit();
      when(() => topUps.methods()).thenAnswer((_) async => Right(methods()));
      final otp = await onDeposit();

      // Assert
      expect(stateOf(qrOnly).onlineMethods, isEmpty);
      expect(stateOf(otp).onlineMethods.map((m) => m.id), [111]);
      await qrOnly.close();
      await otp.close();
    });
  });

  group('the amount', () {
    test('less than a quarter or more than the goods cannot be sent', () async {
      // Arrange
      final cubit = await onDeposit();
      cubit.choosePayment(CheckoutPayment.office);

      // Act - Assert
      cubit.chooseDepositAmount('124');
      expect(stateOf(cubit).depositAmountError, contains('125'));
      expect(stateOf(cubit).canSubmit, isFalse);

      cubit.chooseDepositAmount('501');
      expect(stateOf(cubit).depositAmountError, isNotNull);
      expect(stateOf(cubit).canSubmit, isFalse);

      cubit.chooseDepositAmount('200');
      expect(stateOf(cubit).depositAmountError, isNull);
      expect(stateOf(cubit).canSubmit, isTrue);
      await cubit.close();
    });

    test('arabic digits are read as the amount they are, and a fraction is refused', () async {
      // Arrange
      final cubit = await onDeposit();
      cubit.choosePayment(CheckoutPayment.office);

      // Act - Assert
      cubit.chooseDepositAmount('٢٠٠');
      expect(stateOf(cubit).depositAmount, '200');
      expect(stateOf(cubit).canSubmit, isTrue);

      // بالدينار الكامل (صاحب العمل، 2026-10-19).
      cubit.chooseDepositAmount('200.5');
      expect(stateOf(cubit).depositAmountError, contains('الدينار الكامل'));
      expect(stateOf(cubit).canSubmit, isFalse);
      await cubit.close();
    });

    test('a wallet that does not cover the deposit cannot pay it', () async {
      // Arrange
      when(() => wallet.balance()).thenAnswer((_) async => const Right('100.00'));
      final cubit = await onDeposit();

      // Act
      cubit.choosePayment(CheckoutPayment.wallet);

      // Assert
      expect(stateOf(cubit).walletCovers, isFalse);
      expect(stateOf(cubit).canSubmit, isFalse);
      await cubit.close();
    });
  });

  group('paying online', () {
    test('nothing is sent while the top-up has not happened', () async {
      // Arrange
      final cubit = await onDeposit();
      cubit.chooseOnline(111);

      // Act
      final order = await cubit.submit(recipientPhone: '0912345678');

      // Assert — the owner's rule: the payment succeeds first, then the order.
      expect(stateOf(cubit).canSubmit, isTrue);
      expect(order, isNull);
      verifyNever(() => orders.place(any()));
      await cubit.close();
    });

    test('once topped up the order is sent from the wallet, with the deposit it chose', () async {
      // Arrange — the wallet holds the deposit now.
      final cubit = await onDeposit();
      cubit
        ..chooseDepositAmount('200')
        ..chooseOnline(111);
      when(() => wallet.balance()).thenAnswer((_) async => const Right('200.00'));

      // Act
      await cubit.toppedUp();
      await cubit.submit(recipientPhone: '0912345678');

      // Assert
      final deposit = sent().deposit!;
      expect(stateOf(cubit).walletBalance, '200.00');
      expect(deposit.payment, CheckoutPayment.wallet);
      expect(deposit.amount, '200');
      expect(deposit.clientToken, isNotNull);
      await cubit.close();
    });

    test('a method whose limit cannot take the deposit cannot be paid through', () async {
      // Arrange
      when(() => topUps.methods()).thenAnswer((_) async => Right(methods(maxAmount: '100.00')));
      final cubit = await onDeposit();

      // Act
      cubit.chooseOnline(111);

      // Assert — 125 does not fit in 100.
      expect(stateOf(cubit).canSubmit, isFalse);
      await cubit.close();
    });
  });

  group('sending', () {
    test('at the office it sends the way and the amount, with no key', () async {
      // Arrange
      final cubit = await onDeposit();
      cubit
        ..choosePayment(CheckoutPayment.office)
        ..chooseDepositAmount('200');

      // Act
      final order = await cubit.submit(recipientPhone: '0912345678');

      // Assert
      expect(order, placed);
      expect(sent().toJson()['deposit'], {'payment': 'office', 'amount': '200'});
      expect(cart.state.isEmpty, isTrue);
      await cubit.close();
    });

    test('from the wallet a dropped connection is retried with the same key', () async {
      // Arrange
      when(
        () => orders.place(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا اتصال')));
      final cubit = await onDeposit();
      cubit.choosePayment(CheckoutPayment.wallet);

      // Act
      await cubit.submit(recipientPhone: '0912345678');
      final first = sent().deposit!.clientToken;
      await cubit.submit(recipientPhone: '0912345678');
      final second = sent().deposit!.clientToken;

      // Assert
      expect(first, isNotNull);
      expect(second, first);
      await cubit.close();
    });

    test('a refusal from the server is told under the deposit, and the next try is a new payment', () async {
      // Arrange
      const refusal = ServerFailure(
        message: 'أقل عربون 125.00 د.ل',
        statusCode: 422,
        fieldErrors: {
          'deposit.amount': ['أقل عربون 125.00 د.ل (ربع قيمة الطلبية)'],
        },
      );
      when(() => orders.place(any())).thenAnswer((_) async => const Left(refusal));
      final cubit = await onDeposit();
      cubit.choosePayment(CheckoutPayment.wallet);

      // Act
      await cubit.submit(recipientPhone: '0912345678');
      final first = sent().deposit!.clientToken;
      await cubit.submit(recipientPhone: '0912345678');

      // Assert
      expect(stateOf(cubit).depositServerError, 'أقل عربون 125.00 د.ل (ربع قيمة الطلبية)');
      expect(sent().deposit!.clientToken, isNot(first));
      await cubit.close();
    });
  });

  test('a basket repriced out of its deposit goes back to the details', () async {
    // Arrange
    final cubit = await onDeposit();
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer((_) async => const Right(notOffered));

    // Act — a line changed from a product page while the step was open.
    cart.add(bag.copyWith(line: const NewOrderLine(productId: 9, productVariantId: 9, quantity: '1')));
    await Future<void>.delayed(Duration.zero);

    // Assert
    expect(stateOf(cubit).step, CheckoutStep.details);
    await cubit.close();
  });
}
