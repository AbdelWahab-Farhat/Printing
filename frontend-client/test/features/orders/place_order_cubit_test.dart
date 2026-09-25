import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

class _MockDesignRepository extends Mock implements DesignRepository {}

class _MockShopRepository extends Mock implements ShopRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockOrderRepository extends Mock implements OrderRepository {}

/// السلة معالجاً من خطوتين: «المنتجات» ثم «بيانات الطلب».
///
/// **الخطوة الثانية تُملأ من الحساب**: أول متاجر العميل مختارٌ ومدينته ومنطقته معه، ورقم هاتفه في
/// حقل الاستلام. ولا اسمَ مستلمٍ ولا عنوانَ حرّاً في ما يُرسل — المستلم هو العميل نفسه.
///
/// **والسلة تُسعَّر من الخادم** كلما تغيّر ما يغيّر السعر — سطورها أو مدينتها — كي تعرض التكلفة
/// النهائية كما تعرضها تطبيقات التسوّق، بلا أن يضرب التطبيق سعراً في كمية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockDeliveryRepository delivery;
  late _MockDesignRepository designs;
  late _MockShopRepository shops;
  late _MockAuthRepository auth;
  late _MockOrderRepository orders;
  late CartCubit cart;

  const kish = Region(id: 10, cityId: 1, name: 'الكيش');
  const benghazi = City(id: 1, name: 'بنغازي', deliveryPrice: '20.00', regions: [kish]);
  const tripoli = City(id: 2, name: 'طرابلس', deliveryPrice: '15.00');

  const noor = Shop(
    id: 5,
    name: 'متجر النور',
    cityId: 1,
    cityName: 'بنغازي',
    regionId: 10,
    regionName: 'الكيش',
  );
  const amal = Shop(id: 6, name: 'متجر الأمل', cityId: 2, cityName: 'طرابلس');

  const me = CustomerAccount(id: 1, name: 'محمد', phone: '0912345678');
  const logo = CustomerDesign(id: 3, label: 'الشعار', kind: DesignKind.image);

  const bag = OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 2, quantity: '1000'),
    title: 'كيس شحن',
  );

  const quote = BasketQuote(
    lines: [
      BasketLineQuote(
        productId: 1,
        productVariantId: 2,
        unitLabel: 'قطعة',
        unitPrice: '0.500',
        lineTotal: '500.00',
      ),
    ],
    itemsTotal: '500.00',
    deliveryPrice: '20.00',
    totalWithDelivery: '520.00',
  );

  const priced = BasketPricing.priced(quote);

  const placed = CustomerOrderDetail(id: 77, code: 'O-77', stageLabel: 'بانتظار المراجعة');

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
    cart = CartCubit()..add(bag);

    when(() => delivery.cities()).thenAnswer((_) async => const Right([benghazi, tripoli]));
    when(() => designs.list()).thenAnswer((_) async => const Right([logo]));
    when(() => shops.list()).thenAnswer((_) async => const Right([noor, amal]));
    when(() => auth.currentCustomer()).thenAnswer((_) async => const Right(me));
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer((_) async => const Right(quote));
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
  );

  PlaceOrderReady ready({
    List<Shop> shopList = const [noor, amal],
    List<OrderDraftLine> lines = const [bag],
    CheckoutStep step = CheckoutStep.products,
    int? shopId = 5,
    int? cityId = 1,
    int? regionId = 10,
    BasketPricing pricing = priced,
  }) => PlaceOrderReady(
    cities: const [benghazi, tripoli],
    designs: const [logo],
    shops: shopList,
    lines: lines,
    step: step,
    shopId: shopId,
    cityId: cityId,
    regionId: regionId,
    customerPhone: '0912345678',
    pricing: pricing,
  );

  group('load', () {
    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'opens on the products, with the first shop and the account’s phone already filled in',
      // Arrange
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const PlaceOrderState.loading(),
        ready(pricing: const BasketPricing.pending()),
        ready(),
      ],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'an account with no shops chooses its destination by hand',
      // Arrange
      build: () {
        when(() => shops.list()).thenAnswer((_) async => const Right(<Shop>[]));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => [
        const PlaceOrderState.loading(),
        ready(
          shopList: const [],
          shopId: null,
          cityId: null,
          regionId: null,
          pricing: const BasketPricing.pending(),
        ),
        ready(shopList: const [], shopId: null, cityId: null, regionId: null),
      ],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'a shop whose city left the map is chosen, but its city is left for the customer to pick',
      // Arrange
      build: () {
        when(() => shops.list()).thenAnswer(
          (_) async => Right([noor.copyWith(cityId: 99, regionId: null)]),
        );

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      skip: 2,
      expect: () => [
        ready(
          shopList: [noor.copyWith(cityId: 99, regionId: null)],
          cityId: null,
          regionId: null,
        ),
      ],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'the shops failing to load stops the screen — «no shops» would be a lie that invites a '
      'duplicate',
      // Arrange
      build: () {
        when(() => shops.list())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        PlaceOrderState.loading(),
        PlaceOrderState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
      ],
      verify: (_) => verifyNever(
        () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
      ),
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'the account failing to load leaves the phone for the customer to type, and stops nothing',
      // Arrange
      build: () {
        when(() => auth.currentCustomer())
            .thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      skip: 2,
      expect: () => [ready().copyWith(customerPhone: null)],
    );
  });

  group('pricing', () {
    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'the basket is priced once the screen is ready, with the chosen shop’s city for delivery',
      // Arrange
      build: build,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      verify: (cubit) {
        verify(() => orders.quote(items: [bag.line], cityId: 1)).called(1);
        expect(cubit.state.quote, quote);
      },
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'a pricing that fails leaves the order sendable — the shop prices it anyway',
      // Arrange
      build: () {
        when(
          () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
        ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

        return build();
      },
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      skip: 2,
      expect: () => [
        ready(pricing: const BasketPricing.failed(NetworkFailure(message: 'لا يوجد اتصال'))),
      ],
      verify: (cubit) => expect(cubit.state.canSubmit, isTrue),
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'another city re-prices the basket, for its delivery',
      // Arrange
      build: build,
      seed: ready,
      // Act
      act: (cubit) => cubit.chooseCity(2),
      // Assert
      expect: () => [
        ready(cityId: 2, regionId: null, pricing: const BasketPricing.pending()),
        ready(cityId: 2, regionId: null),
      ],
      verify: (_) => verify(() => orders.quote(items: [bag.line], cityId: 2)).called(1),
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'a region does not re-price — delivery is by city',
      // Arrange
      build: build,
      seed: () => ready(regionId: null),
      // Act
      act: (cubit) => cubit.chooseRegion(10),
      // Assert
      expect: () => [ready()],
      verify: (_) => verifyNever(
        () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
      ),
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'removing a line re-prices what is left',
      // Arrange
      build: () {
        cart.add(bag.copyWith(line: const NewOrderLine(productId: 7, productVariantId: 8, quantity: '5')));

        return build();
      },
      seed: () => ready(lines: cart.state.lines),
      // Act
      act: (cubit) => cubit.removeLineAt(0),
      // Assert
      verify: (_) {
        expect(cart.state.lines.single.line.productId, 7);
        verify(
          () => orders.quote(
            items: [const NewOrderLine(productId: 7, productVariantId: 8, quantity: '5')],
            cityId: 1,
          ),
        ).called(1);
      },
    );

    test('a quantity changed on the product page arrives in the basket, re-priced', () async {
      // Arrange — السلة لقطةٌ في الحالة، والعميل عاد من صفحة المنتج بكميةٍ أخرى.
      final cubit = build();
      await cubit.load();
      final more = bag.copyWith(line: bag.line.copyWith(quantity: '2000'));

      // Act
      cart.add(more);
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect((cubit.state as PlaceOrderReady).lines.single.line.quantity, '2000');
      verify(() => orders.quote(items: [more.line], cityId: 1)).called(1);
      await cubit.close();
    });

    test('an answer for an older basket is dropped when a newer one was asked', () async {
      // Arrange — تبديل المدينة مرتين بسرعة، والجواب الأول يصل بعد الثاني.
      final slow = Completer<Either<Failure, BasketQuote>>();
      const tripoliQuote = BasketQuote(itemsTotal: '500.00', deliveryPrice: '15.00');
      when(() => orders.quote(items: any(named: 'items'), cityId: 2)).thenAnswer((_) => slow.future);
      when(
        () => orders.quote(items: any(named: 'items'), cityId: 1),
      ).thenAnswer((_) async => const Right(quote));
      final cubit = build()..emit(ready());

      // Act
      cubit
        ..chooseCity(2)
        ..chooseCity(1);
      await Future<void>.delayed(Duration.zero);
      slow.complete(const Right(tripoliQuote));
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(cubit.state.quote, quote);
      await cubit.close();
    });

    test('an empty basket is not priced', () async {
      // Arrange
      final cubit = build()..emit(ready(lines: const []));

      // Act
      cubit.chooseCity(2);
      await Future<void>.delayed(Duration.zero);

      // Assert
      verifyNever(() => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')));
      await cubit.close();
    });
  });

  group('the steps', () {
    blocTest<PlaceOrderCubit, PlaceOrderState>(
      '«إتمام الطلب» moves on to the details',
      // Arrange
      build: build,
      seed: ready,
      // Act
      act: (cubit) => cubit.proceed(),
      // Assert
      expect: () => [ready(step: CheckoutStep.details)],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'an empty basket has no details step to move on to',
      // Arrange
      build: build,
      seed: () => ready(lines: const []),
      // Act
      act: (cubit) => cubit.proceed(),
      // Assert
      expect: () => const <PlaceOrderState>[],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      '«السابق» returns to the products with every choice kept',
      // Arrange
      build: build,
      seed: () => ready(step: CheckoutStep.details, shopId: 6, cityId: 2, regionId: null),
      // Act
      act: (cubit) => cubit.back(),
      // Assert
      expect: () => [ready(shopId: 6, cityId: 2, regionId: null)],
    );
  });

  group('the shop', () {
    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'choosing a shop sends the order to its city, clears a region from elsewhere, and re-prices',
      // Arrange
      build: build,
      seed: () => ready(step: CheckoutStep.details),
      // Act
      act: (cubit) => cubit.chooseShop(6),
      // Assert
      expect: () => [
        ready(
          step: CheckoutStep.details,
          shopId: 6,
          cityId: 2,
          regionId: null,
          pricing: const BasketPricing.pending(),
        ),
        ready(step: CheckoutStep.details, shopId: 6, cityId: 2, regionId: null),
      ],
    );

    blocTest<PlaceOrderCubit, PlaceOrderState>(
      'another city keeps the shop — bags for this shop may still be collected elsewhere',
      // Arrange
      build: build,
      seed: () => ready(step: CheckoutStep.details),
      // Act
      act: (cubit) => cubit.chooseCity(2),
      // Assert
      skip: 1,
      expect: () => [ready(step: CheckoutStep.details, cityId: 2, regionId: null)],
    );
  });

  group('submit', () {
    test('sends the shop, the destination and the phone — and no name or address', () async {
      // Arrange
      when(() => orders.place(any())).thenAnswer((_) async => const Right(placed));
      final cubit = build();
      await cubit.load();
      cubit
        ..proceed()
        ..toggleDesign(3);

      // Act
      final order = await cubit.submit(recipientPhone: ' 0923456789 ', note: '  ');

      // Assert
      expect(order, placed);
      final sent = verify(() => orders.place(captureAny())).captured.single as NewOrder;
      expect(sent.customerShopId, 5);
      expect(sent.cityId, 1);
      expect(sent.regionId, 10);
      expect(sent.recipientPhone, '0923456789');
      expect(sent.customerNote, isNull);
      expect(sent.designIds, [3]);
      expect(sent.items, [bag.line]);
      expect(sent.toJson().keys, isNot(contains('recipient_name')));
      expect(sent.toJson().keys, isNot(contains('address_details')));
      await cubit.close();
    });

    test('the basket empties only once the shop has the order', () async {
      // Arrange
      when(() => orders.place(any())).thenAnswer((_) async => const Right(placed));
      final cubit = build();
      await cubit.load();

      // Act
      await cubit.submit(recipientPhone: '0912345678');
      await Future<void>.delayed(Duration.zero);

      // Assert — والسلة التي فرغت لا تُعيد تسعير شيءٍ على شاشةٍ أُرسلت طلبيتها.
      expect(cart.state.isEmpty, isTrue);
      expect((cubit.state as PlaceOrderReady).placed, placed);
      verify(() => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')))
          .called(1);
      await cubit.close();
    });

    test('a refused order keeps the basket and every choice, with the reason beside them', () async {
      // Arrange
      const refusal = ServerFailure(message: 'المدينة غير موجودة', statusCode: 422);
      when(() => orders.place(any())).thenAnswer((_) async => const Left(refusal));
      final cubit = build();
      await cubit.load();
      cubit.proceed();

      // Act
      final order = await cubit.submit(recipientPhone: '0912345678');

      // Assert
      expect(order, isNull);
      expect(cart.state.lines, [bag]);
      expect(cubit.state, ready(step: CheckoutStep.details).copyWith(lastFailure: refusal));
      await cubit.close();
    });
  });
}
