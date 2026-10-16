import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/top_up_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/payment_gateway_page.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// ── a browser that is not one ───────────────────────────────────────────────────────────

class _FakeWebViewPlatform extends WebViewPlatform {
  final List<Uri> loaded = [];

  @override
  PlatformWebViewController createPlatformWebViewController(PlatformWebViewControllerCreationParams params) =>
      _FakeController(params, loaded);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(PlatformNavigationDelegateCreationParams params) =>
      _FakeNavigation(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) =>
      _FakeWidget(params);
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params, this.loaded) : super.implementation();

  final List<Uri> loaded;

  @override
  Future<void> loadRequest(LoadRequestParams params) async => loaded.add(params.uri);

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {}

  @override
  Future<bool> canGoBack() async => false;

  @override
  Future<void> reload() async {}
}

class _FakeNavigation extends PlatformNavigationDelegate {
  _FakeNavigation(super.params) : super.implementation();

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}
}

class _FakeWidget extends PlatformWebViewWidget {
  _FakeWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand(key: Key('browser'));
}

// ── EzonePay in memory ──────────────────────────────────────────────────────────────────

class _FakeTopUp implements TopUpRepository {
  /// What the next question answers.
  TopUpAnswer answer = _attempt('pending');

  @override
  Future<Either<Failure, TopUpMethods>> methods() async => const Right(
    TopUpMethods(
      enabled: true,
      feePayer: 'customer',
      methods: [TopUpMethod(id: 101, label: 'بطاقة مصرفية', flow: 'link', feePercentage: '1.5')],
    ),
  );

  @override
  Future<Either<Failure, TopUpQuote>> quote({required int method, required String amount}) async =>
      const Right(TopUpQuote(amount: '100.00', total: '101.50', fee: '1.50'));

  @override
  Future<Either<Failure, TopUpAnswer>> start(TopUpRequest request) async => Right(_attempt('pending'));

  @override
  Future<Either<Failure, TopUpAnswer>> confirmOtp(String attemptId, String otp) => throw UnimplementedError();

  @override
  Future<Either<Failure, TopUpAnswer>> show(String attemptId) async => Right(answer);
}

const _url = 'https://pay.example.test/l/77';

TopUpAnswer _attempt(String status) => TopUpAnswer(
  attempt: TopUpAttempt(
    id: '0b9e',
    methodLabel: 'بطاقة مصرفية',
    flow: 'link',
    status: status,
    statusLabel: status,
    isFinal: status != 'pending',
    paymentUrl: status == 'pending' ? _url : null,
    amount: '100.00',
    total: '101.50',
    fee: '1.50',
  ),
  balance: status == 'succeeded' ? '100.00' : '0.00',
);

/// «بوابة الدفع» داخل التطبيق — كما في بريمولا: تُغلق نفسها حين يصل المال، و✕ يسأل الخادم أولاً
/// ثم يؤكّد. CUSTOMER-WALLET §٥.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _FakeTopUp fake;
  late _FakeWebViewPlatform browser;
  late TopUpCubit cubit;

  /// Long enough for a route or a dialog to arrive or leave. Not `pumpAndSettle`: the page's
  /// first-load spinner turns until a real browser says the page loaded, which this one never does.
  Future<void> settle(WidgetTester tester) async {
    // Three frames: the state lands, the page closes after the frame that rebuilt it, and the
    // route animates out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// «اشحن محفظتك» وقد بدأ الشحن بالبطاقة، والبوابة مفتوحة فوقها.
  Future<void> openGateway(WidgetTester tester) async {
    fake = _FakeTopUp();
    browser = _FakeWebViewPlatform();
    WebViewPlatform.instance = browser;
    cubit = TopUpCubit(
      getMethods: GetTopUpMethods(fake),
      quote: QuoteTopUp(fake),
      start: StartTopUp(fake),
      confirmOtp: ConfirmTopUpOtp(fake),
      getAttempt: GetTopUpAttempt(fake),
      initialAmount: '100',
      // The test asks; nothing asks by itself.
      pollEvery: const Duration(hours: 1),
      quoteDelay: Duration.zero,
    );
    addTearDown(cubit.close);

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
          home: BlocProvider<TopUpCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => PaymentGatewayPage.open(context, _url),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      await cubit.load();
      await cubit.start();
    });
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('the card page opens inside the app, on the link the server gave', (tester) async {
    // Arrange & Act
    await openGateway(tester);

    // Assert
    expect(find.byKey(const Key('browser')), findsOneWidget);
    expect(find.text('بوابة الدفع'), findsOneWidget);
    expect(find.text('pay.example.test'), findsOneWidget);
    expect(browser.loaded, [Uri.parse(_url)]);
  });

  testWidgets('it closes by itself the moment the money lands', (tester) async {
    // Arrange
    await openGateway(tester);
    fake.answer = _attempt('succeeded');

    // Act
    await tester.runAsync(cubit.check);
    await settle(tester);

    // Assert
    expect(find.byType(PaymentGatewayPage), findsNothing);
    expect(cubit.state, isA<TopUpDone>());
  });

  testWidgets('✕ asks the server first — paid meanwhile, it closes with no question', (tester) async {
    // Arrange
    await openGateway(tester);
    fake.answer = _attempt('succeeded');

    // Act
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);

    // Assert
    expect(find.text('إلغاء عملية الدفع'), findsNothing);
    expect(find.byType(PaymentGatewayPage), findsNothing);
  });

  testWidgets('✕ while still unpaid asks before leaving, and «متابعة الدفع» stays', (tester) async {
    // Arrange
    await openGateway(tester);

    // Act
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);
    final asked = find.text('إلغاء عملية الدفع').evaluate().isNotEmpty;
    await tester.tap(find.text('متابعة الدفع'));
    await settle(tester);

    // Assert
    expect(asked, isTrue);
    expect(find.byType(PaymentGatewayPage), findsOneWidget);
  });

  testWidgets('«خروج» leaves the page, and the attempt keeps waiting behind it', (tester) async {
    // Arrange
    await openGateway(tester);
    await tester.tap(find.byTooltip('إغلاق'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await settle(tester);

    // Act
    await tester.tap(find.text('خروج'));
    await settle(tester);

    // Assert
    expect(find.byType(PaymentGatewayPage), findsNothing);
    expect(cubit.state, isA<TopUpWaiting>());
  });
}
