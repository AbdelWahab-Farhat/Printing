import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/svg_icon.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// السلة في الشريط العلوي، مكانَ الجرس الذي أُزيل (طلب المستخدم، 2026-09-25).
///
/// كانت زرّاً عائماً فوق الشريط السفلي يغطّي سعرَ البطاقة التي تحته، وبأيقونة المستند نفسها التي
/// يلبسها تبويب «طلباتي»، فبدت اختصاراً إليه. الآن هي عربةُ تسوّقٍ SVG على مثالٍ أرسله المستخدم،
/// في أقصى يسار الشريط، والعددُ أحمرُ على كتفها الأيمن.
///
/// **مقيسةٌ لا منظورة:** خطأ التخطيط لا يرمي استثناءً ولا يُحمِّر اختباراً.
///
/// Arrange - Act - Assert throughout.
void main() {
  OrderDraftLine line({int productId = 1}) => OrderDraftLine(
    line: NewOrderLine(productId: productId, productVariantId: 1, quantity: '1000'),
    title: 'منتج $productId',
  );

  setUp(() => sl.registerLazySingleton<CartCubit>(CartCubit.new));
  tearDown(() => sl.reset());

  /// شريط «المنتجات» كما هو: العنوان، والسلة وحدها في `actions`.
  Widget host() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('المنتجات'), actions: const [CartButton()]),
            body: const SizedBox.expand(),
          ),
        ),
        GoRoute(
          path: Routes.newOrder,
          builder: (context, state) => Scaffold(appBar: AppBar(title: const Text('شاشة السلة'))),
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
      ),
    );
  }

  testWidgets('an empty basket draws nothing in the bar', (tester) async {
    // Arrange
    final app = host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert — أيقونة سلةٍ بلا رقم دعوةٌ للضغط لاكتشاف أنها فارغة.
    expect(find.byTooltip('سلتك'), findsNothing);
  });

  testWidgets('it sits at the far left of the top bar, where the bell was', (tester) async {
    // Arrange
    sl<CartCubit>().add(line());

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — آخر `actions` في شريطٍ عربي هو الأقرب إلى الحافة اليسرى.
    final button = tester.getRect(find.byTooltip('سلتك'));
    final bar = tester.getRect(find.byType(AppBar));

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byTooltip('سلتك')),
      findsOneWidget,
    );
    expect(button.center.dx, lessThan(bar.center.dx));
  });

  testWidgets('the count is drawn on it', (tester) async {
    // Arrange — منتجان مختلفان، فلا يكون الرقم «1» الذي قد يرسمه خطأٌ أيضاً.
    sl<CartCubit>()
      ..add(line())
      ..add(line(productId: 2));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('it wears the cart drawing, not the document the «طلباتي» tab wears', (
    tester,
  ) async {
    // Arrange
    sl<CartCubit>().add(line());

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final basket = find.byTooltip('سلتك');
    final glyph = tester.widget<SvgIcon>(
      find.descendant(of: basket, matching: find.byType(SvgIcon)),
    );

    expect(glyph.asset, SvgIcon.cart);
    expect(find.descendant(of: basket, matching: find.byIcon(AppIcons.orders)), findsNothing);
  });

  testWidgets('the count hangs red on the cart\'s top right, like the badge on «الدعم»', (
    tester,
  ) async {
    // Arrange
    sl<CartCubit>().add(line());

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — على كتف العربة فوق سلّتها كما في المثال، لا فوق المقبض.
    final count = find.text('1');
    final badge = tester.getCenter(count);
    final glyph = tester.getCenter(find.byType(SvgIcon));
    final pill = tester.widget<Container>(
      find.ancestor(of: count, matching: find.byType(Container)).first,
    );
    final scheme = Theme.of(tester.element(count)).colorScheme;

    expect(badge.dx, greaterThan(glyph.dx));
    expect(badge.dy, lessThan(glyph.dy));
    expect((pill.decoration! as BoxDecoration).color, scheme.error);
  });

  testWidgets('tapping it opens the basket, with a way back', (tester) async {
    // Arrange
    sl<CartCubit>().add(line());
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('سلتك'));
    await tester.pumpAndSettle();

    // Assert — `push` لا `go`: السلة تُفتح فوق الكتالوج ويُرجع منها إليه.
    expect(find.text('شاشة السلة'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
