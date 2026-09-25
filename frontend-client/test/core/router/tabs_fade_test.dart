import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/router/fade_through_branches.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
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
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:dayaa_client/features/splash/presentation/viewmodel/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// أقسام الشريط السفلي في التطبيق الحقيقي تنتقل بالتلاشي.
///
/// سلوك الحاوية نفسها مختبَر في `fade_through_branches_test.dart`، وهذا الملف يثبت أن [AppRouter]
/// يستعملها فعلاً. من يعيد `StatefulShellRoute.indexedStack` يعيد الانتقال الفوري، ولن يفشل بسبب
/// ذلك أي اختبار غير هذا.
///
/// Arrange - Act - Assert throughout.
class _StubAuth implements AuthRepository {
  @override
  Future<Either<Failure, CustomerAccount>> currentCustomer() async =>
      const Right(CustomerAccount(id: 1, name: 'طه', phone: '0911111111', code: 'C-7'));

  @override
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String phone,
    required String password,
    String? shopName,
    String? cityName,
    String? businessField,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> logout() => throw UnimplementedError();

  /// الحارس في [AppRouter] وشاشة البداية يسألان هذا، فالجواب «نعم» يفتح الرئيسية بدل شاشة الدخول.
  @override
  bool get hasStoredToken => true;
}

class _StubBillboards implements BillboardRepository {
  @override
  Future<Either<Failure, List<Billboard>>> showing() async => const Right([]);
}

class _StubBadges implements BadgeRepository {
  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => const Right({});
}

Paginated<T> _empty<T>() => Paginated<T>(
  items: const [],
  meta: const PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: 0),
);

/// قسم الرئيسية الجديد يسأل عن الطلبيات، وجوابٌ فارغ يكفي هذا الاختبار.
class _StubOrders implements OrderRepository {
  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) async => Right(_empty());

  @override
  Future<Either<Failure, CustomerOrderDetail>> detail(int id) => throw UnimplementedError();

  @override
  Future<Either<Failure, CustomerOrderDetail>> place(NewOrder order) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, BasketQuote>> quote({required List<NewOrderLine> items, int? cityId}) =>
      throw UnimplementedError();
}

void main() {
  setUp(() {
    final auth = _StubAuth();
    sl
      ..registerLazySingleton<HasStoredSession>(() => HasStoredSession(auth))
      ..registerLazySingleton<GetCurrentCustomer>(() => GetCurrentCustomer(auth))
      ..registerFactory<SplashCubit>(
        () => SplashCubit(
          hasStoredSession: HasStoredSession(auth),
          getCurrentCustomer: GetCurrentCustomer(auth),
          logout: Logout(auth),
        ),
      )
      ..registerFactory<BillboardCubit>(
        () => BillboardCubit(get: GetBillboards(_StubBillboards())),
      )
      ..registerFactory<ActiveOrdersCubit>(
        () => ActiveOrdersCubit(list: ListActiveOrders(_StubOrders())),
      );
  });

  tearDown(() => sl.reset());

  testWidgets('the tabs switch through the fading container', (tester) async {
    // Arrange — التطبيق بموجّهه الحقيقي، كما يبنيه app.dart.
    final app = ScreenUtilInit(
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
          routerConfig: AppRouter.instance,
        ),
      ),
    );

    // Act — شاشة البداية أولاً، ودوّارها لا يهدأ، فيُتجاوز وقتها صراحةً قبل انتظار الهدوء.
    await tester.pumpWidget(app);
    await tester.pump(SplashCubit.minimumDisplay + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(FadeThroughBranches), findsOneWidget);
  });
}
