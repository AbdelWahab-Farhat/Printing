import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/features/home/presentation/views/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

/// الشريط السفلي: ثلاثة أماكن، أيقوناتٍ بلا كلمات.
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
          ],
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
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
    );
  }

  setUp(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  /// «حسابي» في شريط الرئيسية العلوي، و«تصاميمي» والأدوات صفوفٌ فيها. و«الخدمات» كانت تبويباً
  /// رابعاً ثم نُزعت في اليوم نفسه (طلب المستخدم، 2026-09-25): صفوفها كلها في «حسابي».
  testWidgets('three places, in reading order, and none of «حسابي» «تصاميمي» «الخدمات»', (
    tester,
  ) async {
    // Arrange
    final semantics = tester.ensureSemantics();

    const places = ['الرئيسية', 'المنتجات', 'طلباتي'];

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — كما يسمعها قارئ الشاشة، ومن اليمين إلى اليسار.
    expect(find.byType(GButton), findsNWidgets(places.length));
    final fromTheRight = [
      for (final place in places) tester.getCenter(find.bySemanticsLabel(place)).dx,
    ];
    expect(fromTheRight, [...fromTheRight]..sort((a, b) => b.compareTo(a)));
    expect(find.bySemanticsLabel('حسابي'), findsNothing);
    expect(find.bySemanticsLabel('تصاميمي'), findsNothing);
    expect(find.bySemanticsLabel('الخدمات'), findsNothing);

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
      for (final label in ['الرئيسية', 'المنتجات', 'طلباتي']) find.text(label),
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
}
