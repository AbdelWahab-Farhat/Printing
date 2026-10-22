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

/// الشريط العلوي الذي تلبسه الأقسام الأربعة: اسم المتجر في الوسط، والدعم في طرفه الأيمن والسلة
/// بجانبه، كلٌّ في دائرة، ورصيد المحفظة وحده في الأيسر (طلب المستخدم، 2026-10-20). و«حسابي» نزلت
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

  /// «اقلب يمين وخليها واضحة بإنها ايقونة هي وتذاكر بداخل سيركل افتار» (طلب المستخدم،
  /// 2026-10-20): السلة انتقلت من جانب الرصيد إلى جانب الدعم، وكلٌّ منهما في دائرة.
  testWidgets('the cart sits beside support on the right, and filling it moves nothing', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(await host());
    await tester.pumpAndSettle();
    final balance = tester.getRect(find.byTooltip('محفظتي'));
    final support = tester.getRect(find.byTooltip('الدعم'));
    final cart = tester.getRect(find.byTooltip('سلتك'));

    // Act
    sl<CartCubit>().add(line);
    await tester.pumpAndSettle();

    // Assert — الدعم في الطرف، والسلة في داخله، وكلاهما يمين الاسم.
    final name = tester.getRect(find.text('FlyerX', findRichText: true));
    expect(cart.left, greaterThan(name.right));
    expect(cart.right, lessThan(support.left));
    expect(tester.getRect(find.byTooltip('سلتك')), cart);
    expect(tester.getRect(find.byTooltip('محفظتي')), balance);
    expect(tester.getRect(find.byTooltip('الدعم')), support);
  });

  /// «يليت دوما تظهر السلة» (طلب المستخدم، 2026-10-20).
  testWidgets('an empty basket still shows the cart', (tester) async {
    // Arrange
    final app = await host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byTooltip('سلتك'), findsOneWidget);
  });

  testWidgets('support and the cart each sit in a light circle', (tester) async {
    // Arrange — هاتفٌ بعرض ٣٩٠: في نافذة الاختبار الافتراضية (٨٠٠) تكبر `.w` حتى يقصّ الشريطُ
    // الدائرةَ بارتفاعه.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final app = await host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert — دائرةٌ مرسومةٌ لا تموّج لمسةٍ وحسب: لها لونٌ وهي ساكنة.
    for (final tooltip in ['الدعم', 'سلتك']) {
      final button = find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton));
      final style = tester.widget<IconButton>(button).style!;
      final rect = tester.getRect(button);

      expect(style.shape!.resolve({}), isA<CircleBorder>(), reason: tooltip);
      expect(style.backgroundColor!.resolve({})!.a, greaterThan(0), reason: tooltip);
      expect(rect.width, closeTo(rect.height, 0.01), reason: tooltip);
    }
  });

  /// الرصيد في طرف، والدعم والسلة في الآخر: الاسم يجب أن يبقى في منتصف الشاشة لا أن يُزاح عنه،
  /// على أضيق هاتفٍ شائع.
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
    final balance = tester.getRect(find.byTooltip('محفظتي'));
    expect(name.center.dx, closeTo(180, 0.5));
    expect(cart.left, greaterThanOrEqualTo(name.right));
    expect(balance.right, lessThanOrEqualTo(name.left));
  });

  /// «200 د.ل» بحبّةٍ خفيفة وحدها في أقصى يسار الشريط، والدعم في أقصى يمينه.
  testWidgets('the balance takes the far left alone, «200 د.ل», and support the far right', (
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
    final support = tester.getRect(find.byTooltip('الدعم'));
    expect(find.text('200 د.ل'), findsOneWidget);
    expect(chip.right, lessThan(name.left));
    expect(support.left, greaterThan(tester.getRect(find.byTooltip('سلتك')).right));
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
