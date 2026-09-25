import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/presentation/views/login_page.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// شاشة الدخول كما رسمها التصميم: ترويسةٌ كحلية، وبطاقةٌ عائمة بحقلين معنونين وزرٍّ واحد، ورابطٌ
/// إلى إنشاء الحساب تحتها.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockAuthRepository repository;

  const account = CustomerAccount(id: 1, name: 'متجر النور', phone: '0911111111');
  const session = AuthSession(customer: account, token: 'tok');

  setUp(() async {
    await Injector.reset();
    repository = _MockAuthRepository();
    sl.registerFactory<LoginCubit>(() => LoginCubit(login: Login(repository)));
  });

  /// التطبيق كما يُقلع: الشاشة في موجّهٍ حقيقي، فالرابط والرجوع يعملان كما على الهاتف.
  Widget host() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/register', builder: (context, state) => const Text('شاشة التسجيل')),
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

  /// الحقل الذي يحمل [label] — بعنوانه لا بترتيبه.
  Finder fieldLabelled(String label) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(AppTextField)),
    matching: find.byType(EditableText),
  );

  /// التوست يبقى ثلاث ثوانٍ ثم ينسحب؛ يُنتظر حتى يغيب كي لا يبقى مؤقّتٌ معلّق بعد الاختبار.
  Future<void> outlastToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('it opens on the welcome, two labelled fields and one button', (tester) async {
    // Arrange
    usePhone(tester);
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أهلاً بك مجدداً'), findsOneWidget);
    expect(find.text('سجّل دخولك لمتابعة طلبياتك'), findsOneWidget);
    expect(fieldLabelled('رقم الهاتف'), findsOneWidget);
    expect(fieldLabelled('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.text('ليس لديك حساب؟'), findsOneWidget);
  });

  testWidgets('the link under the card opens the sign-up screen', (tester) async {
    // Arrange
    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.ensureVisible(find.text('إنشاء حساب جديد'));
    await tester.tap(find.text('إنشاء حساب جديد'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شاشة التسجيل'), findsOneWidget);
  });

  testWidgets('«نسيتها؟» says the way back is coming, instead of going nowhere', (tester) async {
    // Arrange
    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('نسيتها؟'));
    await tester.pump(const Duration(milliseconds: 300));

    // Assert
    expect(find.text('ستتوفر قريباً'), findsOneWidget);
    await outlastToast(tester);
  });

  testWidgets('the terms say the same, rather than opening nothing', (tester) async {
    // Arrange
    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.ensureVisible(find.textContaining('شروط الاستخدام'));
    await tester.tapOnText(find.textRange.ofSubstring('شروط الاستخدام'));
    await tester.pump(const Duration(milliseconds: 300));

    // Assert
    expect(find.text('ستتوفر قريباً'), findsOneWidget);
    await outlastToast(tester);
  });

  testWidgets('what was typed is what is sent', (tester) async {
    // Arrange
    when(
      () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
    ).thenAnswer((_) async => const Right(session));
    usePhone(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('رقم الهاتف'), '0911111111');
    await tester.enterText(fieldLabelled('كلمة المرور'), 'password123');

    // Act
    await tester.tap(find.text('دخول'));
    await tester.pump();

    // Assert
    verify(() => repository.login(phone: '0911111111', password: 'password123')).called(1);
    await outlastToast(tester);
  });
}
