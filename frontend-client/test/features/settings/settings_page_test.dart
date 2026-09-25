import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/features/settings/presentation/views/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «الإعدادات»: تفضيلات هذا الجهاز، وأوّلها المظهر.
///
/// كان «مظهر التطبيق» صفاً في «حسابي» نفسها، وانتقل إلى هنا حين صار لـ«حسابي» صفٌّ واحد اسمه
/// «الإعدادات». الحساب يقول من أنت، وهذه الشاشة تقول كيف يبدو التطبيق على هاتفك.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUp(() async {
    // جهازٌ اختار صاحبه الداكن من قبل، ليكون في الصف جوابٌ غير الافتراضي.
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    sl.registerSingleton<ThemeModeCubit>(
      ThemeModeCubit(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() => sl.reset());

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the appearance, and what it is set to without being opened', (
    tester,
  ) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('مظهر التطبيق'), findsOneWidget);
    expect(find.text('داكن'), findsOneWidget);
  });

  testWidgets('tapping it opens the appearance sheet', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.text('مظهر التطبيق'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('حسب النظام'), findsOneWidget);
  });

  testWidgets('a choice made in the sheet is what the row says afterwards', (tester) async {
    // Arrange
    await open(tester);
    await tester.tap(find.text('مظهر التطبيق'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('فاتح'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('فاتح'), findsOneWidget);
    expect(find.text('داكن'), findsNothing);
  });
}
