// أداةٌ لا اختبار: ترسم السلة بخطوتيها و«متاجري» ونموذج المتجر صوراً PNG كي يُنظر فيها بلا هاتف.
// خارج `test/` كي لا يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/cart_preview.dart
//
// على مقاس `auth_preview.dart` نفسه: ٣٩٠×٨٤٤ بكثافة ٢، بشريط حالةٍ ومؤشرٍ سفليّ، وخط Cairo بأوزانه
// الستة، وخط أيقونات Material من ذاكرة الـ SDK.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/delivery/models/city.dart';
import 'package:dayaa_client/features/delivery/repositories/delivery_repository.dart';
import 'package:dayaa_client/features/delivery/usecases/list_cities.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
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
import 'package:dayaa_client/features/shops/presentation/viewmodel/shop_form_cubit.dart';
import 'package:dayaa_client/features/shops/presentation/viewmodel/shops_cubit.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_details_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shop_form_page.dart';
import 'package:dayaa_client/features/shops/presentation/views/shops_page.dart';
import 'package:dayaa_client/features/shops/repositories/shop_repository.dart';
import 'package:dayaa_client/features/shops/usecases/add_shop.dart';
import 'package:dayaa_client/features/shops/usecases/list_business_fields.dart';
import 'package:dayaa_client/features/shops/usecases/list_shops.dart';
import 'package:dayaa_client/features/shops/usecases/remove_shop.dart';
import 'package:dayaa_client/features/shops/usecases/update_shop.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

const _kish = Region(id: 10, cityId: 1, name: 'الكيش');
const _benghazi = City(
  id: 1,
  name: 'بنغازي',
  isRegionRequired: true,
  deliveryPrice: '20.00',
  regions: [_kish, Region(id: 11, cityId: 1, name: 'الصابري')],
);
const _tripoli = City(id: 2, name: 'طرابلس', deliveryPrice: '25.00');

const _shops = [
  Shop(
    id: 5,
    name: 'متجر النور',
    cityId: 1,
    cityName: 'بنغازي',
    regionId: 10,
    regionName: 'الكيش',
    businessFieldId: 3,
    businessFieldName: 'ملابس وأحذية',
    pageUrl: 'https://facebook.com/alnoor',
  ),
  Shop(id: 6, name: 'متجر الأمل — فرع قرجي', cityId: 2, cityName: 'طرابلس'),
];

const _lines = [
  OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 2, quantity: '1000'),
    title: 'كيس شحن فلاير — مطبوع',
    subtitle: '30*40 · 1,000 قطعة',
  ),
  OrderDraftLine(
    line: NewOrderLine(productId: 3, productVariantId: 4, quantity: '500'),
    title: 'كيس ورقي بيد مبرومة',
    subtitle: '25*35 · 12.5 كجم',
  ),
];

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(() async {
    registerFallbackValue(<NewOrderLine>[]);
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  void register() {
    final delivery = _MockDeliveryRepository();
    final designs = _MockDesignRepository();
    final shops = _MockShopRepository();
    final auth = _MockAuthRepository();

    when(() => delivery.cities()).thenAnswer((_) async => const Right([_benghazi, _tripoli]));
    when(() => designs.list()).thenAnswer(
      (_) async => const Right([
        CustomerDesign(id: 1, label: 'شعار المتجر', kind: DesignKind.image),
        CustomerDesign(id: 2, label: 'تصميم الكيس', kind: DesignKind.pdf),
      ]),
    );
    when(() => shops.list()).thenAnswer((_) async => const Right(_shops));
    when(() => shops.businessFields()).thenAnswer(
      (_) async => const Right([
        BusinessField(id: 3, name: 'ملابس وأحذية'),
        BusinessField(id: 4, name: 'عطور'),
      ]),
    );
    when(() => auth.currentCustomer()).thenAnswer(
      (_) async => const Right(CustomerAccount(id: 1, name: 'محمد', phone: '0912345678')),
    );

    final orders = _MockOrderRepository();
    when(
      () => orders.quote(items: any(named: 'items'), cityId: any(named: 'cityId')),
    ).thenAnswer(
      (_) async => const Right(
        BasketQuote(
          lines: [
            BasketLineQuote(
              productId: 1,
              productVariantId: 2,
              unitLabel: 'قطعة',
              unitPrice: '0.450',
              lineTotal: '450.00',
            ),
            BasketLineQuote(
              productId: 3,
              productVariantId: 4,
              unitLabel: 'كجم',
              unitPrice: '9.000',
              lineTotal: '112.50',
            ),
          ],
          itemsTotal: '562.50',
          deliveryPrice: '20.00',
          totalWithDelivery: '582.50',
        ),
      ),
    );

    final cart = CartCubit();
    for (final line in _lines) {
      cart.add(line);
    }

    sl
      ..registerFactory<DesignsCubit>(
        () => DesignsCubit(
          list: ListDesigns(designs),
          upload: UploadDesign(designs),
          rename: RenameDesign(designs),
          remove: RemoveDesign(designs),
        ),
      )
      ..registerFactory<PlaceOrderCubit>(
        () => PlaceOrderCubit(
          cities: ListCities(delivery),
          designs: ListDesigns(designs),
          shops: ListShops(shops),
          customer: GetCurrentCustomer(auth),
          quote: QuoteBasket(orders),
          place: PlaceOrder(orders),
          cart: cart,
        ),
      )
      ..registerFactory<ShopsCubit>(
        () => ShopsCubit(list: ListShops(shops), remove: RemoveShop(shops)),
      )
      ..registerFactoryParam<ShopFormCubit, Shop?, void>(
        (editing, _) => ShopFormCubit(
          cities: ListCities(delivery),
          businessFields: ListBusinessFields(shops),
          add: AddShop(shops),
          update: UpdateShop(shops),
          editing: editing,
        ),
      );
  }

  Future<void> draw(
    WidgetTester tester, {
    required String name,
    required Brightness brightness,
    required Widget screen,
    bool details = false,
    bool scrolled = false,
    bool sheet = false,
  }) async {
    await sl.reset();
    register();

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => screen),
        GoRoute(path: Routes.shopForm, builder: (context, state) => const ShopFormPage()),
      ],
    );
    final key = GlobalKey();

    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: brightness == Brightness.light ? theme.light() : theme.dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (details) {
      tester.element(find.byType(EasyStepper)).read<PlaceOrderCubit>().proceed();
      await tester.pumpAndSettle();
    }

    // ورقة التصاميم مفتوحةً، وأول تصميمٍ مختار.
    if (sheet) {
      await tester.ensureVisible(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختيار التصاميم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('شعار المتجر').last);
      await tester.pumpAndSettle();
    }

    // آخر الخطوة: ملخّص التكلفة تحت الملاحظات.
    if (scrolled) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -900));
      await tester.pumpAndSettle();
    }

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw cart products, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'cart-products-${brightness.name}',
        brightness: brightness,
        screen: const PlaceOrderPage(),
      );
    });

    testWidgets('draw the design sheet, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'cart-design-sheet-${brightness.name}',
        brightness: brightness,
        screen: const PlaceOrderPage(),
        details: true,
        sheet: true,
      );
    });

    testWidgets('draw cart details scrolled, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'cart-details-end-${brightness.name}',
        brightness: brightness,
        screen: const PlaceOrderPage(),
        details: true,
        scrolled: true,
      );
    });

    testWidgets('draw cart details, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'cart-details-${brightness.name}',
        brightness: brightness,
        screen: const PlaceOrderPage(),
        details: true,
      );
    });
  }

  testWidgets('draw my shops', (tester) async {
    await draw(
      tester,
      name: 'shops-light',
      brightness: Brightness.light,
      screen: const ShopsPage(),
    );
  });

  testWidgets('draw the shop form', (tester) async {
    await draw(
      tester,
      name: 'shop-form-light',
      brightness: Brightness.light,
      screen: ShopFormPage(editing: _shops.first),
    );
  });

  testWidgets('draw a new shop form', (tester) async {
    await draw(
      tester,
      name: 'shop-form-new-light',
      brightness: Brightness.light,
      screen: const ShopFormPage(),
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('draw a shop page, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'shop-details-${brightness.name}',
        brightness: brightness,
        screen: ShopDetailsPage(shop: _shops.first),
      );
    });
  }
}
