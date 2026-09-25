import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/features/auth/presentation/widgets/sign_out_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// تأكيد تسجيل الخروج: ورقةٌ من الأسفل، لا حوارٌ في وسط الشاشة.
///
/// **الورقة تسأل ولا تفعل.** تجيب بنعم أو لا وتُغلق، والشاشة التي فتحتها هي التي تُنهي الجلسة —
/// ولهذا تُختبر هنا بلا خادمٍ ولا توكن.
///
/// Arrange - Act - Assert throughout.
void main() {
  late bool? answer;

  setUp(() => answer = null);

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async => answer = await showSignOutSheet(context),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  /// مقاس الهاتف الذي صُمّم عليه التطبيق، لا سطح الاختبار الافتراضي (٨٠٠×٦٠٠).
  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('asks in a sheet from the bottom, not in a dialog', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('هل تريد تسجيل الخروج؟'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'تسجيل الخروج'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'إلغاء'), findsOneWidget);
  });

  testWidgets('the two answers sit side by side, signing out first', (tester) async {
    // Arrange & Act
    await open(tester);

    // Assert — سطرٌ واحد بنصفين متساويين، و«تسجيل الخروج» أوّلاً في القراءة، أي إلى اليمين.
    final confirm = tester.getRect(find.widgetWithText(AppButton, 'تسجيل الخروج'));
    final cancel = tester.getRect(find.widgetWithText(AppButton, 'إلغاء'));

    expect(confirm.center.dy, cancel.center.dy);
    expect(confirm.center.dx, greaterThan(cancel.center.dx));
    expect(confirm.width, cancel.width);
  });

  testWidgets('nothing in the sheet glows', (tester) async {
    // Arrange & Act — طلبه صاحب العمل صراحةً حين رأى الورقة على الهاتف.
    await open(tester);

    // Assert
    final glows = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: find.byType(BottomSheet), matching: find.byType(DecoratedBox)),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.boxShadow?.isNotEmpty ?? false);

    expect(glows, isEmpty);
  });

  testWidgets('confirming answers yes and closes the sheet', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'تسجيل الخروج'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer, isTrue);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('«إلغاء» answers no', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.tap(find.widgetWithText(AppButton, 'إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    expect(answer, isFalse);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('backing out answers no, the same as «إلغاء»', (tester) async {
    // Arrange — من غيّر رأيه أنهى السؤال بطريقةٍ عادية، ولا شيء يُقال له عن ذلك.
    await open(tester);

    // Act — الستارة فوق الورقة.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Assert — `false` لا `null`: من ينادي الورقة يسأل سؤالاً واحداً، هل خرج أم لا.
    expect(answer, isFalse);
  });
}
