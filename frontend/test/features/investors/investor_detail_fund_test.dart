import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/investors/models/fund_share.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetInvestor extends Mock implements GetInvestor {}

class _MockRecordWalletEntry extends Mock implements RecordWalletEntry {}

/// كلُّ ماله على صفحته — والصندوقُ منه.
///
/// كانت الصفحةُ تقول «رصيد المحفظة 0» و«لا مال له في أي صفقة» لرجلٍ مالُه كلُّه في الصندوق،
/// لأن الصندوقَ محذوفٌ من الصفقات عمداً ولم يُقَل في مكانٍ آخر.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  late _MockGetInvestor getInvestor;

  setUp(() async {
    await sl.reset();
    getInvestor = _MockGetInvestor();
    sl
      ..registerSingleton<Session>(Session())
      ..registerFactory<InvestorDetailCubit>(
        () => InvestorDetailCubit(
          getInvestor: getInvestor,
          recordWalletEntry: _MockRecordWalletEntry(),
        ),
      );
  });

  tearDown(() async => sl.reset());

  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InvestorDetailPage(investorId: 7),
        ),
      ),
    );
  }

  /// الصفحةُ داخل موجّه — لما يُفتح منها. بابُ الفترة يكتب مسارَه وما حمله في [opened] ويقف.
  Widget routedHost(void Function(String path, Object? extra) opened) {
    final router = GoRouter(
      initialLocation: '/investors/7',
      routes: [
        GoRoute(
          path: '/investors/7',
          builder: (context, state) => const InvestorDetailPage(investorId: 7),
        ),
        GoRoute(
          path: '/investment/periods/:id',
          builder: (context, state) {
            opened(state.uri.path, state.extra);

            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        routerConfig: router,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
  }

  Investor investor({
    FundShare? fund,
    List<DealPots> deals = const <DealPots>[],
    List<InvestorPeriod> periods = const <InvestorPeriod>[],
    String? phone,
  }) {
    return Investor(
      id: 7,
      code: 'I7',
      name: 'أحمد',
      phone: phone,
      balances: InvestorBalances(
        wallet: const WalletPots(capital: '0.00', profit: '0.00'),
        deals: deals,
      ),
      fund: fund,
      periods: periods,
    );
  }

  Future<void> open(WidgetTester tester, Investor shown, {Widget? within}) async {
    when(() => getInvestor(7)).thenAnswer((_) async => Right(shown));

    // طويلةٌ بما يكفي لبطاقاتها كلّها — القائمةُ تبني ما يظهر منها وحده.
    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(within ?? host());
    await tester.pumpAndSettle();
  }

  Finder inFund(String text) => find.descendant(
    of: find.ancestor(of: find.text('في الصندوق'), matching: find.byType(InvestorMoneyTile)),
    matching: find.text(text),
  );

  testWidgets('reads what he put in the fund and each deposit with its lock', (tester) async {
    // Arrange — 3,000 في الصندوق على دفعتين: 2,000 محبوسة إلى سبتمبر القادم، و1,000 انقضى حبسها.
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '37.500000',
      period: FundPeriodBrief(code: 'P2', startsOn: '2026-10-01', endsOn: '2026-10-31'),
      deposits: [
        FundDeposit(
          units: '2000.000000',
          amount: '2000.00',
          lockedUntil: '2027-09-01',
        ),
        FundDeposit(
          units: '1000.000000',
          amount: '1000.00',
          lockedUntil: '2026-09-15',
          isLocked: false,
        ),
      ],
    );

    // Act
    await open(tester, investor(fund: fund));

    // Assert
    expect(inFund('3,000 د.ل'), findsOneWidget);
    expect(inFund('2,000 د.ل'), findsOneWidget);
    expect(inFund('محبوسة إلى 1 سبتمبر 2027'), findsOneWidget);
    expect(inFund('1,000 د.ل'), findsOneWidget);
    expect(inFund('متاحة للاسترداد'), findsOneWidget);
  });

  testWidgets('the fund carries no line under its number', (tester) async {
    // Arrange — «نصيبه من ربح P2» و«نصيبه يبدأ من الفترة القادمة» رُفضا كلامًا لا حاجة له.
    const share = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '37.500000',
      period: FundPeriodBrief(code: 'P2', startsOn: '2026-10-01', endsOn: '2026-10-31'),
    );
    final fresh = share.copyWith(sharePercent: '0.000000', shareStartsNextPeriod: true);

    // Act
    await open(tester, investor(fund: share));
    final shareLine = inFund('نصيبه من ربح P2: 37.50%').evaluate().length;
    await open(tester, investor(fund: fresh));
    final freshLine = inFund('نصيبه يبدأ من الفترة القادمة').evaluate().length;

    // Assert
    expect(shareLine, 0);
    expect(freshLine, 0);
  });

  testWidgets('no deal is listed, even one still holding his money', (tester) async {
    // Arrange — قرارُ المالك 2026-09-25: «اخفي صفقات سوف تغلق وتضاف لربحه ومالناش علاقة بيها».
    const deals = [
      DealPots(investorDealId: 1, capital: '378.44', profit: '0.00'),
      DealPots(investorDealId: 3, capital: '0.00', profit: '0.00'),
    ];

    // Act
    await open(tester, investor(deals: deals));

    // Assert
    expect(find.text('في الصفقات'), findsNothing);
    expect(find.text('صفقة #1'), findsNothing);
    expect(find.text('378.44 د.ل'), findsNothing);
  });

  testWidgets('lists each period he shared with his profit in it', (tester) async {
    // Arrange — الأحدثُ أوّلاً كما يرسلها الخادم، وفترةٌ خسر فيها تقول سالبَها.
    const periods = [
      InvestorPeriod(id: 3, code: 'P3', profit: '-80.00'),
      InvestorPeriod(id: 2, code: 'P2', profit: '120.00'),
      InvestorPeriod(id: 1, code: 'P1', profit: '1200.23'),
    ];

    // Act
    await open(tester, investor(periods: periods));
    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    // Assert
    expect(find.text('الفترات'), findsOneWidget);
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('1,200.23 د.ل'), findsOneWidget);
    expect(find.text('120 د.ل'), findsOneWidget);
    expect(find.text('-80 د.ل'), findsOneWidget);
    expect(top('P3'), lessThan(top('P2')));
    expect(top('P2'), lessThan(top('P1')));
  });

  testWidgets('a period opens its own screen', (tester) async {
    // Arrange — «من أين جاء الربح؟» سؤالٌ عن الفترة: شاشتُها تقوله طلبيةً طلبية.
    const periods = [InvestorPeriod(id: 4, code: 'P1', profit: '1200.23')];
    String? path;
    Object? extra;
    await open(
      tester,
      investor(periods: periods),
      within: routedHost((opened, carried) {
        path = opened;
        extra = carried;
      }),
    );

    // Act
    await tester.tap(find.text('P1'));
    await tester.pumpAndSettle();

    // Assert — ورمزُها معها، فيقوله الشريطُ ريثما تصل.
    expect(path, '/investment/periods/4');
    expect(extra, 'P1');
  });

  test('his periods arrive from the server with the page', () {
    // Arrange — كما يرسلها `GET /investors/{id}`، الأحدثُ أوّلاً.
    final json = <String, dynamic>{
      'id': 7,
      'code': 'I7',
      'name': 'أحمد',
      'periods': [
        {'id': 4, 'code': 'P2', 'profit': '120.00'},
        {'id': 1, 'code': 'P1', 'profit': '1200.23'},
      ],
    };

    // Act
    final read = Investor.fromJson(json);

    // Assert
    expect(read.periods, const [
      InvestorPeriod(id: 4, code: 'P2', profit: '120.00'),
      InvestorPeriod(id: 1, code: 'P1', profit: '1200.23'),
    ]);
  });

  testWidgets('no periods heading when he has shared none', (tester) async {
    // Arrange — مالُه في المحفظة وحدها، ولم يدخل فترةً بعد.

    // Act
    await open(tester, investor());

    // Assert — لا عنوانَ فوق فراغ.
    expect(find.text('الفترات'), findsNothing);
  });

  testWidgets('the wallet and the profit carry no explanation under their numbers', (
    tester,
  ) async {
    // Arrange — «الاسمُ فوق الرقم يكفيه»: سطرُ الشرح تحته رُفض على هذه الصفحة.
    final shown = investor().copyWith(
      profitFigures: const ProfitFigures(
        awaitingDelivery: '0.00',
        pending: '0.00',
        available: '0.00',
      ),
    );

    // Act
    await open(tester, shown);

    // Assert
    expect(find.text('رصيد المحفظة'), findsOneWidget);
    expect(find.text('متاح للتمويل أو للسحب'), findsNothing);
    expect(find.text('إجمالي الأرباح'), findsOneWidget);
    expect(find.text('ما لم يُسحب بعد'), findsNothing);
  });

  testWidgets('the top is his name in the bar and nothing else', (tester) async {
    // Arrange — الهاتفُ والرمزُ فوق المحفظة رُفضا: «مش ضروري».
    final shown = investor(phone: '0910055438');

    // Act
    await open(tester, shown);

    // Assert
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('0910055438'), findsNothing);
    expect(find.text('I7'), findsNothing);
    expect(find.byIcon(AppIcons.person), findsNothing);
  });

  testWidgets('a stopped investor still says so', (tester) async {
    // Arrange
    final shown = investor().copyWith(isActive: false);

    // Act
    await open(tester, shown);

    // Assert
    expect(find.text('موقوف'), findsOneWidget);
  });

  testWidgets('a single deposit does not repeat the fund figure', (tester) async {
    // Arrange — دفعةٌ واحدة هي كلُّ ما في الصندوق: مبلغُها هو الرقمُ الكبير نفسُه.
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '100.000000',
      deposits: [
        FundDeposit(units: '3000.000000', amount: '3000.00', lockedUntil: '2027-09-01'),
      ],
    );

    // Act
    await open(tester, investor(fund: fund));

    // Assert
    expect(inFund('3,000 د.ل'), findsOneWidget);
    expect(inFund('محبوسة إلى 1 سبتمبر 2027'), findsOneWidget);
  });

  testWidgets('his money reads before his profit: wallet, fund, periods, then profit', (
    tester,
  ) async {
    // Arrange
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '100.000000',
    );
    final shown = investor(
      fund: fund,
      periods: const [InvestorPeriod(id: 1, code: 'P1', profit: '0.00')],
    ).copyWith(
      profitFigures: const ProfitFigures(
        awaitingDelivery: '0.00',
        pending: '0.00',
        available: '0.00',
      ),
    );

    // Act
    await open(tester, shown);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    // Assert — الفتراتُ في مكان الصفقات: «عرض الفترات بدلا من الصفقات».
    expect(top('رصيد المحفظة'), lessThan(top('في الصندوق')));
    expect(top('في الصندوق'), lessThan(top('P1')));
    expect(top('P1'), lessThan(top('إجمالي الأرباح')));
  });

  testWidgets('no decorative disc beside the figures', (tester) async {
    // Arrange — «⊕» بجانب «في الصندوق» كان يُقرأ زرّاً لا يفعل شيئاً.
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '100.000000',
    );
    final shown = investor(
      fund: fund,
      periods: const [InvestorPeriod(id: 1, code: 'P1', profit: '0.00')],
    ).copyWith(
      profitFigures: const ProfitFigures(
        awaitingDelivery: '0.00',
        pending: '0.00',
        available: '0.00',
      ),
    );

    // Act
    await open(tester, shown);

    // Assert
    expect(find.byIcon(AppIcons.fundDeposit), findsNothing);
    expect(find.byIcon(AppIcons.report), findsNothing);
    expect(find.byIcon(AppIcons.investorDeals), findsNothing);
  });
}
