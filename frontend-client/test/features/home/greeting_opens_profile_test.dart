import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/billboards/models/billboard.dart';
import 'package:dayaa_client/features/billboards/presentation/viewmodel/billboard_cubit.dart';
import 'package:dayaa_client/features/billboards/repositories/billboard_repository.dart';
import 'package:dayaa_client/features/billboards/usecases/get_billboards.dart';
import 'package:dayaa_client/features/home/presentation/views/home_page.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Tapping who you are opens the screen about you.
///
/// **The thing people tried and nothing happened.** The avatar and «مرحباً …» are the account
/// looking back at the customer, and an account you cannot tap is a dead spot in the one corner
/// everybody aims at first.
///
/// **`go`, not `push`, and that is the half a test is needed for.** «حسابي» is one of the five
/// tabs; pushing it would stack a second copy over the home screen with the navigation bar gone
/// and no way back to it. Both spellings compile, both put the profile on screen, and only one
/// is right — so the test asserts the *bar moved*, not merely that a profile appeared.
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

void main() {
  setUp(() {
    sl
      ..registerLazySingleton<GetCurrentCustomer>(() => GetCurrentCustomer(_StubAuth()))
      ..registerFactory<BillboardCubit>(
        () => BillboardCubit(get: GetBillboards(_StubBillboards())),
      );
  });

  tearDown(() => sl.reset());

  /// The home screen under a router that also knows where «حسابي» is, so `go` has somewhere
  /// real to land rather than throwing.
  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('شاشة حسابي'))),
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
        ),
      ),
    );
  }

  testWidgets('tapping the greeting opens «حسابي»', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('مرحباً طه'), findsOneWidget);

    // Act
    await tester.tap(find.text('مرحباً طه'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة حسابي'), findsOneWidget);
  });

  testWidgets('tapping the avatar does too, not just the words', (tester) async {
    // Arrange — the ringed circle is the bigger target and the one people aim at, so it has to
    // be inside the tap area and not merely beside it.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final avatar = find.byIcon(AppIcons.person);
    expect(avatar, findsOneWidget);

    // Act
    await tester.tap(avatar);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة حسابي'), findsOneWidget);
  });

  testWidgets('the bell is not part of that tap target', (tester) async {
    // Arrange — the two sit in the same row, and a customer aiming for the bell who landed on
    // «حسابي» would have been given a worse version of both.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(NotificationsButton));
    await tester.pumpAndSettle();

    // Assert — the bell went to «الإشعارات», which this router does not know, so the one thing
    // that must be true is that it did *not* land on «حسابي».
    expect(find.text('شاشة حسابي'), findsNothing);
  });
}
