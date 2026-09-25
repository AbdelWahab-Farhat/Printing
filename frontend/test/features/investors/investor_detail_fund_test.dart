import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
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

/// صفحةُ المستثمر في «أ · لمحة واحدة» — الاتجاهُ الذي اختاره المالك 2026-09-25.
///
/// رأسُ ماله كلُّه في البطاقة الكبيرة وأين هو تحته، وربحُه وبوّاباتُه الثلاث معاً، ثم فتراتُه —
/// كلُّ رقمٍ ظاهرٌ بلا لمسة.
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
    String walletCapital = '0.00',
    String walletProfit = '0.00',
    String? phone,
  }) {
    return Investor(
      id: 7,
      code: 'I7',
      name: 'أحمد',
      phone: phone,
      balances: InvestorBalances(
        wallet: WalletPots(capital: walletCapital, profit: walletProfit),
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

  /// ما في بطاقةٍ عنوانُها [label].
  Finder inCard(String label, String text) => find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(InvestorMoneyTile)),
    matching: find.text(text),
  );

  Finder inCapital(String text) => inCard('رأس المال', text);
  Finder inProfit(String text) => inCard('الأرباح', text);

  const oneDeposit = FundShare(
    capital: '3000.00',
    units: '3000.000000',
    unitPrice: '1.000000',
    value: '3000.00',
    sharePercent: '100.000000',
    deposits: [
      FundDeposit(units: '3000.000000', amount: '3000.00', lockedUntil: '2027-09-01'),
    ],
  );

  const threeGates = ProfitFigures(
    awaitingDelivery: '100.00',
    pending: '200.00',
    available: '0.00',
  );

  testWidgets('the big card is all his capital, the wallet and the fund side by side under it', (
    tester,
  ) async {
    // Arrange — «رصيد المحفظة 0» كان أكبرَ ما في الصفحة لرجلٍ مالُه كلُّه في الصندوق.
    final shown = investor(walletCapital: '500.00', fund: oneDeposit);

    // Act
    await open(tester, shown);

    // Assert
    expect(inCapital('3,500 د.ل'), findsOneWidget);
    expect(inCapital('في المحفظة'), findsOneWidget);
    expect(inCapital('500 د.ل'), findsOneWidget);
    expect(inCapital('في الصندوق'), findsOneWidget);
    expect(inCapital('3,000 د.ل'), findsOneWidget);
    expect(find.text('رصيد المحفظة'), findsNothing);
  });

  testWidgets('a single deposit says when it unlocks under the fund figure, once', (
    tester,
  ) async {
    // Arrange — دفعةٌ وحيدة مبلغُها رقمُ الصندوق نفسُه: موعدُ فكّها وحده.
    final shown = investor(walletCapital: '500.00', fund: oneDeposit);

    // Act
    await open(tester, shown);

    // Assert
    expect(inCapital('إلى 1 سبتمبر 2027'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('رأس المال'), matching: find.byType(InvestorMoneyTile)),
        matching: find.byIcon(AppIcons.locked),
      ),
      findsOneWidget,
    );
    expect(inCapital('3,000 د.ل'), findsOneWidget);
  });

  testWidgets('several deposits are listed, each with its own lock', (tester) async {
    // Arrange — 3,000 على دفعتين: 2,000 محبوسة إلى سبتمبر القادم، و1,000 انقضى حبسها.
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '37.500000',
      deposits: [
        FundDeposit(units: '2000.000000', amount: '2000.00', lockedUntil: '2027-09-01'),
        FundDeposit(
          units: '1000.000000',
          amount: '1000.00',
          lockedUntil: '2026-09-15',
          isLocked: false,
        ),
      ],
    );

    // Act
    await open(tester, investor(walletCapital: '500.00', fund: fund));

    // Assert
    expect(inCapital('2,000 د.ل'), findsOneWidget);
    expect(inCapital('محبوسة إلى 1 سبتمبر 2027'), findsOneWidget);
    expect(inCapital('1,000 د.ل'), findsOneWidget);
    expect(inCapital('متاحة للاسترداد'), findsOneWidget);
  });

  testWidgets('the fund carries no line about his share', (tester) async {
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
    final shareLine = find.textContaining('نصيبه من ربح').evaluate().length;
    await open(tester, investor(fund: fresh));
    final freshLine = find.text('نصيبه يبدأ من الفترة القادمة').evaluate().length;

    // Assert
    expect(shareLine, 0);
    expect(freshLine, 0);
  });

  testWidgets('without a fund figure the big card is his wallet alone', (tester) async {
    // Arrange — ردٌّ من خادمٍ لا يرسل `fund`: لا قسمةَ تُقال.
    final shown = investor(walletCapital: '500.00');

    // Act
    await open(tester, shown);

    // Assert
    expect(inCapital('500 د.ل'), findsOneWidget);
    expect(find.text('في المحفظة'), findsNothing);
    expect(find.text('في الصندوق'), findsNothing);
  });

  testWidgets('his profit and its three gates show at once, with nothing to tap', (tester) async {
    // Arrange — «كم يستطيع أن يسحب؟» سؤالٌ يُسأل على الهاتف، وكان جوابُه خلف زرّ.
    final shown = investor(
      fund: oneDeposit,
      walletProfit: '50.00',
    ).copyWith(profitFigures: threeGates);

    // Act
    await open(tester, shown);

    // Assert
    expect(inProfit('350 د.ل'), findsOneWidget);
    expect(inProfit('قيد التسليم'), findsOneWidget);
    expect(inProfit('100 د.ل'), findsOneWidget);
    expect(inProfit('معلّقة'), findsOneWidget);
    expect(inProfit('200 د.ل'), findsOneWidget);
    expect(inProfit('متاحة للسحب'), findsOneWidget);
    expect(inProfit('50 د.ل'), findsOneWidget);
    expect(find.byType(FilterOptionChip), findsNothing);
    expect(find.byWidgetPredicate((widget) => widget is SegmentedButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('without the three figures the profit card says what can be withdrawn', (
    tester,
  ) async {
    // Arrange — خادمٌ لا يرسل `profit_figures`: ما يُسحب وحده، كما كانت الصفحة قبل الصندوق.
    final shown = investor(walletProfit: '75.00');

    // Act
    await open(tester, shown);

    // Assert
    expect(inCard('أرباح متاحة للسحب', '75 د.ل'), findsOneWidget);
  });

  testWidgets('the capital and the profit carry no explanation under their numbers', (
    tester,
  ) async {
    // Arrange — «الاسمُ فوق الرقم يكفيه»: سطرُ الشرح تحته رُفض على هذه الصفحة.
    final shown = investor(fund: oneDeposit).copyWith(profitFigures: threeGates);

    // Act
    await open(tester, shown);

    // Assert
    expect(find.text('رأس المال'), findsOneWidget);
    expect(find.text('متاح للتمويل أو للسحب'), findsNothing);
    expect(find.text('الأرباح'), findsOneWidget);
    expect(find.text('ما لم يُسحب بعد'), findsNothing);
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

  testWidgets('a period row says its dates and whether it is still open', (tester) async {
    // Arrange — «سواء منتهية أو مستمرة»: الصفُّ يقول أيَّهما.
    const periods = [
      InvestorPeriod(
        id: 2,
        code: 'P2',
        profit: '120.00',
        startsOn: '2026-10-01',
        endsOn: '2026-10-31',
        status: 'open',
        statusLabel: 'مفتوحة',
      ),
      InvestorPeriod(
        id: 1,
        code: 'P1',
        profit: '1200.23',
        startsOn: '2026-09-23',
        endsOn: '2026-09-30',
        status: 'closed',
        statusLabel: 'مغلقة',
      ),
    ];

    // Act
    await open(tester, investor(periods: periods));

    // Assert
    expect(find.text('1 – 31 أكتوبر 2026'), findsOneWidget);
    expect(find.text('مفتوحة'), findsOneWidget);
    expect(find.text('23 – 30 سبتمبر 2026'), findsOneWidget);
    expect(find.text('مغلقة'), findsOneWidget);
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
        {
          'id': 4,
          'code': 'P2',
          'profit': '120.00',
          'starts_on': '2026-10-01',
          'ends_on': '2026-10-31',
          'status': 'open',
          'status_label': 'مفتوحة',
        },
        {'id': 1, 'code': 'P1', 'profit': '1200.23'},
      ],
    };

    // Act
    final read = Investor.fromJson(json);

    // Assert — وصفُّ خادمٍ أقدم بلا تواريخ يُقرأ كما هو.
    expect(read.periods, const [
      InvestorPeriod(
        id: 4,
        code: 'P2',
        profit: '120.00',
        startsOn: '2026-10-01',
        endsOn: '2026-10-31',
        status: 'open',
        statusLabel: 'مفتوحة',
      ),
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

  testWidgets('his money reads first: capital, then profit, then his periods', (tester) async {
    // Arrange
    final shown = investor(
      fund: oneDeposit,
      periods: const [InvestorPeriod(id: 1, code: 'P1', profit: '0.00')],
    ).copyWith(profitFigures: threeGates);

    // Act
    await open(tester, shown);
    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    // Assert
    expect(top('رأس المال'), lessThan(top('الأرباح')));
    expect(top('الأرباح'), lessThan(top('P1')));
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

  testWidgets('no decorative disc beside the figures', (tester) async {
    // Arrange — «⊕» بجانب «في الصندوق» كان يُقرأ زرّاً لا يفعل شيئاً.
    final shown = investor(
      fund: oneDeposit,
      periods: const [InvestorPeriod(id: 1, code: 'P1', profit: '0.00')],
    ).copyWith(profitFigures: threeGates);

    // Act
    await open(tester, shown);

    // Assert
    expect(find.byIcon(AppIcons.fundDeposit), findsNothing);
    expect(find.byIcon(AppIcons.report), findsNothing);
    expect(find.byIcon(AppIcons.investorDeals), findsNothing);
  });
}
