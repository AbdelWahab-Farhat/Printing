import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/root/presentation/widgets/root_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The sidebar, now that its rows are filed under headings.
///
/// The thing worth proving is that folding the list did not lose anything or leak anything: every
/// row still reachable, still under the heading it belongs to, and still absent for an account the
/// server would answer with 403 — including the heading itself, once nothing is left under it.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// Everything the drawer asks for, so a test about layout is not silently a test about grants.
  const allGrants = [
    'products.view',
    'purchase_orders.view',
    'shipping_companies.view',
    'investors.view',
    'reports.pnl.view',
    'users.view',
    'roles.manage',
  ];

  /// Every screen the drawer can reach — the router has to know them, because tapping a row
  /// pushes one.
  const paths = [
    '/products',
    '/product-categories',
    '/business-fields',
    '/purchase-orders',
    '/shipping-companies',
    '/cities',
    '/investor-deals',
    '/reports/profit-loss',
    '/employees',
    '/roles',
    '/settings',
  ];

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> arrange(List<String> permissions) async {
    await Injector.reset();
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
    );
  }

  tearDown(Injector.reset);

  Widget host({String initialLocation = '/'}) {
    Widget page(BuildContext context, GoRouterState state) => Scaffold(
      key: state.uri.path == initialLocation ? scaffoldKey : null,
      drawer: const RootDrawer(),
      body: const SizedBox.shrink(),
    );

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: page),
        for (final path in paths) GoRoute(path: path, builder: page),
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
      ),
    );
  }

  Future<void> open(WidgetTester tester, {String at = '/'}) async {
    await tester.pumpWidget(host(initialLocation: at));
    await tester.pumpAndSettle();
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('closed, the drawer is headings and nothing else', (tester) async {
    // Arrange
    await arrange(allGrants);

    // Act
    await open(tester);

    // Assert — the four headings are there and none of their rows is.
    expect(find.text('المنتجات والخدمات'), findsOneWidget);
    expect(find.text('المشتريات والتوصيل'), findsOneWidget);
    expect(find.text('الاستثمار والمالية'), findsOneWidget);
    expect(find.text('الإدارة والصلاحيات'), findsOneWidget);
    expect(find.text('المنتجات'), findsNothing);
    expect(find.text('أوامر الشراء'), findsNothing);
  });

  testWidgets('a heading opens onto its own rows', (tester) async {
    // Arrange
    await arrange(allGrants);
    await open(tester);

    // Act
    await tester.tap(find.text('المنتجات والخدمات'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('تصنيفات المنتجات'), findsOneWidget);
    expect(find.text('مجالات العمل'), findsOneWidget);
  });

  testWidgets('opening one heading closes the one before it', (tester) async {
    // Arrange
    await arrange(allGrants);
    await open(tester);
    await tester.tap(find.text('المنتجات والخدمات'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('المشتريات والتوصيل'));
    await tester.pumpAndSettle();

    // Assert — the second is open, the first has folded itself away.
    expect(find.text('أوامر الشراء'), findsOneWidget);
    expect(find.text('شركات التوصيل'), findsOneWidget);
    expect(find.text('مدن التوصيل'), findsOneWidget);
    expect(find.text('المنتجات'), findsNothing);
  });

  testWidgets('every row of the old drawer is still filed somewhere', (tester) async {
    // Arrange
    await arrange(allGrants);
    await open(tester);

    // Act — open each heading in turn and collect what falls out of it.
    final found = <String>{};
    for (final heading in const [
      'المنتجات والخدمات',
      'المشتريات والتوصيل',
      'الاستثمار والمالية',
      'الإدارة والصلاحيات',
    ]) {
      await tester.tap(find.text(heading));
      await tester.pumpAndSettle();
      for (final row in const [
        'المنتجات',
        'تصنيفات المنتجات',
        'مجالات العمل',
        'أوامر الشراء',
        'شركات التوصيل',
        'مدن التوصيل',
        'صفقات المستثمرين',
        'الأرباح والخسائر',
        'الموظفون',
        'الأدوار والصلاحيات',
      ]) {
        if (find.text(row).evaluate().isNotEmpty) found.add(row);
      }
    }

    // Assert
    expect(found, hasLength(10));
  });

  testWidgets('a heading with nothing left under it does not appear', (tester) async {
    // Arrange — may read the catalogue, may not touch staff or roles.
    await arrange(['products.view']);

    // Act
    await open(tester);

    // Assert
    expect(find.text('المنتجات والخدمات'), findsOneWidget);
    expect(find.text('الإدارة والصلاحيات'), findsNothing);
    expect(find.text('الاستثمار والمالية'), findsNothing);
  });

  testWidgets('a row this reader may not open is not under its heading', (tester) async {
    // Arrange — orders yes, carriers no.
    await arrange(['purchase_orders.view']);
    await open(tester);

    // Act
    await tester.tap(find.text('المشتريات والتوصيل'));
    await tester.pumpAndSettle();

    // Assert — مدن التوصيل carries no grant at all, so it stays.
    expect(find.text('أوامر الشراء'), findsOneWidget);
    expect(find.text('مدن التوصيل'), findsOneWidget);
    expect(find.text('شركات التوصيل'), findsNothing);
  });

  testWidgets('الإعدادات stays a row of its own, outside every heading', (tester) async {
    // Arrange
    await arrange(allGrants);

    // Act
    await open(tester);

    // Assert
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('the screen being read opens its heading and marks its row', (tester) async {
    // Arrange
    await arrange(allGrants);

    // Act — arriving straight at تصنيفات المنتجات, as a reload or a deep link does.
    await open(tester, at: '/product-categories');

    // Assert — the heading unfolded itself, and the row says which screen this is.
    expect(find.text('تصنيفات المنتجات'), findsOneWidget);
    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('تصنيفات المنتجات'), matching: find.byType(ListTile)),
    );
    expect(tile.selected, isTrue);
  });

  testWidgets('the drawer scrolls rather than overflowing a short screen', (tester) async {
    // Arrange — a small phone, with a heading open on top of everything else.
    tester.view
      ..physicalSize = const Size(320 * 2, 480 * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await arrange(allGrants);
    await open(tester);

    // Act
    await tester.tap(find.text('المنتجات والخدمات'));
    await tester.pumpAndSettle();

    // Assert — no overflow was painted, and الإعدادات is still reachable at the foot.
    expect(tester.takeException(), isNull);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
