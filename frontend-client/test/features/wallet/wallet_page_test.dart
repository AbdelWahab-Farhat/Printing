import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/wallet_page.dart';
import 'package:dayaa_client/features/wallet/repositories/top_up_repository.dart';
import 'package:dayaa_client/features/wallet/repositories/wallet_repository.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockWallet extends Mock implements WalletRepository {}

class _MockTopUp extends Mock implements TopUpRepository {}

/// طريقة شحنٍ كما يرسلها الخادم — `otp` تُعرض، و`qr` لا (لا ماسح في التطبيق).
TopUpMethod _method(int id, {String flow = 'otp'}) => TopUpMethod(
  id: id,
  label: 'طريقة $id',
  flow: flow,
  feePercentage: '2.5',
  needsCardNumber: false,
  needsServiceMobileNumber: false,
  needsBirthYear: false,
  remaining: const [],
);

/// صورةٌ محزومة باسمها — شعار طريقة الدفع.
Finder _logo(String asset) => find.byWidgetPredicate(
  (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName == asset,
);

/// «محفظتي» بتصميم «بطاقة FlyerX»: بطاقةٌ كحلية بالرصيد والاسم والرمز، تحتها «شحن المحفظة» بشعارات
/// طرق الدفع، ثم المعاملات سطراً سطراً تحت أيامها.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUpAll(() => registerFallbackValue(MyWalletFilter.all));

  tearDown(() async => sl.reset());

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9, 15);
  final earlierToday = DateTime(now.year, now.month, now.day, 8);
  final yesterday = DateTime(now.year, now.month, now.day - 1, 16, 5);

  Future<void> open(
    WidgetTester tester, {
    required bool topUpEnabled,
    List<TopUpMethod> methods = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final auth = _MockAuth();
    final wallet = _MockWallet();
    final topUp = _MockTopUp();

    when(auth.currentCustomer).thenAnswer(
      (_) async => const Right(CustomerAccount(id: 3, name: 'علي', phone: '0911111111', code: 'C-102')),
    );
    when(() => wallet.entries(page: any(named: 'page'), filter: any(named: 'filter'))).thenAnswer(
      (_) async => Right(
        Paginated(
          items: [
            MyWalletEntry(
              id: 4,
              type: 'order_payment',
              typeLabel: 'دفع طلبية',
              isIn: false,
              amount: '40.00',
              orderId: 1286,
              orderCode: '1286',
              occurredAt: today,
            ),
            MyWalletEntry(
              id: 3,
              type: 'topup',
              typeLabel: 'شحن المحفظة',
              isIn: true,
              amount: '100.00',
              method: 'online',
              onlineMethod: 103,
              methodLabel: 'ون باي',
              occurredAt: earlierToday,
            ),
            MyWalletEntry(
              id: 2,
              type: 'order_refund',
              typeLabel: 'ردّ إلى المحفظة',
              isIn: true,
              amount: '20.00',
              orderId: 1280,
              orderCode: '1280',
              occurredAt: yesterday,
            ),
            MyWalletEntry(
              id: 1,
              type: 'topup',
              typeLabel: 'شحن المحفظة',
              isIn: true,
              amount: '50.00',
              method: 'cash',
              methodLabel: 'كاش',
              isReversed: true,
              occurredAt: yesterday,
            ),
          ],
          meta: const PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 4),
          extraMeta: const {'balance': '60.00'},
        ),
      ),
    );
    when(topUp.methods).thenAnswer(
      (_) async => Right(TopUpMethods(enabled: topUpEnabled, feePayer: 'customer', methods: methods)),
    );

    sl
      ..registerLazySingleton(() => GetCurrentCustomer(auth))
      ..registerLazySingleton(() => GetTopUpMethods(topUp))
      ..registerFactory(() => WalletEntriesCubit(getEntries: GetWalletEntries(wallet)))
      ..registerLazySingleton(() => WalletBalanceCubit(getBalance: GetWalletBalance(wallet)));

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
          home: WalletPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final sixMethods = [
    _method(103),
    _method(104),
    _method(105, flow: 'link'),
    _method(102),
    _method(108),
    _method(106),
    _method(123, flow: 'qr'),
  ];

  testWidgets('the card carries the balance, the name and the code', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true);

    // Assert
    expect(find.text('60'), findsOneWidget);
    expect(find.text('علي'), findsOneWidget);
    expect(find.text('C-102'), findsOneWidget);
  });

  testWidgets('the card says nothing beyond its numbers', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(find.text('تُشحن ولا يُسحب منها، وتُدفع منها طلبياتك'), findsNothing);
  });

  testWidgets('«شحن المحفظة» shows the logo of every method it pays with', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true, methods: sixMethods);

    // Assert — the six it offers, and not the QR one it cannot.
    final button = find.widgetWithText(AppCard, 'شحن المحفظة');
    expect(button, findsOneWidget);
    for (final logo in ['onepay', 'masrifipay', 'yussorpay', 'mobicash', 'saharapay', 'edfali']) {
      expect(find.descendant(of: button, matching: _logo('assets/payment/$logo.png')), findsOneWidget);
    }
    expect(find.descendant(of: button, matching: find.textContaining('+')), findsNothing);
  });

  testWidgets('a method this version has no logo for is counted, not drawn blank', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true, methods: [_method(103), _method(199)]);

    // Assert
    final button = find.widgetWithText(AppCard, 'شحن المحفظة');
    expect(find.descendant(of: button, matching: _logo('assets/payment/onepay.png')), findsOneWidget);
    expect(find.descendant(of: button, matching: find.text('+1')), findsOneWidget);
  });

  testWidgets('with online top-ups off there is no button that would not work', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false, methods: sixMethods);

    // Assert
    expect(find.widgetWithText(AppCard, 'شحن المحفظة'), findsNothing);
  });

  testWidgets('each movement is one row: what it was, how or which order, and the signed amount', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(find.text('دفع طلبية'), findsOneWidget);
    expect(find.text('1286 · 9:15 ص'), findsOneWidget);
    expect(find.text('−40'), findsOneWidget);
    expect(find.text('ون باي · 8:00 ص'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('وارد'), findsNothing);
    expect(find.textContaining('نوع العملية'), findsNothing);
  });

  testWidgets('an online top-up wears its method’s logo', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(_logo('assets/payment/onepay.png'), findsOneWidget);
  });

  testWidgets('the movements sit under the day they happened', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('أمس'), findsOneWidget);
  });

  testWidgets('a cancelled movement says so and strikes its amount through', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: false);

    // Assert
    expect(find.text('أُلغيت'), findsOneWidget);
    final amount = tester.widget<Text>(find.text('+50'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
  });

  /// الرصيد الذي وصل مع الصفحة هو ما ترسمه حبّة الشريط العلوي بعد الرجوع — بلا سؤالٍ ثانٍ.
  testWidgets('the balance the page learned reaches the bar', (tester) async {
    // Arrange & Act
    await open(tester, topUpEnabled: true);

    // Assert
    expect(sl<WalletBalanceCubit>().state, '60.00');
  });
}
