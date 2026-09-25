// أداةٌ لا اختبار: ترسم «طلباتي» صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا يجمعها
// `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/orders_preview.dart
//
// على طريقة `home_preview.dart`. البيانات مزيّفة وللرسم وحده: ثلاث طلبيات بمراحل مختلفة، إحداها
// بلا سعرٍ بعد، وأخرى بثلاثة بنود.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/orders_page.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/stage_filter_field.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/browse_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

OrderLine _line(int id, String name, String variant, String quantity) => OrderLine(
  id: id,
  productName: name,
  variantLabel: variant,
  quantity: quantity,
  pricingUnitLabel: 'قطعة',
);

class _Orders implements OrderRepository {
  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) async {
    final orders = [
      CustomerOrder(
        id: 1,
        code: '1228',
        stage: OrderStage.producing,
        stageLabel: 'قيد الإنتاج',
        total: '245.000',
        paidAmount: '100.000',
        balance: '145.00',
        cityName: 'بنغازي',
        recipientPhone: '0913333333',
        fulfilmentTypeLabel: 'توصيل',
        placedAt: DateTime.now().subtract(const Duration(days: 1)),
        items: [
          _line(1, 'أكياس شحن - مطبوعة', '30*40', '500.000'),
          _line(2, 'أكياس يد داخلية - مطبوع', '25*35', '300.000'),
          _line(3, 'اكياس شفافه - مطبوعة', '20*30', '200.000'),
        ],
      ),
      CustomerOrder(
        id: 2,
        code: '1231',
        stage: OrderStage.underReview,
        stageLabel: 'بانتظار المراجعة',
        isAwaitingQuote: true,
        cityName: 'طرابلس',
        recipientPhone: '0924444444',
        fulfilmentTypeLabel: 'توصيل',
        placedAt: DateTime.now(),
        items: [_line(4, 'أكياس ورقية عادية - مطبوعه', '25*35', '1000.000')],
      ),
      CustomerOrder(
        id: 3,
        code: '1190',
        stage: OrderStage.delivered,
        stageLabel: 'تم الاستلام',
        total: '980.000',
        paidAmount: '980.000',
        balance: '0.00',
        cityName: 'بنغازي',
        fulfilmentTypeLabel: 'استلام من المكتب',
        placedAt: DateTime.now().subtract(const Duration(days: 12)),
        items: [_line(5, 'أكياس شحن - مطبوعة', '35*45', '2000.000')],
      ),
    ];

    return Right(
      Paginated<CustomerOrder>(
        items: orders,
        meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: orders.length),
      ),
    );
  }

  @override
  Future<Either<Failure, CustomerOrderDetail>> detail(int id) => throw UnimplementedError();

  @override
  Future<Either<Failure, CustomerOrderDetail>> place(NewOrder order) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BasketQuote>> quote({required List<NewOrderLine> items, int? cityId}) =>
      throw UnimplementedError();
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['PREVIEW_OUT'] ?? '.';

  setUpAll(() async {
    await _load('Cairo', [
      for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Cairo-$face.ttf',
    ]);
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final icons = '$artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(icons).existsSync()) await _load('MaterialIcons', [icons]);
  });

  Future<void> draw(
    WidgetTester tester, {
    required Brightness brightness,
    bool withSheet = false,
  }) async {
    await sl.reset();
    sl.registerFactory<OrdersCubit>(() => OrdersCubit(browse: BrowseOrders(_Orders())));

    // آيفون بجزيرة: ٣٩٠×٨٤٤، شريط الحالة ٥٩، والمؤشر السفلي ٣٤.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 118, bottom: 68);
    tester.view.viewPadding = const FakeViewPadding(top: 118, bottom: 68);
    addTearDown(tester.view.reset);

    StatefulShellBranch branch(String path, Widget page) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => page)],
    );

    final router = GoRouter(
      initialLocation: Routes.orders,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomeShell(shell: shell),
          branches: [
            branch(Routes.home, const Scaffold()),
            branch(Routes.products, const Scaffold()),
            branch(Routes.orders, const OrdersPage()),
          ],
        ),
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

    // الورقة مفتوحةً فوق القائمة، كما يراها من لمس حقل الحالة.
    if (withSheet) {
      await tester.tap(find.byType(StageFilterField));
      await tester.pumpAndSettle();
    }

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final name = withSheet ? 'orders-sheet' : 'orders';
      await File('$out/$name-${brightness.name}.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw orders, ${brightness.name}', (tester) async {
      await draw(tester, brightness: brightness);
    });

    testWidgets('draw the status sheet, ${brightness.name}', (tester) async {
      await draw(tester, brightness: brightness, withSheet: true);
    });
  }
}
