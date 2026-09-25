import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_thumbnail.dart';
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
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// السلة على الشاشة: شريط الخطوتين، وما تملؤه الخطوة الثانية من الحساب، وما لم يعد فيها.
///
/// Arrange - Act - Assert throughout.
void main() {
  const kish = Region(id: 10, cityId: 1, name: 'الكيش');
  const benghazi = City(id: 1, name: 'بنغازي', deliveryPrice: '20.00', regions: [kish]);
  const tripoli = City(id: 2, name: 'طرابلس', deliveryPrice: '25.00');

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

  const bag = OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 2, quantity: '1000'),
    title: 'كيس شحن فلاير',
  );

  const placed = CustomerOrderDetail(id: 77, code: 'O-77', stageLabel: 'بانتظار المراجعة');

  const logo = CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image);
  const flyer = CustomerDesign(id: 2, label: 'تصميم الكيس', kind: DesignKind.pdf);

  late _MockShopRepository shops;
  late _MockOrderRepository orders;
  late CartCubit cart;
  late GoRouter router;

  setUpAll(() {
    registerFallbackValue(const NewOrder(cityId: 0, items: []));
    registerFallbackValue(<NewOrderLine>[]);
  });

  tearDown(() async {
    resetSnackBars();
    await cart.close();
    await sl.reset();
  });

  /// السلة فوق شاشةٍ تحتها، ليكون للرجوع منها مكانٌ حقيقي يصل إليه.
  Future<void> open(
    WidgetTester tester, {
    List<Shop> accountShops = const [noor],
    List<CustomerDesign> library = const [],
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final delivery = _MockDeliveryRepository();
    final designs = _MockDesignRepository();
    final auth = _MockAuthRepository();
    shops = _MockShopRepository();
    orders = _MockOrderRepository();
    cart = CartCubit()..add(bag);

    when(() => delivery.cities()).thenAnswer((_) async => const Right([benghazi, tripoli]));
    when(() => designs.list()).thenAnswer((_) async => Right(library));
    when(() => shops.list()).thenAnswer((_) async => Right(accountShops));
    when(() => auth.currentCustomer()).thenAnswer((_) async => const Right(me));
    when(() => orders.place(any())).thenAnswer((_) async => const Right(placed));
    // الخادم يسعّر ١٠٠٠ قطعة بـ٥٠٠، ويضيف توصيل المدينة التي سُئل عنها.
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer((invocation) async {
      final delivery = switch (invocation.namedArguments[#cityId]) {
        1 => '20.00',
        2 => '25.00',
        _ => null,
      };

      return Right(
        BasketQuote(
          lines: const [
            BasketLineQuote(
              productId: 1,
              productVariantId: 2,
              unitLabel: 'قطعة',
              unitPrice: '0.500',
              lineTotal: '500.00',
            ),
          ],
          itemsTotal: '500.00',
          deliveryPrice: delivery,
          totalWithDelivery: switch (delivery) {
            '20.00' => '520.00',
            '25.00' => '525.00',
            _ => null,
          },
        ),
      );
    });

    sl.registerFactory<PlaceOrderCubit>(
      () => PlaceOrderCubit(
        cities: ListCities(delivery),
        designs: ListDesigns(designs),
        shops: ListShops(shops),
        customer: GetCurrentCustomer(auth),
        quote: QuoteBasket(orders),
        place: PlaceOrder(orders),
        cart: cart,
      ),
    );

    router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(body: Center(child: Text('الكتالوج'))),
        ),
        GoRoute(path: Routes.newOrder, builder: (context, state) => const PlaceOrderPage()),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) =>
              Scaffold(body: Center(child: Text('منتج ${state.pathParameters['id']}'))),
        ),
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    unawaited(router.push(Routes.newOrder));
    await tester.pumpAndSettle();
  }

  /// الـ Cubit من داخل الشاشة، لتحريك الخطوة بلا لمسةٍ ترسم موجةً متحرّكة من عندها.
  PlaceOrderCubit cubitOf(WidgetTester tester) =>
      tester.element(find.byType(EasyStepper)).read<PlaceOrderCubit>();

  Future<void> proceed(WidgetTester tester) async {
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();
  }

  group('the products step', () {
    testWidgets('opens on the products, with both steps drawn across the top', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.byType(EasyStepper), findsOneWidget);
      expect(find.text('المنتجات'), findsOneWidget);
      expect(find.text('بيانات الطلب'), findsOneWidget);
      expect(find.text('كيس شحن فلاير'), findsOneWidget);
      expect(find.text('إتمام الطلب'), findsOneWidget);
      expect(find.text('هاتف الاستلام'), findsNothing);
    });

    testWidgets('an emptied basket shows the empty basket, and no «إتمام الطلب» under it', (
      tester,
    ) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.byTooltip('احذف'));
      await tester.pumpAndSettle();

      // Assert — رسم السلة الفارغة يحمل زرّه، فلا زرّ معطّلٌ ثانٍ تحته.
      expect(find.text('سلتك فارغة'), findsOneWidget);
      expect(find.text('إتمام الطلب'), findsNothing);
      expect(cubitOf(tester).state.canProceed, isFalse);
    });

    testWidgets('each line shows what it costs, as the server priced it', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.text('500 د.ل'), findsWidgets);
      expect(
        find.descendant(of: find.byType(AppCard), matching: find.text('500 د.ل')),
        findsOneWidget,
      );
    });

    testWidgets('the goods total sits beside «إتمام الطلب»', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.text('المجموع'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('المجموع')).dy,
        lessThan(tester.getTopLeft(find.text('إتمام الطلب')).dy),
      );
    });

    testWidgets('a line opens its product, to change the size or the quantity', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.text('كيس شحن فلاير'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('منتج 1'), findsOneWidget);
    });
  });

  group('the details step', () {
    testWidgets('is filled from the account: the first shop, its city, and the phone', (
      tester,
    ) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);

      // Assert
      expect(find.text('متجر النور'), findsOneWidget);
      expect(find.text('بنغازي'), findsWidgets);
      expect(find.text('الكيش'), findsWidgets);
      expect(find.text('0912345678'), findsOneWidget);
    });

    testWidgets('asks for no recipient name and no address details', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);

      // Assert — المستلم هو العميل نفسه، والوجهة مدينةٌ ومنطقةٌ ومتجر.
      expect(find.textContaining('اسم المستلم'), findsNothing);
      expect(find.textContaining('تفاصيل العنوان'), findsNothing);
      expect(find.text('هاتف الاستلام'), findsOneWidget);
    });

    testWidgets('chooses among the account’s shops, and the order follows the chosen one', (
      tester,
    ) async {
      // Arrange
      await open(tester, accountShops: const [noor, amal]);
      await proceed(tester);

      // Act
      await tester.tap(find.text('متجر الأمل'));
      await tester.pumpAndSettle();

      // Assert — والطلبية تذهب الآن إلى مدينته.
      expect(cubitOf(tester).state, isA<PlaceOrderReady>().having((s) => s.shopId, 'shopId', 6));
      expect(find.text('25 د.ل'), findsWidgets);
    });

    testWidgets('the city and the region sit side by side', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);

      // Assert
      final city = tester.getRect(find.byType(DropdownButtonFormField<City>));
      final region = tester.getRect(find.byType(DropdownButtonFormField<Region>));
      expect(city.top, closeTo(region.top, 1));
      expect(city.overlaps(region), isFalse);
    });

    testWidgets('the delivery price sits inside the city’s box, and on no line under it', (
      tester,
    ) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);

      // Assert
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<City>),
          matching: find.text('20 د.ل'),
        ),
        findsWidgets,
      );
      expect(find.textContaining('التوصيل:'), findsNothing);
    });

    testWidgets('the goods, the delivery and the total — like any shop’s checkout', (
      tester,
    ) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);
      await tester.ensureVisible(find.text('التوصيل'));
      await tester.pumpAndSettle();

      // Assert — والإجمالي بجانب زرّ الإرسال.
      expect(find.text('التوصيل'), findsOneWidget);
      expect(find.text('20 د.ل'), findsWidgets);
      expect(find.text('الإجمالي'), findsOneWidget);
      expect(find.text('520 د.ل'), findsOneWidget);
    });

    testWidgets('another city changes the delivery and the total', (tester) async {
      // Arrange
      await open(tester, accountShops: const [noor, amal]);
      await proceed(tester);

      // Act
      await tester.tap(find.text('متجر الأمل'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('525 د.ل'), findsOneWidget);
    });

    testWidgets('the region box is there before there is any region to choose', (tester) async {
      // Arrange — حسابٌ بلا متاجر: لا مدينة مختارة بعد.
      await open(tester, accountShops: const []);

      // Act
      await proceed(tester);

      // Assert — الصفّ بصندوقيه دائماً، والمنطقة تقول لماذا هي فارغة.
      expect(find.byType(DropdownButtonFormField<Region>), findsOneWidget);
      expect(find.text('اختر المدينة أولاً'), findsOneWidget);
    });

    testWidgets('a city with no regions keeps the region box, closed', (tester) async {
      // Arrange — طرابلس بلا مناطق.
      await open(tester, accountShops: const [amal]);

      // Act
      await proceed(tester);

      // Assert
      expect(find.byType(DropdownButtonFormField<Region>), findsOneWidget);
      expect(find.text('لا توجد مناطق'), findsOneWidget);
    });

    testWidgets('designs are chosen from a sheet, and the chosen ones are listed', (tester) async {
      // Arrange
      await open(tester, library: const [logo, flyer]);
      await proceed(tester);
      await tester.ensureVisible(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شعار المتجر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تم (1)'));
      await tester.pumpAndSettle();

      // Assert
      expect(cubitOf(tester).state, isA<PlaceOrderReady>().having((s) => s.designIds, 'ids', [1]));
      expect(find.text('شعار المتجر'), findsOneWidget);
      expect(find.text('تصميم الكيس'), findsNothing);
      expect(find.text('تعديل الاختيار (1)'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('in the sheet each design has its name on the right and its image on the left', (
      tester,
    ) async {
      // Arrange
      await open(tester, library: const [logo, flyer]);
      await proceed(tester);
      await tester.ensureVisible(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();

      // Assert
      final name = tester.getCenter(find.text('شعار المتجر'));
      final image = tester.getCenter(find.byType(DesignThumbnail).first);
      expect(name.dx, greaterThan(image.dx));
    });

    testWidgets('an account with no designs has no designs section', (tester) async {
      // Arrange & Act
      await open(tester);
      await proceed(tester);

      // Assert
      expect(find.text('التصاميم'), findsNothing);
      expect(find.text('اختيار التصاميم'), findsNothing);
    });

    testWidgets('notes are «ملاحظات» and nothing more is said about them', (tester) async {
      // Arrange & Act
      await open(tester);
      await proceed(tester);

      // Assert
      expect(find.text('ملاحظات'), findsOneWidget);
      expect(find.text('ملاحظاتك'), findsNothing);
      expect(find.textContaining('أي شيء تريد'), findsNothing);
    });

    testWidgets('offers no way to add a shop — that lives under «حسابي»', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await proceed(tester);

      // Assert
      expect(find.textContaining('أضف متجر'), findsNothing);
    });

    testWidgets('an account with no shops sees no shop section at all', (tester) async {
      // Arrange
      await open(tester, accountShops: const []);

      // Act
      await proceed(tester);

      // Assert — لا عنوانٌ فوق فراغ؛ الوجهة تحته تكفيه.
      expect(find.text('المتجر'), findsNothing);
      expect(find.text('الاستلام'), findsOneWidget);
    });

    testWidgets('sends the chosen shop and the phone, then opens the order', (tester) async {
      // Arrange
      await open(tester);
      await proceed(tester);

      // Act
      await tester.tap(find.text('أرسل الطلبية'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      final sent = verify(() => orders.place(captureAny())).captured.single as NewOrder;
      expect(sent.customerShopId, 5);
      expect(sent.cityId, 1);
      expect(sent.regionId, 10);
      expect(sent.recipientPhone, '0912345678');
      expect(find.text('طلبية 77'), findsOneWidget);
      expect(find.text('وصلتنا طلبيتك — سنراجعها ونتواصل معك'), findsOneWidget);

      // رسالة النجاح تنصرف بعد ثلاث ثوانٍ؛ يُترك لها وقتها كي لا يبقى مؤقّتها معلّقاً بعد الاختبار.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });

  group('going back', () {
    testWidgets('«السابق» returns to the products', (tester) async {
      // Arrange
      await open(tester);
      await proceed(tester);

      // Act
      await tester.tap(find.text('السابق'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('كيس شحن فلاير'), findsOneWidget);
      expect(find.text('هاتف الاستلام'), findsNothing);
    });

    testWidgets('the system back on the details returns to the products, not out of the cart', (
      tester,
    ) async {
      // Arrange
      await open(tester);
      await proceed(tester);

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('إتمام الطلب'), findsOneWidget);
      expect(find.text('الكتالوج'), findsNothing);
    });

    testWidgets('on the products it leaves the cart as usual', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الكتالوج'), findsOneWidget);
    });

    testWidgets('what was typed survives the trip back and forth', (tester) async {
      // Arrange
      await open(tester);
      await proceed(tester);
      await tester.enterText(find.widgetWithText(TextFormField, '0912345678'), '0923456789');

      // Act
      await tester.tap(find.text('السابق'));
      await tester.pumpAndSettle();
      await proceed(tester);

      // Assert — الرقم الذي كتبه العميل، لا رقم الحساب مرةً ثانية.
      expect(find.text('0923456789'), findsOneWidget);
    });
  });

  group('motion', () {
    testWidgets('the next step slides in', (tester) async {
      // Arrange
      await open(tester);

      // Act
      cubitOf(tester).proceed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // Assert
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('with reduced motion the step changes in one frame and nothing runs', (
      tester,
    ) async {
      // Arrange
      await open(tester, reduceMotion: true);

      // Act — ضخّةٌ تسلّم الحالة من التيار، وأخرى ترسمها: هذا أول إطارٍ يعرف فيه الشاشة بالخطوة.
      cubitOf(tester).proceed();
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.text('هاتف الاستلام'), findsOneWidget);
      expect(find.text('كيس شحن فلاير'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
