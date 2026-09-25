import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:dayaa_client/features/home/presentation/viewmodel/active_orders_cubit.dart';
import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:dayaa_client/features/home/presentation/widgets/active_order_card.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StubBillboards implements BillboardRepository {
  @override
  Future<Either<Failure, List<Billboard>>> showing() async => const Right(<Billboard>[]);
}

class _StubBadges implements BadgeRepository {
  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => const Right({});
}

Paginated<T> _page<T>(List<T> items) => Paginated<T>(
  items: items,
  meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
);

/// يجيب عن «قيد التنفيذ» بما في [moving]، وعن «جاهزة» بلا شيء. [moving] قابلٌ للتغيير كي
/// يُختبر ما يحدث حين تنجح المحاولة الثانية.
class _StubOrders implements OrderRepository {
  _StubOrders(this.moving);

  Either<Failure, List<CustomerOrder>> moving;

  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) async {
    if (stage != null) return Right(_page(const <CustomerOrder>[]));

    return moving.fold((failure) => Left(failure), (orders) => Right(_page(orders)));
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

/// الرئيسية: الإعلانات، ثم «طلبياتي الجارية». «منتجاتنا» نُزع (طلب المستخدم، 2026-09-25): تبويب
/// «المنتجات» تحت الإبهام يعرضها كلها.
///
/// Arrange - Act - Assert throughout.
void main() {
  final producing = CustomerOrder(
    id: 1,
    code: '1228',
    stage: OrderStage.producing,
    stageLabel: 'قيد الإنتاج',
    summary: 'أكياس شحن - مطبوعة 30×40',
    total: '245.000',
    placedAt: DateTime.now(),
  );

  late _StubOrders orders;

  void register({required Either<Failure, List<CustomerOrder>> moving}) {
    orders = _StubOrders(moving);

    sl
      ..registerFactory<BillboardCubit>(
        () => BillboardCubit(get: GetBillboards(_StubBillboards())),
      )
      ..registerFactory<ActiveOrdersCubit>(
        () => ActiveOrdersCubit(list: ListActiveOrders(orders)),
      );
  }

  Widget host() {
    Widget page(String title) => Scaffold(appBar: AppBar(title: Text(title)));

    final router = GoRouter(
      routes: [
        GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
        GoRoute(path: Routes.orders, builder: (context, state) => page('صفحة الطلبيات')),
        GoRoute(path: Routes.products, builder: (context, state) => page('صفحة المنتجات')),
        GoRoute(
          path: '/orders/:id',
          builder: (context, state) => page('طلبية ${state.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (context, state) => page('منتج ${state.pathParameters['id']}'),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => BlocProvider<BadgesCubit>(
        create: (_) => BadgesCubit(getBadges: GetBadges(_StubBadges())),
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          // الإعلانات تتقلب بنفسها، ومؤقّتها لا يعني هذه الاختبارات.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
  }

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    await sl.reset();
  });

  testWidgets('an order on its way shows its stage and where it stands', (tester) async {
    // Arrange
    register(moving: Right([producing]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('طلبياتي الجارية'), findsOneWidget);
    expect(find.text('#1228'), findsOneWidget);
    expect(find.text('قيد الإنتاج'), findsOneWidget);
    expect(find.text('الإنتاج'), findsOneWidget);
  });

  // كانت صفّاً يُمرَّر أفقياً وحافة التالية ظاهرة، فطلب المستخدم أن تكون تحت بعضها (2026-09-25).
  testWidgets('several orders stack one under another, each the full width', (tester) async {
    // Arrange
    final older = CustomerOrder(
      id: 2,
      code: '1304',
      stage: OrderStage.underReview,
      stageLabel: 'بانتظار المراجعة',
      summary: 'أكياس يد خارجية - مطبوعة',
      total: '1470.000',
      placedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    register(moving: Right([producing, older]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final first = tester.getRect(find.byType(ActiveOrderCard).first);
    final second = tester.getRect(find.byType(ActiveOrderCard).last);
    expect(find.byType(ActiveOrderCard), findsNWidgets(2));
    expect(second.top, greaterThan(first.bottom));
    expect(second.left, first.left);
    expect(second.width, first.width);
    expect(first.width, 430 - 2 * 16);
  });

  testWidgets('tapping the order opens it, with a way back', (tester) async {
    // Arrange
    register(moving: Right([producing]));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('#1228'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('طلبية 1'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('with nothing on its way, the section offers to order bags', (tester) async {
    // Arrange
    register(moving: const Right(<CustomerOrder>[]));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('اطلب أكياسك'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('صفحة المنتجات'), findsOneWidget);
  });

  testWidgets('«عرض الكل» beside the orders goes to «طلباتي»', (tester) async {
    // Arrange
    register(moving: Right([producing]));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('عرض الكل').first);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('صفحة الطلبيات'), findsOneWidget);
  });

  testWidgets('orders that did not load can be asked for again', (tester) async {
    // Arrange
    register(moving: const Left(NetworkFailure(message: 'لا يوجد اتصال')));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد اتصال'), findsOneWidget);
    orders.moving = Right([producing]);

    // Act
    await tester.tap(find.text('أعد المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('#1228'), findsOneWidget);
    expect(find.text('لا يوجد اتصال'), findsNothing);
  });

  testWidgets('the home screen carries no products row', (tester) async {
    // Arrange
    register(moving: const Right(<CustomerOrder>[]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('منتجاتنا'), findsNothing);
    expect(find.text('عرض الكل'), findsOneWidget);
  });
}
