import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/empty_basket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// السلة الفارغة: كيسٌ مفتوحٌ لا شيء فيه بدل السطر الأحمر «لا توجد منتجات في هذه الطلبية.»
/// (طلب المستخدم، 2026-09-25: «بصورة وبشكل جميل تبين انه سلة فارغة»).
///
/// Arrange - Act - Assert throughout.
void main() {
  final light = ColorScheme.fromSeed(seedColor: const Color(0xfff4622a));
  final dark = ColorScheme.fromSeed(
    seedColor: const Color(0xfff4622a),
    brightness: Brightness.dark,
  );

  /// السلة فوق الـ shell كما هي في التطبيق، و«المنتجات» تبويبٌ يُنتقل إليه.
  Widget host({ColorScheme? scheme, double height = 800}) {
    final router = GoRouter(
      initialLocation: Routes.newOrder,
      routes: [
        GoRoute(
          path: Routes.products,
          builder: (context, state) => const Scaffold(body: Text('شاشة المنتجات')),
        ),
        GoRoute(
          path: Routes.newOrder,
          builder: (context, state) => Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: height, child: const EmptyBasket()),
            ),
          ),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        theme: ThemeData(colorScheme: scheme ?? light),
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

  /// ما يستبدل به الرسمُ لوناً بديلاً من ملفه.
  Color paint(WidgetTester tester, int placeholder) {
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    final loader = picture.bytesLoader as SvgAssetLoader;

    return loader.colorMapper!.substitute(null, 'path', 'fill', Color(placeholder));
  }

  testWidgets('says the basket is empty, over a drawing of an empty bag', (tester) async {
    // Arrange
    final app = host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert — لا أحمر: سلةٌ فارغة حالةٌ لا خطأ.
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));

    expect(find.text('سلتك فارغة'), findsOneWidget);
    expect((picture.bytesLoader as SvgAssetLoader).assetName, EmptyBasket.illustration);
    expect(find.text('لا توجد منتجات في هذه الطلبية.'), findsNothing);
  });

  testWidgets('the bag is painted in the theme\'s colours, light and dark', (tester) async {
    // Arrange
    await tester.pumpWidget(host(scheme: dark));
    await tester.pumpAndSettle();

    // Act
    final bag = paint(tester, 0xFFFF0000);
    final side = paint(tester, 0xFF990000);
    final disc = paint(tester, 0xFFFF00FF);
    final untouched = paint(tester, 0xFF123456);

    // Assert — الكيس بلون العلامة، والدائرة خلفه بلون حاويات الوضع الداكن.
    expect(bag, dark.primary);
    expect(side, dark.primaryDeep);
    expect(disc, dark.surfaceContainerHigh);
    expect(untouched, const Color(0xFF123456));
  });

  testWidgets('«تصفّح المنتجات» leaves the basket for the catalogue', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('تصفّح المنتجات'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة المنتجات'), findsOneWidget);
    expect(find.byType(EmptyBasket), findsNothing);
  });

  testWidgets('a short screen scrolls rather than overflowing', (tester) async {
    // Arrange
    final app = host(height: 260);

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert — شريطٌ أصفر وأسود في منتصف السلة هو ما يُمنع هنا.
    expect(tester.takeException(), isNull);
    expect(find.text('سلتك فارغة'), findsOneWidget);
  });

  test('the drawing is bundled, in the placeholder colours the widget maps', () async {
    // Arrange — ملفٌّ يُعاد رسمه بألوانٍ حقيقية لا يتبع الثيم، وهذا ما يُمسك هنا.
    TestWidgetsFlutterBinding.ensureInitialized();

    // Act
    final source = await rootBundle.loadString(EmptyBasket.illustration);

    // Assert
    expect(source, contains('<svg'));
    for (final placeholder in ['#FF00FF', '#FF0000', '#990000']) {
      expect(source, contains(placeholder));
    }
  });
}
