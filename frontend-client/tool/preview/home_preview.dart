// أداةٌ لا اختبار: ترسم الرئيسية صوراً PNG كي يُنظر فيها بلا هاتف. خارج `test/` كي لا
// يجمعها `flutter test`.
//
//   PREVIEW_OUT=<مجلد الصور> flutter test tool/preview/home_preview.dart
//
// على طريقة `auth_preview.dart`: آيفون ٣٩٠×٨٤٤ بكثافة ٢، وCairo بأوزانه الستة، وخط أيقونات
// Material من ذاكرة الـ SDK، والظلال بتمويهها. والفرق هنا أن للشاشة صوراً: إعلانات التطبيق
// تُفكّ قبل الرسم داخل `runAsync`، لأن فكّ الصور عمليةٌ حقيقية خارج ساعة الاختبار المزيّفة.
//
// البيانات مزيّفة وللرسم وحده: طلبيتان في الطريق، ولا إعلان من المتجر (فتظهر إعلانات التطبيق).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/text_theme.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/models/house_ad.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:dayaa_client/features/home/presentation/viewmodel/active_orders_cubit.dart';
import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Paginated<T> _page<T>(List<T> items) => Paginated<T>(
  items: items,
  meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
);

class _Billboards implements BillboardRepository {
  @override
  Future<Either<Failure, List<Billboard>>> showing() async => const Right(<Billboard>[]);
}

class _Badges implements BadgeRepository {
  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async =>
      const Right({CustomerBadge.support: 2});
}

class _Orders implements OrderRepository {
  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) async {
    if (stage != null) return Right(_page(const <CustomerOrder>[]));

    return Right(
      _page([
        CustomerOrder(
          id: 1,
          code: '1228',
          stage: OrderStage.producing,
          stageLabel: 'قيد الإنتاج',
          summary: 'أكياس شحن - مطبوعة 30×40',
          itemsCount: 3,
          total: '245.000',
          placedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        CustomerOrder(
          id: 2,
          code: '1231',
          stage: OrderStage.underReview,
          stageLabel: 'بانتظار المراجعة',
          summary: 'أكياس ورقية عادية - مطبوعه 25×35',
          isAwaitingQuote: true,
          placedAt: DateTime.now(),
        ),
      ]),
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
    required String name,
    required Brightness brightness,
    required String location,
  }) async {
    await sl.reset();
    sl
      ..registerFactory<BillboardCubit>(() => BillboardCubit(get: GetBillboards(_Billboards())))
      ..registerFactory<ActiveOrdersCubit>(
        () => ActiveOrdersCubit(list: ListActiveOrders(_Orders())),
      );

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
      initialLocation: location,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomeShell(shell: shell),
          branches: [
            branch(Routes.home, const HomePage()),
            branch(Routes.products, const Scaffold()),
            branch(Routes.orders, const Scaffold()),
          ],
        ),
      ],
    );
    final key = GlobalKey();
    final badges = BadgesCubit(getBadges: GetBadges(_Badges()));
    await badges.refresh();

    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) {
            final theme = MaterialTheme(createTextTheme(context, 'Cairo', 'Cairo'));

            return BlocProvider<BadgesCubit>.value(
              value: badges,
              child: MaterialApp.router(
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
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    // صور الإعلانات تُفكّ فعلاً قبل الرسم، وإلا رُسمت أماكنها فارغة.
    final context = key.currentContext!;
    await tester.runAsync(() async {
      for (final ad in HouseAd.values) {
        await precacheImage(AssetImage(ad.asset), context);
      }
    });
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    debugDisableShadows = true;
  }

  for (final brightness in Brightness.values) {
    testWidgets('draw home, ${brightness.name}', (tester) async {
      await draw(
        tester,
        name: 'home-${brightness.name}',
        brightness: brightness,
        location: Routes.home,
      );
    });
  }
}
