import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/home/presentation/widgets/home_app_bar.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/cairo_font.dart';
import '../wallet/fake_wallet.dart';

class _StubBadges implements BadgeRepository {
  _StubBadges(this._counts);

  final Map<CustomerBadge, int> _counts;

  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => Right(_counts);
}

/// الشريط العلوي الذي تلبسه الأقسام الأربعة: اسم المتجر في الوسط، والدعم في طرفه الأيمن، ورصيد
/// المحفظة في الأيسر والسلة بجانبه حين يكون فيها شيء (طلب المستخدم، 2026-10-16). و«حسابي» نزلت
/// إلى الشريط السفلي (طلب المستخدم، 2026-09-25).
///
/// **«حسابي» تُدفع فوق الرئيسية ولا يُنتقل إليها.** لم تعد تبويباً، فالطريق إليها طريقٌ يُرجع
/// منه — والاختبار يثبت زرّ الرجوع لا ظهور الشاشة وحده، لأن `go` كان سيُظهرها أيضاً بلا رجوع.
///
/// Arrange - Act - Assert throughout.
void main() {
  const line = OrderDraftLine(
    line: NewOrderLine(productId: 1, productVariantId: 1, quantity: '1000'),
    title: 'منتج 1',
  );

  // الخطّ الحقيقي: اختباراتٌ هنا تسأل هل يتّسع نص.
  setUpAll(loadCairo);

  // السلة ورصيد المحفظة في الشريط يقرآن المفرَدين من `sl` مباشرة.
  setUp(() {
    sl
      ..registerLazySingleton<CartCubit>(CartCubit.new)
      ..registerLazySingleton(
        () => WalletBalanceCubit(getBalance: GetWalletBalance(FakeWallet(held: '200.00'))),
      );
  });
  tearDown(() => sl.reset());

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
        GoRoute(path: Routes.wallet, builder: (context, state) => page('شاشة محفظتي')),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => BlocProvider<BadgesCubit>.value(
        value: badges,
        child: MaterialApp.router(
          theme: ThemeData(fontFamily: 'Cairo'),
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

  testWidgets('the bar carries no «حسابي» icon: it is a place in the bottom bar now', (
    tester,
  ) async {
    // Arrange
    final app = await host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('حسابي'), findsNothing);
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

  /// الشريط نفسه على الأقسام الأربعة، فالسلة فيه أينما كان العميل. **وتظهر في الداخل، بجانب
  /// الرصيد،** لا في الطرف: السلة الفارغة لا تُرسم أصلاً، ولو كانت في الطرف لدفعت الرصيد إلى
  /// الداخل كلّما امتلأت.
  testWidgets('a basket with something in it joins the bar inside the balance, moving nothing', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();
    final balance = tester.getRect(find.byTooltip('محفظتي'));
    final support = tester.getRect(find.byTooltip('الدعم'));

    // Act
    sl<CartCubit>().add(line);
    await tester.pumpAndSettle();

    // Assert — في شريطٍ عربي الطرفُ يساراً، فالداخلُ يمينه.
    expect(find.byTooltip('سلتك'), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('سلتك')).dx, greaterThan(balance.center.dx));
    expect(tester.getRect(find.byTooltip('محفظتي')), balance);
    expect(tester.getRect(find.byTooltip('الدعم')), support);
  });

  testWidgets('an empty basket draws no cart in the bar', (tester) async {
    // Arrange
    final app = await host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('سلتك'), findsNothing);
  });

  /// الرصيد والسلة في طرف، والدعم في الآخر: الاسم يجب أن يبقى في منتصف الشاشة لا أن يُزاح عنه،
  /// على أضيق هاتفٍ شائع. **ولهذا انتقل الدعم إلى اليمين** (طلب المستخدم، 2026-10-16): ثلاثتها
  /// في طرفٍ واحد كانت تزيح الاسم ستين نقطة.
  testWidgets('with the cart in, the name stays in the middle of a narrow phone', (
    tester,
  ) async {
    // Arrange
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    sl<CartCubit>().add(line);

    // Act
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Assert
    final name = tester.getRect(find.text('FlyerX', findRichText: true));
    final cart = tester.getRect(find.byTooltip('سلتك'));
    expect(name.center.dx, closeTo(180, 0.5));
    expect(cart.right, lessThanOrEqualTo(name.left));
  });

  /// «200 د.ل» بحبّةٍ خفيفة في أقصى يسار الشريط، والدعم في أقصى يمينه (طلب المستخدم،
  /// 2026-10-16).
  testWidgets('the balance takes the far left, «200 د.ل», and support the far right', (
    tester,
  ) async {
    // Arrange
    sl<CartCubit>().add(line);

    // Act
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Assert
    final chip = tester.getRect(find.byTooltip('محفظتي'));
    final name = tester.getRect(find.text('FlyerX', findRichText: true));
    expect(find.text('200 د.ل'), findsOneWidget);
    expect(chip.right, lessThan(tester.getRect(find.byTooltip('سلتك')).left));
    expect(tester.getRect(find.byTooltip('الدعم')).left, greaterThan(name.right));
  });

  testWidgets('the balance opens «محفظتي», with a way back', (tester) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('محفظتي'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة محفظتي'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  /// ما دفعته شاشة الطلبية يصل إلى الشريط بلا سؤال.
  testWidgets('a balance another screen learned shows in the bar at once', (tester) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();

    // Act
    sl<WalletBalanceCubit>().patch('1250.50');
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('1,250.50 د.ل'), findsOneWidget);
  });
}
