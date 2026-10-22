import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
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
import 'package:dayaa_client/features/orders/presentation/views/place_order_page.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

class _MockDesignRepository extends Mock implements DesignRepository {}

class _MockShopRepository extends Mock implements ShopRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockTopUpRepository extends Mock implements TopUpRepository {}

/// خطوة «العربون» على الشاشة: الدائرة الثالثة، والمبلغ، وطرق الدفع، وما يُرسل.
///
/// Arrange - Act - Assert throughout. البضاعة ٥٠٠ د.ل، وأقلّ عربونٍ ١٢٥.
void main() {
  const benghazi = City(id: 1, name: 'بنغازي', deliveryPrice: '20.00');
  const noor = Shop(id: 5, name: 'متجر النور', cityId: 1, cityName: 'بنغازي');
  const me = CustomerAccount(id: 1, name: 'محمد', phone: '0912345678');

  const bag = OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 2, quantity: '1000'),
    title: 'كيس شحن فلاير',
  );

  const placed = CustomerOrderDetail(id: 77, code: 'O-77', stageLabel: 'بانتظار العربون');

  late _MockOrderRepository orders;
  late CartCubit cart;

  setUpAll(() {
    registerFallbackValue(const NewOrder(cityId: 0, items: []));
    registerFallbackValue(<NewOrderLine>[]);
  });

  tearDown(() async {
    resetSnackBars();
    await cart.close();
    await sl.reset();
  });

  Future<void> open(WidgetTester tester, {String balance = '300.00', bool offered = true}) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final delivery = _MockDeliveryRepository();
    final designs = _MockDesignRepository();
    final shops = _MockShopRepository();
    final auth = _MockAuthRepository();
    final wallet = _MockWalletRepository();
    final topUps = _MockTopUpRepository();
    orders = _MockOrderRepository();
    cart = CartCubit()..add(bag);

    when(() => delivery.cities()).thenAnswer((_) async => const Right([benghazi]));
    when(() => designs.list()).thenAnswer((_) async => const Right(<CustomerDesign>[]));
    when(() => shops.list()).thenAnswer((_) async => const Right([noor]));
    when(() => auth.currentCustomer()).thenAnswer((_) async => const Right(me));
    when(() => orders.place(any())).thenAnswer((_) async => const Right(placed));
    when(() => wallet.balance()).thenAnswer((_) async => Right(balance));
    when(() => topUps.methods()).thenAnswer(
      (_) async => const Right(
        TopUpMethods(
          enabled: true,
          feePayer: 'customer',
          methods: [TopUpMethod(id: 111, label: 'ليبيانا', flow: 'otp', feePercentage: '2.5')],
        ),
      ),
    );
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer(
      (_) async => Right(
        BasketQuote(
          lines: const [
            BasketLineQuote(productId: 1, productVariantId: 2, unitPrice: '0.500', lineTotal: '500.00'),
          ],
          itemsTotal: '500.00',
          deliveryPrice: '20.00',
          totalWithDelivery: '520.00',
          deposit: offered
              ? const DepositOffer(offered: true, minAmount: '125.00', maxAmount: '500.00')
              : const DepositOffer(),
        ),
      ),
    );

    // ورقة الشحن تبني الـ Cubit الخاص بها من `sl`.
    when(
      () => topUps.quote(method: any(named: 'method'), amount: any(named: 'amount')),
    ).thenAnswer((_) async => const Right(TopUpQuote(amount: '125.00', total: '128.21', fee: '3.21')));
    sl
      ..registerLazySingleton(() => GetTopUpMethods(topUps))
      ..registerLazySingleton(() => QuoteTopUp(topUps))
      ..registerLazySingleton(() => StartTopUp(topUps))
      ..registerLazySingleton(() => ConfirmTopUpOtp(topUps))
      ..registerLazySingleton(() => GetTopUpAttempt(topUps));

    sl.registerFactory<PlaceOrderCubit>(
      () => PlaceOrderCubit(
        cities: ListCities(delivery),
        designs: ListDesigns(designs),
        shops: ListShops(shops),
        customer: GetCurrentCustomer(auth),
        quote: QuoteBasket(orders),
        place: PlaceOrder(orders),
        cart: cart,
        walletBalance: GetWalletBalance(wallet),
        topUpMethods: GetTopUpMethods(topUps),
      ),
    );

    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(body: Center(child: Text('الكتالوج'))),
        ),
        GoRoute(path: Routes.newOrder, builder: (context, state) => const PlaceOrderPage()),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) =>
              Scaffold(body: Center(child: Text('طلبية ${state.pathParameters['id']}'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    unawaited(router.push(Routes.newOrder));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();
  }

  Future<void> toDeposit(WidgetTester tester) async {
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
  }

  testWidgets('a basket offered a deposit draws a third step and goes on to it with «التالي»', (
    tester,
  ) async {
    // Arrange
    await open(tester);

    // Assert — «بيانات الطلب» does not send from here.
    expect(find.text('العربون'), findsOneWidget);
    expect(find.text('أرسل الطلبية'), findsNothing);

    // Act
    await toDeposit(tester);

    // Assert
    // Assert — Primula's layout: the amount in whole dinars, «ادفع كامل القيمة», then the ways.
    expect(find.text('حدد طريقة الدفع'), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-office')), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-wallet')), findsOneWidget);
    expect(find.text('أو عبّئ محفظتك وادفع مباشرة'), findsOneWidget);
    expect(find.byKey(const ValueKey('pay-online-111')), findsOneWidget);
    expect(find.byKey(const ValueKey('deposit-pay-full')), findsOneWidget);
    expect(find.text('الرصيد: 300 د.ل'), findsOneWidget);
    final field = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const ValueKey('deposit-amount')), matching: find.byType(EditableText)),
    );
    expect(field.controller.text, '125');
  });

  testWidgets('a basket not offered one keeps two steps and sends for review', (tester) async {
    // Arrange & Act
    await open(tester, offered: false);

    // Assert
    expect(find.text('العربون'), findsNothing);
    expect(find.text('أرسل الطلبية'), findsOneWidget);
  });

  /// «حط العربون تبع صفحة ثانيه وانزع الملاحظة خاصة بالعربون» (طلب المستخدم، 2026-10-20): العربون
  /// خطوته الثالثة، ولا جملة عنه في «بيانات الطلب».
  testWidgets('the details step says nothing about the deposit — it has its own step', (
    tester,
  ) async {
    // Arrange & Act
    await open(tester);

    // Assert — «العربون» الوحيدة اسم الخطوة في الأعلى.
    expect(find.textContaining('العربون'), findsOneWidget);
    expect(find.textContaining('الخطوة التالية'), findsNothing);
  });

  testWidgets('a basket not offered one carries no note under its costs either', (tester) async {
    // Arrange & Act
    await open(tester, offered: false);

    // Assert
    expect(find.textContaining('نراجع الطلبية'), findsNothing);
  });

  testWidgets('«ادفع كامل القيمة» writes the whole amount into the box, and says so', (tester) async {
    // Arrange
    await open(tester);
    await toDeposit(tester);

    // Act
    await tester.tap(find.byKey(const ValueKey('deposit-pay-full')));
    await tester.pumpAndSettle();

    // Assert
    final field = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const ValueKey('deposit-amount')), matching: find.byType(EditableText)),
    );
    expect(field.controller.text, '500');
    expect(find.text('أنت تدفع كامل قيمة الطلبية'), findsOneWidget);
  });

  testWidgets('online, the order is not sent while the top-up has not finished', (tester) async {
    // Arrange
    await open(tester);
    await toDeposit(tester);
    await tester.tap(find.byKey(const ValueKey('pay-online-111')));
    await tester.pumpAndSettle();

    // Act — the sheet opens on the method, with the deposit locked; then it is closed unpaid.
    await tester.tap(find.text('ادفع ثم أرسل الطلبية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final locked = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const ValueKey('top-up-amount')), matching: find.byType(EditableText)),
    );
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    // Assert
    expect(locked.controller.text, '125');
    expect(locked.readOnly, isTrue);
    verifyNever(() => orders.place(any()));
    expect(find.text('حدد طريقة الدفع'), findsOneWidget);
  });

  testWidgets('a wallet that is short says so and cannot be chosen', (tester) async {
    // Arrange
    await open(tester, balance: '100.00');
    await toDeposit(tester);

    // Act
    await tester.tap(find.byKey(const ValueKey('pay-wallet')));
    await tester.pumpAndSettle();

    // Assert — nothing chosen, so nothing can be sent.
    expect(find.textContaining('لا يكفي'), findsOneWidget);
    final send = tester.widget<AppButton>(
      find.ancestor(of: find.text('أرسل الطلبية'), matching: find.byType(AppButton)),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('at the office the deposit is sent with the order, then the order opens', (tester) async {
    // Arrange
    await open(tester);
    await toDeposit(tester);
    await tester.tap(find.byKey(const ValueKey('pay-office')));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أرسل الطلبية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Assert
    final sent = verify(() => orders.place(captureAny())).captured.single as NewOrder;
    expect(sent.deposit?.payment, CheckoutPayment.office);
    expect(sent.deposit?.amount, '125');
    expect(find.textContaining('في المكتب'), findsOneWidget);
    expect(find.text('طلبية 77'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
