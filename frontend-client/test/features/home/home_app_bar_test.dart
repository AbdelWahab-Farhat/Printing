import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/home/presentation/widgets/home_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _StubBadges implements BadgeRepository {
  _StubBadges(this._counts);

  final Map<CustomerBadge, int> _counts;

  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => Right(_counts);
}

/// شريط الرئيسية العلوي: اسم المتجر في الوسط، والدعم و«حسابي» في طرفه.
///
/// **«حسابي» تُدفع فوق الرئيسية ولا يُنتقل إليها.** لم تعد تبويباً، فالطريق إليها طريقٌ يُرجع
/// منه — والاختبار يثبت زرّ الرجوع لا ظهور الشاشة وحده، لأن `go` كان سيُظهرها أيضاً بلا رجوع.
///
/// Arrange - Act - Assert throughout.
void main() {
  Future<Widget> host({Map<CustomerBadge, int> counts = const {}}) async {
    final badges = BadgesCubit(getBadges: GetBadges(_StubBadges(counts)));
    await badges.refresh();

    Widget page(String title) => Scaffold(appBar: AppBar(title: Text(title)));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(appBar: HomeAppBar()),
        ),
        GoRoute(path: Routes.profile, builder: (context, state) => page('شاشة حسابي')),
        GoRoute(path: Routes.support, builder: (context, state) => page('شاشة الدعم')),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => BlocProvider<BadgesCubit>.value(
        value: badges,
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

  testWidgets('the profile icon opens «حسابي» over the home screen, with a way back', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('حسابي'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة حسابي'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('the support icon opens «الدعم», with a way back', (tester) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('الدعم'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة الدعم'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('the support icon carries the count of replies not yet read', (tester) async {
    // Arrange
    final app = await host(counts: const {CustomerBadge.support: 2});

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('2'), findsOneWidget);
  });

  /// المطلوب بالحرف: لا «مرحباً»، ولا رقم العميل، ولا جرس. الرقم ما زال في «حسابي».
  testWidgets('the bar names the shop: no greeting, no customer code, no bell', (tester) async {
    // Arrange
    final app = await host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('FlyerX', findRichText: true), findsOneWidget);
    expect(find.textContaining('مرحباً'), findsNothing);
    expect(find.byTooltip('الإشعارات'), findsNothing);
  });
}
