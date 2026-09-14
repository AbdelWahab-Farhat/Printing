import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/tools/presentation/widgets/tools_menu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// زرّ الأدوات في شريط التطبيق، بعد أن خرجت الأدوات من الدرج إلى جانب الجرس.
///
/// ما يستحقّ اختباراً هو ما ضاع بخروجها من الدرج: كانت الأدوات صفوفاً تحت عنوان، والعنوان
/// وحده كان يقول إنها أدوات. صارت الآن أيقونةً واحدة، فالقائمة التي تنفتح تحتها هي كل ما بقي
/// من ذاك العنوان — إن لم تحمل الأداتين كلتيهما، ضاعت واحدةٌ بلا بابٍ إليها.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// آخر مسارٍ دُفع، لأن ما يفعله الصفّ هو الذهاب إلى مكان — لا تغيير شيءٍ على الشاشة.
  String? pushed;

  setUp(() => pushed = null);

  Widget host() {
    Widget page(BuildContext context, GoRouterState state) {
      pushed = state.uri.path;
      return const Scaffold(body: SizedBox.shrink());
    }

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(appBar: null, body: SafeArea(child: ToolsMenuButton())),
        ),
        GoRoute(path: Routes.qrTool, builder: page),
        GoRoute(path: Routes.bagPreview, builder: page),
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

  testWidgets('closed, it is one glyph and no rows', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert — the wrench is the whole of it until it is tapped.
    expect(find.byIcon(AppIcons.tools), findsOneWidget);
    expect(find.text('إنشاء QR'), findsNothing);
    expect(find.text('معاينة التصميم'), findsNothing);
  });

  testWidgets('it opens onto both tools', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(ToolsMenuButton));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إنشاء QR'), findsOneWidget);
    expect(find.text('معاينة التصميم'), findsOneWidget);
  });

  testWidgets('إنشاء QR pushes the tool itself', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ToolsMenuButton));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إنشاء QR'));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, Routes.qrTool);
  });

  testWidgets('معاينة التصميم pushes the tool itself', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ToolsMenuButton));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('معاينة التصميم'));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, Routes.bagPreview);
  });
}
