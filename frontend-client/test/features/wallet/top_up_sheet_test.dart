import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// EzonePay in memory — Libyana by OTP, a card by link, and Sadad with its limit used up.
class _FakeTopUp implements TopUpRepository {
  final List<TopUpRequest> started = [];
  final List<String> codes = [];

  @override
  Future<Either<Failure, TopUpMethods>> methods() async => const Right(
    TopUpMethods(
      enabled: true,
      feePayer: 'customer',
      methods: [
        TopUpMethod(
          id: 111,
          label: 'رصيد ليبيانا',
          flow: 'otp',
          feePercentage: '2.5',
          remaining: ['300.00'],
        ),
        TopUpMethod(id: 101, label: 'بطاقة مصرفية (معاملات)', flow: 'link', feePercentage: '2.5'),
        TopUpMethod(
          id: 107,
          label: 'سداد',
          flow: 'otp',
          feePercentage: '2.5',
          needsServiceMobileNumber: true,
          needsBirthYear: true,
          remaining: ['0.00'],
        ),
      ],
    ),
  );

  @override
  Future<Either<Failure, TopUpQuote>> quote({required int method, required String amount}) async =>
      const Right(TopUpQuote(amount: '100.00', total: '102.57', fee: '2.57'));

  @override
  Future<Either<Failure, TopUpAnswer>> start(TopUpRequest request) async {
    started.add(request);

    return Right(_answer('pending'));
  }

  /// EzonePay takes the code but does not yet say «تم الدفع» — the sandbox, 2026-10-11.
  bool takesCodeUnclear = false;

  /// What the poll answers.
  String shown = 'pending';

  @override
  Future<Either<Failure, TopUpAnswer>> confirmOtp(String attemptId, String otp) async {
    codes.add(otp);

    return Right(takesCodeUnclear ? _answer('pending', confirming: true) : _answer('succeeded'));
  }

  @override
  Future<Either<Failure, TopUpAnswer>> show(String attemptId) async =>
      Right(_answer(shown, confirming: takesCodeUnclear));

  static TopUpAnswer _answer(String status, {bool confirming = false}) => TopUpAnswer(
    attempt: TopUpAttempt(
      id: '0b9e',
      methodId: 111,
      methodLabel: 'رصيد ليبيانا',
      flow: 'otp',
      status: status,
      statusLabel: status,
      isFinal: status == 'succeeded',
      requiresOtp: status == 'pending' && !confirming,
      otpAttemptsLeft: 3,
      amount: '100.00',
      total: '102.57',
      fee: '2.57',
    ),
    balance: status == 'succeeded' ? '100.00' : '0.00',
  );
}

/// «اشحن محفظتك» ورقةً على نسق بريمولا — الطرق بشعاراتها، ثم البيانات وصندوق العمولة، ثم مربّعات
/// الرمز. CUSTOMER-WALLET §٥.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakeTopUp fake;
  bool? result;

  tearDown(() async {
    resetSnackBars();
    await sl.reset();
  });

  /// Spinners turn while a request is out; a fixed pump, not `pumpAndSettle`.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openSheet(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    fake = _FakeTopUp();
    result = null;
    sl
      ..registerLazySingleton(() => GetTopUpMethods(fake))
      ..registerLazySingleton(() => QuoteTopUp(fake))
      ..registerLazySingleton(() => StartTopUp(fake))
      ..registerLazySingleton(() => ConfirmTopUpOtp(fake))
      ..registerLazySingleton(() => GetTopUpAttempt(fake));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showTopUpSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);
  }

  testWidgets('the methods come first, each with its logo, its bank and what is left of it', (tester) async {
    // Arrange & Act
    await openSheet(tester);

    // Assert
    expect(find.text('حدد طريقة الشحن'), findsOneWidget);
    expect(find.text('رصيد ليبيانا'), findsOneWidget);
    expect(find.text('المتبقّي: 300 د.ل'), findsOneWidget);
    expect(find.text('خاصة بشركة المدار'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
  });

  testWidgets('a method whose limit is used up says so and cannot be picked', (tester) async {
    // Arrange
    await openSheet(tester);

    // Act
    await tester.tap(find.text('سداد'));
    await settle(tester);

    // Assert
    expect(find.text('تم بلوغ الحد المسموح'), findsOneWidget);
    expect(find.text('حدد طريقة الشحن'), findsOneWidget);
  });

  testWidgets('picking a method slides to its details, with the fee box', (tester) async {
    // Arrange
    await openSheet(tester);

    // Act
    await tester.tap(find.text('رصيد ليبيانا'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '100');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await settle(tester);

    // Assert — the title is the method, and the server's quote fills the box.
    expect(find.text('رصيد ليبيانا'), findsWidgets);
    expect(find.text('العمولة (2.5%)'), findsOneWidget);
    expect(find.text('سيتم خصم'), findsOneWidget);
    expect(find.text('102.57 د.ل'), findsOneWidget);
    expect(find.text('تأكيد البيانات'), findsOneWidget);
  });

  testWidgets('an OTP method ends on the code boxes, and the full code tops the wallet up', (tester) async {
    // Arrange
    await openSheet(tester);
    await tester.tap(find.text('رصيد ليبيانا'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '100');
    await settle(tester);

    // Act
    await tester.tap(find.text('تأكيد البيانات'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);
    final onCode = find.text('أدخل رمز التحقق').evaluate().isNotEmpty;
    await tester.enterText(find.byKey(const Key('otp-field')), '١٢٣٤٥٦');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);
    // «تمت تعبئة محفظتك» stays a few seconds; let it go before the test ends.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Assert — Arabic digits arrive Latin; the sheet closes saying so, and hands back `true`.
    expect(onCode, isTrue);
    expect(fake.started.single.amount, '100');
    expect(fake.codes, ['123456']);
    expect(find.text('أدخل رمز التحقق'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('a code taken but not yet confirmed shows «نتحقق من الدفع», asks no second code, and the poll ends it', (
    tester,
  ) async {
    // Arrange
    await openSheet(tester);
    fake.takesCodeUnclear = true;
    await tester.tap(find.text('رصيد ليبيانا'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '100');
    await settle(tester);
    await tester.tap(find.text('تأكيد البيانات'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);

    // Act — the code goes in; EzonePay takes it.
    await tester.enterText(find.byKey(const Key('otp-field')), '123456');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);

    // Assert — waiting, with no code boxes to send another.
    expect(find.byKey(const Key('confirming')), findsOneWidget);
    expect(find.text('تأكيد الدفع'), findsOneWidget);
    expect(find.byKey(const Key('otp-field')), findsNothing);

    // Act — EzonePay now says paid; the next poll hears it.
    fake.shown = 'succeeded';
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await settle(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Assert — credited, the sheet closed, and the code was sent once.
    expect(result, isTrue);
    expect(fake.codes, ['123456']);
  });
}
