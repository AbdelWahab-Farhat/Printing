import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/core/widgets/menu_card.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/presentation/views/profile_page.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// «حسابي»: بطاقةٌ تقول من أنت، وتحتها ثلاثة صفوف.
///
/// **البطاقة تحمل الاسم والهاتف وكود العميل** كما في المرجع الذي أرسله صاحب العمل، وبفرقٍ واحد
/// طلبه صراحة: الكود واضحٌ بما يكفي ليعرفه العميل — مسمّىً باسمه، في شارةٍ بيضاء تُنسخ بلمسة.
///
/// **والصفوف في بطاقةٍ واحدة:** «رمز QR» و«معاينة على الكيس» و«تصاميمي» أولاً، ثم الإعدادات
/// وسياسة الخصوصية (معطّلة إلى أن تُكتب) وتسجيل الخروج آخراً. «تواصل مع الدعم» خرج لأنه مكرّرٌ في
/// الرئيسية، و«مظهر التطبيق» انتقل إلى شاشة الإعدادات.
///
/// Arrange - Act - Assert throughout.
class _FakeAuth implements AuthRepository {
  _FakeAuth(this.account);

  final CustomerAccount account;

  /// كم مرة قُرئ الحساب — السحب للتحديث يقرأ مرة ثانية.
  int reads = 0;

  /// كم مرة سُجّل الخروج فعلاً، لا كم مرة فُتحت الورقة.
  int signOuts = 0;

  @override
  Future<Either<Failure, CustomerAccount>> currentCustomer() async {
    reads++;

    return Right(account);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    signOuts++;

    return const Right(unit);
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String phone,
    required String password,
    String? shopName,
    String? cityName,
    String? businessField,
  }) => throw UnimplementedError();

  @override
  bool get hasStoredToken => true;
}

void main() {
  const abdo = CustomerAccount(
    id: 1,
    name: 'عبدو',
    phone: '0944909852',
    code: 'B849',
    shop: CustomerShop(name: 'متجر النور', cityName: 'طرابلس'),
  );

  late _FakeAuth auth;

  /// الموجّه نفسه، ليُسأل هل فُتحت الشاشة *فوق* «حسابي» (`push`) أم حلّت محلّها (`go`).
  late GoRouter router;

  tearDown(() async {
    resetSnackBars();
    await sl.reset();
  });

  /// «حسابي» تحت موجّهٍ يعرف الإعدادات وشاشة الدخول، فيكون لكل انتقالٍ مكانٌ حقيقي يصل إليه.
  Future<void> open(WidgetTester tester, [CustomerAccount account = abdo]) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    auth = _FakeAuth(account);
    sl
      ..registerLazySingleton<GetCurrentCustomer>(() => GetCurrentCustomer(auth))
      ..registerLazySingleton<Logout>(() => Logout(auth));

    router = GoRouter(
      initialLocation: Routes.profile,
      routes: [
        GoRoute(path: Routes.profile, builder: (context, state) => const ProfilePage()),
        GoRoute(
          path: Routes.settings,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('شاشة الإعدادات'))),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(body: Center(child: Text('شاشة الدخول'))),
        ),
        for (final (path, screen) in [
          (Routes.qrTool, 'شاشة رمز QR'),
          (Routes.bagPreview, 'شاشة المعاينة'),
          (Routes.designs, 'شاشة تصاميمي'),
          (Routes.shops, 'شاشة متاجري'),
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Scaffold(body: Center(child: Text(screen))),
          ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the card', () {
    testWidgets('carries the name, the phone and the customer code', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.text('عبدو'), findsOneWidget);
      expect(find.text('0944909852'), findsOneWidget);
      expect(find.text('B849'), findsOneWidget);
    });

    testWidgets('names the code in the same chip, so the customer knows it is theirs', (
      tester,
    ) async {
      // Arrange & Act
      await open(tester);

      // Assert — الاسم والرقم في الشارة نفسها، لا الاسم في مكانٍ والرقم في آخر.
      final chip = find.byKey(ProfilePage.codeChipKey);

      expect(find.descendant(of: chip, matching: find.text('B849')), findsOneWidget);
      expect(find.descendant(of: chip, matching: find.text('كود العميل')), findsOneWidget);
    });

    testWidgets('copies the code when it is tapped', (tester) async {
      // Arrange — الحافظة قناةُ منصة لا وجود لها هنا، فيُلتقط ما أُرسل إليها.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        call,
      ) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }

        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await open(tester);

      // Act
      await tester.tap(find.text('B849'));
      await tester.pump(const Duration(milliseconds: 300));

      // Assert
      expect(copied, 'B849');
      expect(find.text('تم نسخ كود العميل'), findsOneWidget);

      resetSnackBars();
      await tester.pump();
    });

    testWidgets('says where the customer trades', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.text('متجر النور · طرابلس'), findsOneWidget);
      expect(find.byIcon(AppIcons.mapPin), findsOneWidget);
    });

    testWidgets('draws no location line for an account with no shop', (tester) async {
      // Arrange & Act — من سجّل من التطبيق لا متجر له حتى يضيفه الموظفون.
      await open(tester, const CustomerAccount(id: 2, name: 'سالم', phone: '0911111111'));

      // Assert
      expect(find.text('سالم'), findsOneWidget);
      expect(find.byIcon(AppIcons.mapPin), findsNothing);
    });

    testWidgets('draws no code chip before the server has given one', (tester) async {
      // Arrange & Act — شارةٌ برقمٍ مؤقت رقمٌ ليس لصاحبه.
      await open(tester, const CustomerAccount(id: 3, name: 'سالم', phone: '0911111111'));

      // Assert
      expect(find.byKey(ProfilePage.codeChipKey), findsNothing);
      expect(find.text('كود العميل'), findsNothing);
    });
  });

  group('the rows', () {
    testWidgets('are one list: «تصاميمي» first, signing out last', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert — بطاقةٌ واحدة لا اثنتان، و«تصاميمي» أولها، وتسجيل الخروج آخرها: كلاهما طلبه صاحب
      // العمل بعد أن رأى الشاشة على الهاتف. «تواصل مع الدعم» مكرّر في الرئيسية، و«مظهر التطبيق»
      // صار داخل الإعدادات.
      final cards = tester
          .widgetList<MenuCard>(find.byType(MenuCard))
          .map((card) => [for (final row in card.rows) row.label]);

      expect(cards, [
        [
          'تصاميمي',
          'متاجري',
          'رمز QR',
          'معاينة على الكيس',
          'الإعدادات',
          'سياسة الخصوصية',
          'تسجيل الخروج',
        ],
      ]);
    });

    for (final (label, screen) in [
      ('رمز QR', 'شاشة رمز QR'),
      ('معاينة على الكيس', 'شاشة المعاينة'),
      ('تصاميمي', 'شاشة تصاميمي'),
      ('متاجري', 'شاشة متاجري'),
    ]) {
      testWidgets('«$label» opens its screen over «حسابي», with the way back kept', (
        tester,
      ) async {
        // Arrange
        await open(tester);

        // Act
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        // Assert — `push` لا `go`: «حسابي» تبقى تحتها، فزر الرجوع يعيد إليها.
        expect(find.text(screen), findsOneWidget);
        expect(router.canPop(), isTrue);
      });
    }

    testWidgets('coming back from «متاجري» reads the account again — the card names a shop', (
      tester,
    ) async {
      // Arrange
      await open(tester);
      await tester.tap(find.text('متاجري'));
      await tester.pumpAndSettle();
      final readsBefore = auth.reads;

      // Act
      router.pop();
      await tester.pumpAndSettle();

      // Assert — أول المتاجر هو ما تسمّيه البطاقة، وقد يكون أُضيف أو عُدِّل أو حُذف هناك.
      expect(auth.reads, readsBefore + 1);
    });

    testWidgets('«الإعدادات» opens the settings screen', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('شاشة الإعدادات'), findsOneWidget);
    });

    testWidgets('the privacy policy is not open yet, and tapping it does nothing', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.text('سياسة الخصوصية'));
      await tester.pumpAndSettle();

      // Assert — لا انتقال ولا رسالة: الصف يقول «قريباً» قبل أن يُلمس.
      expect(find.text('قريباً'), findsOneWidget);
      expect(find.text('عبدو'), findsOneWidget);
      expect(find.text('ستتوفر قريباً'), findsNothing);
    });

    testWidgets('pulling down reads the account again', (tester) async {
      // Arrange
      await open(tester);
      expect(auth.reads, 1);

      // Act
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      // Assert
      expect(auth.reads, 2);
    });
  });

  group('signing out', () {
    testWidgets('asks first, in a sheet from the bottom', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.widgetWithText(MenuRow, 'تسجيل الخروج'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.signOuts, 0);
    });

    testWidgets('«إلغاء» leaves the customer signed in', (tester) async {
      // Arrange
      await open(tester);
      await tester.tap(find.widgetWithText(MenuRow, 'تسجيل الخروج'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'إلغاء'));
      await tester.pumpAndSettle();

      // Assert
      expect(auth.signOuts, 0);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('عبدو'), findsOneWidget);
    });

    testWidgets('confirming signs out and lands on the sign-in screen', (tester) async {
      // Arrange
      await open(tester);
      await tester.tap(find.widgetWithText(MenuRow, 'تسجيل الخروج'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'تسجيل الخروج'));
      await tester.pumpAndSettle();

      // Assert
      expect(auth.signOuts, 1);
      expect(find.text('شاشة الدخول'), findsOneWidget);
    });
  });
}
