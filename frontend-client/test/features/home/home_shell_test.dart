import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:dayaa_client/features/home/presentation/widgets/home_app_bar.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class _StubBadges implements BadgeRepository {
  @override
  Future<Either<Failure, Map<CustomerBadge, int>>> badges() async => const Right({});
}

/// الشريط السفلي: أربعة أماكن، أيقوناتٍ بلا كلمات. والشريط العلوي فوقها واحدٌ للأربعة.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host({bool reduceMotion = false}) {
    StatefulShellBranch branch(String path, String label) => StatefulShellBranch(
      routes: [
        GoRoute(path: path, builder: (context, state) => Scaffold(body: Text(label))),
      ],
    );

    final router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => HomeShell(shell: shell),
          branches: [
            branch('/', 'صفحة الرئيسية'),
            branch('/products', 'صفحة المنتجات'),
            branch('/orders', 'صفحة الطلبيات'),
            branch('/profile', 'صفحة حسابي'),
          ],
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
        ),
      ),
    );
  }

  /// أماكن الشريط السفلي وحده، لا الشريط العلوي الذي فيه «حسابي» أيقونةً.
  Finder inTabBar(Finder finder) => find.descendant(of: find.byType(GNav), matching: finder);

  setUp(() {
    // السلة في الشريط العلوي تقرأ المفرَد من `sl` مباشرة.
    sl.registerLazySingleton<CartCubit>(CartCubit.new);

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

  /// «حسابي» عادت إلى الشريط السفلي رابعةً (طلب المستخدم، 2026-09-25: «حط بروفايل تحت») بعد
  /// أن كانت أيقونةً في الشريط العلوي. و«تصاميمي» والأدوات صفوفٌ فيها. و«الخدمات» كانت تبويباً
  /// رابعاً ثم نُزعت: صفوفها كلها في «حسابي».
  testWidgets('four places, in reading order, «حسابي» last and none of «تصاميمي» «الخدمات»', (
    tester,
  ) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    const places = ['الرئيسية', 'المنتجات', 'طلباتي', 'حسابي'];

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — كما يسمعها قارئ الشاشة، ومن اليمين إلى اليسار.
    expect(find.byType(GButton), findsNWidgets(places.length));
    final fromTheRight = [
      for (final place in places) tester.getCenter(find.bySemanticsLabel(place)).dx,
    ];
    expect(fromTheRight, [...fromTheRight]..sort((a, b) => b.compareTo(a)));
    expect(inTabBar(find.bySemanticsLabel('تصاميمي')), findsNothing);
    expect(inTabBar(find.bySemanticsLabel('الخدمات')), findsNothing);

    semantics.dispose();
  });

  /// `GNav` يُسقط `semanticLabel` حين يعيد بناء أزراره، فيصل زرٌّ بلا كلمةٍ إلى قارئ الشاشة بلا
  /// اسمٍ أصلاً. هذا الاختبار يمسك من يعيد الاسم إلى هناك.
  testWidgets('the place on screen is announced as selected', (tester) async {
    // Arrange
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byIcon(AppIcons.orders));
    await tester.pumpAndSettle();

    // Assert
    expect(
      tester.getSemantics(find.bySemanticsLabel('طلباتي')),
      isSemantics(label: 'طلباتي', isSelected: true, hasTapAction: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('الرئيسية')),
      isSemantics(label: 'الرئيسية', isSelected: false, hasTapAction: true),
    );

    semantics.dispose();
  });

  testWidgets('the icons carry no words under them', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    final written = [
      for (final label in ['الرئيسية', 'المنتجات', 'طلباتي', 'حسابي']) find.text(label),
    ];

    // Assert
    for (final finder in written) {
      expect(finder, findsNothing);
    }
  });

  testWidgets('tapping «طلباتي» opens that section', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byIcon(AppIcons.orders));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('صفحة الطلبيات'), findsOneWidget);
  });

  testWidgets('for someone who turned motion off, the bar changes at once', (tester) async {
    // Arrange
    await tester.pumpWidget(host(reduceMotion: true));
    await tester.pumpAndSettle();

    // Act
    final bar = tester.widget<GNav>(find.byType(GNav));

    // Assert
    expect(bar.duration, Duration.zero);
  });

  // كان لكل قسمٍ شريطه: الاسم والدعم و«حسابي» في الرئيسية، و«المنتجات» والسلة في الكتالوج،
  // و«طلباتي» وحدها في الطلبيات — فيتبدّل أعلى الشاشة مع كل لمسةٍ في أسفلها. صار شريطاً واحداً
  // على الـ shell (طلب المستخدم، 2026-09-25).
  for (final (icon, place) in [
    (AppIcons.home, 'الرئيسية'),
    (AppIcons.products, 'المنتجات'),
    (AppIcons.orders, 'طلباتي'),
    (AppIcons.account, 'حسابي'),
  ]) {
    testWidgets('«$place» wears the shared top bar: the name and support', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(HomeAppBar), findsOneWidget);
      expect(find.text('FlyerX', findRichText: true), findsOneWidget);
      expect(find.byTooltip('الدعم'), findsOneWidget);
      // «حسابي» مكانٌ في الشريط السفلي الآن، لا أيقونةٌ في العلوي.
      expect(find.byTooltip('حسابي'), findsNothing);
    });
  }

  testWidgets('tapping «حسابي» opens that section', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byIcon(AppIcons.account));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('صفحة حسابي'), findsOneWidget);
  });

  testWidgets('changing place keeps the one bar rather than fading a new one in', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final bar = tester.element(find.byType(HomeAppBar));

    // Act
    await tester.tap(find.byIcon(AppIcons.products));
    await tester.pumpAndSettle();

    // Assert — العنصر نفسه لا نسخةٌ في كل قسم: يبقى ساكناً والصفحة تحته تتلاشى.
    expect(tester.element(find.byType(HomeAppBar)), same(bar));
  });
}
