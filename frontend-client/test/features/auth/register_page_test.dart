import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/register_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/views/register_page.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// شاشة إنشاء الحساب بلغة شاشة الدخول نفسها: الترويسة الكحلية والبطاقة العائمة والحقول المعنونة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockAuthRepository repository;
  late GoRouter router;

  setUp(() async {
    await Injector.reset();
    repository = _MockAuthRepository();
    sl.registerFactory<RegisterCubit>(() => RegisterCubit(register: Register(repository)));
  });

  /// التطبيق كما يُقلع. [initial] هي الشاشة الأولى: الدخول عادةً، ومنها تُفتح هذه فوقها.
  Widget host({String initial = '/login'}) {
    router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const Text('شاشة الدخول')),
        GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
        GoRoute(path: '/', builder: (context, state) => const Text('الرئيسية')),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
        theme: const MaterialTheme(TextTheme()).light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  /// هاتفٌ بالمقاس المرجعي ٤٣٠×٩٣٢، لا سطح الاختبار الافتراضي ٨٠٠×٦٠٠ الذي تكبر عليه الخطوط
  /// ١٫٨ مرة فيخرج نصف الشاشة عنها.
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// تفتح الشاشة فوق الدخول، كما يفتحها «إنشاء حساب جديد».
  Future<void> openFromSignIn(WidgetTester tester) async {
    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    // الوعد يكتمل حين تُغلق الشاشة المفتوحة، فانتظاره هنا لا ينتهي.
    unawaited(router.push('/register'));
    await tester.pumpAndSettle();
  }

  /// الحقل الذي يحمل [label] — بعنوانه لا بترتيبه.
  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
    matching: find.byType(EditableText),
  );

  testWidgets('it opens on its own header, four labelled fields and one button', (tester) async {
    // Arrange
    await openFromSignIn(tester);

    // Act
    final fields = [
      for (final label in ['الاسم', 'رقم الهاتف', 'كلمة المرور', 'تأكيد كلمة المرور'])
        fieldLabelled(label),
    ];

    // Assert
    expect(find.text('أنشئ حسابك'), findsOneWidget);
    for (final field in fields) {
      expect(field, findsOneWidget);
    }
    expect(find.text('إنشاء الحساب'), findsOneWidget);
    expect(find.text('لديك حساب؟'), findsOneWidget);
  });

  testWidgets('the link under the card goes back to sign-in', (tester) async {
    // Arrange
    await openFromSignIn(tester);

    // Act
    await tester.ensureVisible(find.text('سجّل الدخول'));
    await tester.tap(find.text('سجّل الدخول'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة الدخول'), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
  });

  testWidgets('opened over sign-in, it offers the way back', (tester) async {
    // Arrange
    await openFromSignIn(tester);

    // Act
    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة الدخول'), findsOneWidget);
  });

  testWidgets('opened on its own, it draws no arrow to nowhere', (tester) async {
    // Arrange
    usePhone(tester);
    await tester.pumpWidget(host(initial: '/register'));

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.byIcon(AppIcons.back), findsNothing);
  });

  testWidgets('a confirmation that does not match is refused under its field', (tester) async {
    // Arrange
    await openFromSignIn(tester);
    await tester.enterText(fieldLabelled('الاسم'), 'متجر النور');
    await tester.enterText(fieldLabelled('رقم الهاتف'), '0911111111');
    await tester.enterText(fieldLabelled('كلمة المرور'), 'password123');
    await tester.enterText(fieldLabelled('تأكيد كلمة المرور'), 'password124');

    // Act
    await tester.ensureVisible(find.text('إنشاء الحساب'));
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump();

    // Assert
    expect(find.text('تأكيد كلمة المرور لا يطابقها'), findsOneWidget);
    verifyNever(
      () => repository.register(
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    );
  });
}
