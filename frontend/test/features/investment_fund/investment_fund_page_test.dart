import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_fund_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// لوحةُ الصندوق.
///
/// **ما يُثبَّت هنا أن اللوحة لا تجمع ولا تطرح.** القيمةُ ببنودها تصل من الخادم وتُعرض كما هي —
/// وعميلٌ يعيد حسابها يصير تنفيذاً ثانياً للقواعد: ذاك الذي يخالفها يوم تتغيّر.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements InvestmentFundRepository {
  _FakeRepository(this.held);

  final FundStanding held;
  int opened = 0;
  int closed = 0;
  String? closedWith;

  /// ما يعود به الإقفالُ حين ينجح — `null` يُبقي الرفضَ الذي تقوم عليه بقيّةُ الاختبارات.
  FundPeriod? closesInto;

  @override
  Future<Either<Failure, FundStanding>> standing() async => Right(held);

  @override
  Future<Either<Failure, FundPeriod>> openPeriod() async {
    opened++;

    return const Left(Failure.server(message: 'لم يُبنَ بعد'));
  }

  @override
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason}) async {
    closedWith = overrideReason;
    closed++;

    if (closesInto case final period?) return Right(period);

    return const Left(Failure.server(message: 'فيها طلبيات لم تصل العملاء بعد'));
  }

  // الأبوابُ الجديدة — لا تُستدعى في هذه الاختبارات، وتُنفَّذ لأن العقد يطلبها.
  @override
  Future<Either<Failure, List<FundPeriod>>> periods() async => const Right(<FundPeriod>[]);

  @override
  Future<Either<Failure, PeriodOrders>> periodOrders(int periodId) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, DepositReceipt>> deposit({
    required int investorId,
    required String amount,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> withdraw({
    required int investorId,
    required String amount,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> buyPurchaseOrder({
    required int purchaseOrderId,
    required List<int> stockItemIds,
    Map<int, String> printingSalePrices = const {},
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));
}

const _valuation = FundValuation(
  cash: '12000.00',
  stockOnShelf: '14000.00',
  goodsInFlight: '3000.00',
  receivablesAtCost: '0.00',
  profitOwed: '3000.00',
  total: '26000.00',
);

void main() {
  Future<_FakeRepository> register(FundStanding standing) async {
    await sl.reset();
    final repository = _FakeRepository(standing);
    sl
      // `PermissionGate` تقرأ الجلسة؛ جلسةٌ بلا صلاحيات تُخفي الزرَّ ولا تُسقط الشاشة.
      ..registerSingleton<Session>(Session())
      ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(repository))
      ..registerLazySingleton<OpenFundPeriod>(() => OpenFundPeriod(repository))
      ..registerLazySingleton<CloseFundPeriod>(() => CloseFundPeriod(repository))
      ..registerLazySingleton<GetFundPeriods>(() => GetFundPeriods(repository))
      ..registerLazySingleton<DepositCapital>(() => DepositCapital(repository))
      ..registerLazySingleton<WithdrawCapital>(() => WithdrawCapital(repository))
      ..registerLazySingleton<RecordFundExpense>(() => RecordFundExpense(repository));

    return repository;
  }

  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InvestmentFundPage(),
        ),
      ),
    );
  }

  /// اللوحةُ داخل موجّه — لما يُفتح منها. كلُّ بابٍ يكتب مسارَه في [pushed] ويقف.
  Widget routedHost(void Function(String path) pushed) {
    final router = GoRouter(
      initialLocation: '/investment',
      routes: [
        GoRoute(path: '/investment', builder: (context, state) => const InvestmentFundPage()),
        for (final path in const [
          '/investment/cash',
          '/investment/shelf',
          '/investment/in-flight',
          '/investment/receivables',
          '/investment/profit-owed',
        ])
          GoRoute(
            path: path,
            builder: (context, state) {
              pushed(state.uri.path);

              return const Scaffold(body: SizedBox.shrink());
            },
          ),
      ],
    );

    return ScreenUtilInit(
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
    );
  }

  // **كلُّ رقمٍ في اللوحة بابٌ إلى ما صنعه** — طلبُ المالك 2026-09-24: النقدُ إلى سجلّه،
  // والبضاعةُ إلى موادّها وطلبياتها، والأرباحُ إلى ما أعطاها.
  for (final (label, path) in const [
    ('نقد في الخزينة', '/investment/cash'),
    ('بضاعة على الرفّ', '/investment/shelf'),
    ('بضاعة خرجت ولم تُسلَّم', '/investment/in-flight'),
    ('سُلِّمت ولم تُحصَّل', '/investment/receivables'),
    ('أرباح مستحقّة للمستثمرين', '/investment/profit-owed'),
  ]) {
    testWidgets('«$label» opens what it is made of', (tester) async {
      // Arrange
      await register(const FundStanding(valuation: _valuation));
      String? opened;
      await tester.pumpWidget(routedHost((path) => opened = path));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      // Assert
      expect(opened, path);
    });
  }

  testWidgets('the cash log also sits beside the fund value', (tester) async {
    // Arrange — «ممكن تكون بجانب قيمة الصندوق».
    await register(const FundStanding(valuation: _valuation));
    String? opened;
    await tester.pumpWidget(routedHost((path) => opened = path));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('سجل الخزينة'));
    await tester.pumpAndSettle();

    // Assert
    expect(opened, '/investment/cash');
  });

  testWidgets('the total is shown above its parts, never instead of them', (tester) async {
    // Arrange — بندٌ مخفيٌّ في هذا الرقم مالُ مستثمر.
    await register(const FundStanding(valuation: _valuation));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    // أصفارُ الحشو مقصوصة — قرارُ عرضٍ يُتَّخذ مرّةً في `GroupedNumberText.grouped` لا في كل شاشة.
    expect(find.text('26,000 د.ل'), findsOneWidget);
    expect(find.text('12,000 د.ل'), findsOneWidget);
    expect(find.text('14,000 د.ل'), findsOneWidget);
    expect(find.text('بضاعة خرجت ولم تُسلَّم'), findsOneWidget);
  });

  testWidgets('every figure is drawn positive, the label carrying what it means', (tester) async {
    // Arrange — الأرباحُ المستحقّة دَينٌ يُطرح من المجموع، وكانت تُرسم بسالبٍ أحمر لذلك.
    // قرارُ المالك: «مش ضروري» — والمجموعُ يُحسب في الخادم، فلا عمودَ يجمعه أحدٌ بيده.
    await register(const FundStanding(valuation: _valuation));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — اثنان بالرقم نفسه: «بضاعة خرجت» و«أرباح مستحقّة». يفرّقهما العنوانُ وحده الآن،
    // وهو المقصود.
    expect(find.text('3,000 د.ل'), findsNWidgets(2));
    expect(find.text('−3,000 د.ل'), findsNothing);
    expect(find.text('أرباح مستحقّة للمستثمرين'), findsOneWidget);
  });

  testWidgets('a fund with no period says so and offers to open one', (tester) async {
    // Arrange — لا تُخترع فترةٌ وهمية لتملأ الفراغ.
    await register(const FundStanding(valuation: _valuation));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا توجد فترة مفتوحة'), findsOneWidget);
  });

  testWidgets('a running period shows its window and how long it has been due', (tester) async {
    // Arrange — §٠.٤: الجدولةُ تُقفلها في ساعتها الأولى، فبقاؤها مستحقّةً ثلاثةَ أيام يعني أنها
    // صمتت. واللوحةُ تقولها رقماً بدل أن يمرّ الصمت.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 1,
          code: 'P1',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-01',
          endsOn: '2026-09-30',
          subscriptionClosesOn: '2026-09-07',
          isDueToClose: true,
          overdueDays: 3,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '14000.00',
          openingCash: '12000.00',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الفترة P1 — مفتوحة'), findsOneWidget);
    expect(find.text('2026-09-01 ← 2026-09-30'), findsOneWidget);
    expect(find.text('الاكتتاب مفتوح حتى 2026-09-07'), findsOneWidget);
    expect(find.text('مستحقّة الإقفال منذ 3 أيام'), findsOneWidget);
    expect(find.text('لا توجد فترة مفتوحة'), findsNothing);
  });

  testWidgets('a period waiting for its orders stays on the dashboard, counting them', (
    tester,
  ) async {
    // Arrange — §١٢هـ: «تبقى بلا حدّ، واللوحةُ تصرخ». سبتمبر أُقفل في موعده وبقيت له طلبيتان،
    // وأكتوبر يجري فوقه.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 2,
          code: 'P2',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-10-01',
          endsOn: '2026-10-31',
          subscriptionClosesOn: '2026-10-07',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '0.00',
          openingCash: '0.00',
        ),
        waitingPeriods: [
          FundPeriod(
            id: 1,
            code: 'P1',
            status: 'closing',
            statusLabel: 'قيد الإغلاق',
            startsOn: '2026-09-22',
            endsOn: '2026-09-30',
            subscriptionClosesOn: '2026-09-30',
            isDueToClose: false,
            owedOrders: 2,
            periodMonths: 1,
            investorProfitSharePercent: '50.00',
            openingStockCost: '0.00',
            openingCash: '0.00',
          ),
        ],
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('تنتظر طلبيتين'), 200);

    // Assert — بابٌ يُفتح على الفترة، ويقول كم طلبيةً تحبسها.
    final card = find.ancestor(
      of: find.text('الفترة P1 — قيد الإغلاق'),
      matching: find.byType(InkWell),
    );

    expect(card, findsOneWidget);
    expect(tester.widget<InkWell>(card).onTap, isNotNull);
    expect(find.text('تنتظر طلبيتين'), findsOneWidget);
    expect(find.text('الفترة P2 — مفتوحة'), findsOneWidget);
  });

  testWidgets('a refusal to close is shown in the server words', (tester) async {
    // Arrange — طلبيةٌ عالقة تحبس الفترة، والخادمُ يسمّيها. الشاشةُ تنقل ولا تُعيد صياغة.
    final repository = await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 1,
          code: 'P1',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-01',
          endsOn: '2026-09-30',
          subscriptionClosesOn: '2026-09-07',
          isDueToClose: true,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '14000.00',
          openingCash: '12000.00',
        ),
      ),
    );
    sl<Session>().adopt(
      const AuthUser(id: 1, name: 'مدير', phone: '0910000000', permissions: ['investors.manage']),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — اللوحةُ صارت أطولَ من الشاشة بعد الوحدات والشركاء والأزرار، فالزرُّ يُمرَّر إليه
    // بدل أن يُنقَر في مكانٍ خارج الإطار.
    await tester.scrollUntilVisible(find.text('إقفال الفترة'), 200);
    await tester.pumpAndSettle();

    await tester.tap(find.text('إقفال الفترة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Assert — **ولا سببَ تجاوزٍ يُرسَل من الزرّ**: التجاوزُ قرارٌ يُكتب لا ضغطةٌ تمرّ.
    expect(repository.closed, 1);
    expect(repository.closedWith, isNull);
    expect(find.text('فيها طلبيات لم تصل العملاء بعد'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
  testWidgets('a close that leaves the period waiting says so, not that it closed', (tester) async {
    // Arrange — §٠.٧: الفترةُ تنتهي في موعدها ولو بقيت لها طلبية. «أُقفلت وأُفرج عن الأرباح»
    // كذبٌ هنا: ربحُ ما لم يصل أو لم يُحصَّل لم يُفرَج عنه.
    const due = FundPeriod(
      id: 1,
      code: 'P1',
      status: 'open',
      statusLabel: 'مفتوحة',
      startsOn: '2026-09-22',
      endsOn: '2026-09-30',
      subscriptionClosesOn: '2026-09-30',
      isDueToClose: true,
      overdueDays: 0,
      periodMonths: 1,
      investorProfitSharePercent: '50.00',
      openingStockCost: '0.00',
      openingCash: '0.00',
    );
    final repository = await register(const FundStanding(valuation: _valuation, period: due));
    repository.closesInto = due.copyWith(
      status: 'closing',
      statusLabel: 'قيد الإغلاق',
      isDueToClose: false,
      owedOrders: 2,
    );
    sl<Session>().adopt(
      const AuthUser(id: 1, name: 'مدير', phone: '0910000000', permissions: ['investors.manage']),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('إقفال الفترة'), 200);
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إقفال الفترة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Assert
    expect(find.text('انتهت الفترة P1 — قيد الإغلاق، تنتظر طلبيتين'), findsOneWidget);
    expect(find.textContaining('أُفرج عن الأرباح'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the unit price is on the dashboard, and subscribing rides the floating button', (
    tester,
  ) async {
    // Arrange — سعرُ الوحدة هو ما يشتري به الداخلُ الجديد، فمن يقبض مالاً اليوم يحتاج أن يراه
    // قبل أن يكتب. والاشتراكُ نفسُه في الزرّ العائم — قرارُ المالك 2026-09-23 — لا في ذيل
    // اللوحة؛ والشركاءُ ونسبُهم خلف «المستثمرون الحاليون» لا على اللوحة.
    await register(
      const FundStanding(
        valuation: _valuation,
        unitPrice: '1.600000',
        unitsOutstanding: '2000.000000',
        investors: [
          FundHolder(
            investorId: 1,
            name: 'أحمد',
            units: '1500.000000',
            sharePercent: '75.000000',
            capital: '3000.00',
            profit: '400.00',
          ),
          FundHolder(
            investorId: 2,
            name: 'محمد',
            units: '500.000000',
            sharePercent: '25.000000',
            capital: '1000.00',
            profit: '0.00',
          ),
        ],
        period: FundPeriod(
          id: 1,
          code: 'P1',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-01',
          endsOn: '2026-09-30',
          subscriptionClosesOn: '2026-09-07',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '14000.00',
          openingCash: '12000.00',
          acceptsCapital: true,
        ),
      ),
    );
    sl<Session>().adopt(
      const AuthUser(
        id: 1,
        name: 'مدير',
        phone: '0910000000',
        permissions: ['investors.money.record'],
      ),
    );

    // Act — شاشةٌ طويلة: `ListView` يبني ما يُرى فقط، فما تحت الطيّة غيرُ موجودٍ ليُبحث عنه.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — السعرُ كما وصل، ولا شريكَ على اللوحة، ولا زرَّ اشتراكٍ في جسمها.
    expect(find.text('1.600000'), findsOneWidget);
    expect(find.text('أحمد'), findsNothing);
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('اشتراك في الصندوق')),
      findsNothing,
    );

    // Act — صلاحيةُ المال تُبقي اثنين (الاشتراك والاسترداد)، فهو زرٌّ يتفتّح.
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اشتراك في الصندوق'), findsOneWidget);
    expect(find.text('استرداد رأس مال'), findsOneWidget);
    // «تسجيل مصروف» خلف صلاحيةٍ أخرى لا تحملها هذه الجلسة.
    expect(find.text('تسجيل مصروف'), findsNothing);
  });

  testWidgets('a closed subscription window says so instead of offering a deposit', (tester) async {
    // Arrange — «يمكنه فقط في بداية الفترة». والخادمُ هو من قرّر أنها أُغلقت؛ الشاشةُ تعرض
    // قرارَه ولا تقارن تواريخ.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 1,
          code: 'P1',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-01',
          endsOn: '2026-09-30',
          subscriptionClosesOn: '2026-09-07',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '14000.00',
          openingCash: '12000.00',
        ),
      ),
    );
    sl<Session>().adopt(
      const AuthUser(
        id: 1,
        name: 'مدير',
        phone: '0910000000',
        permissions: ['investors.money.record'],
      ),
    );

    // Act
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — والاستردادُ وحده يبقى، فهو الزرُّ العائم نفسُه باسمه لا زرٌّ يتفتّح عن واحد.
    expect(find.text('اشتراك في الصندوق'), findsNothing);
    expect(
      find.text('أُغلقت نافذة الاكتتاب — يُقبل رأس المال في الفترة التالية'),
      findsOneWidget,
    );
    expect(find.text('استرداد رأس مال'), findsOneWidget);
  });

  testWidgets('the record of the periods has a door on the dashboard', (tester) async {
    // Arrange — اللوحةُ تعرض الفترةَ الجارية وحدها؛ وما صنعته كلُّ فترةٍ سؤالٌ ثانٍ خلف زرّ،
    // لا سجلٌّ يُحشر فوق الرقم الذي فُتحت الشاشةُ لأجله.
    await register(const FundStanding(valuation: _valuation));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — بلا صلاحيةٍ في الجلسة: القراءةُ ليست خلف `manage`، ومن يرى اللوحة يرى سجلَّها.
    expect(find.text('سجل الفترات'), findsOneWidget);
    expect(find.text('المستثمرون الحاليون'), findsOneWidget);
  });

  testWidgets('the investors door sits beside the periods record, on one row', (tester) async {
    // Arrange — قرارُ المالك 2026-09-23: «سجل الفترات يكون بجانبه زر المستثمرين الحاليين».
    await register(const FundStanding(valuation: _valuation));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — على سطرٍ واحد، والسجلُّ على اليمين حيث يبدأ السطرُ العربيّ.
    final periods = tester.getCenter(find.text('سجل الفترات'));
    final investors = tester.getCenter(find.text('المستثمرون الحاليون'));

    expect(periods.dy, investors.dy);
    expect(periods.dx, greaterThan(investors.dx));
  });
  testWidgets('the running period card is a door into the period itself', (tester) async {
    // Arrange — الأرقامُ على البطاقة صحيحةٌ ولا تقول من أين جاءت. وكان الطريقُ الوحيد إلى
    // تفصيلها «سجل الفترات»، فيمرّ من يقرأ الفترةَ الجارية أمامه ولا يعرف أنها تُفتح.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 7,
          code: 'P7',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-20',
          endsOn: '2026-10-19',
          subscriptionClosesOn: '2026-09-26',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '0.00',
          openingCash: '0.00',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — بطاقةٌ تُنقر، وسهمٌ يقول ذلك قبل أن يجرّب أحد.
    final card = find.ancestor(
      of: find.text('الفترة P7 — مفتوحة'),
      matching: find.byType(InkWell),
    );

    expect(card, findsOneWidget);
    expect(tester.widget<InkWell>(card).onTap, isNotNull);
    expect(
      find.descendant(of: card, matching: find.byIcon(AppIcons.forward)),
      findsOneWidget,
    );
  });
  testWidgets('the open window says it feeds the next period, not this one', (tester) async {
    // Arrange — «يقدر يحط فلوسه في الصندوق وتجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له
    // أرباح شهر عشرة». فالسطرُ يقول لمن هذه النافذة قبل أن يضع أحدٌ مالَه فيها.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 2,
          code: 'P2',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-10-01',
          endsOn: '2026-10-31',
          subscriptionClosesOn: '2026-10-07',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '0.00',
          openingCash: '0.00',
          subscriptionServesNextPeriod: true,
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('اكتتاب الفترة القادمة مفتوح حتى 2026-10-07'), findsOneWidget);
    expect(find.text('الاكتتاب مفتوح حتى 2026-10-07'), findsNothing);
  });

  testWidgets('the period window is read from its start, on the right', (tester) async {
    // Arrange — سطرُ المدى كان يُجبَر على الاتجاه اللاتيني، فيقع أوّلُ التاريخين يساراً
    // والسهمُ يشير إليه: فترةٌ تمشي إلى الوراء في عين من يقرأ.
    await register(
      const FundStanding(
        valuation: _valuation,
        period: FundPeriod(
          id: 1,
          code: 'P1',
          status: 'open',
          statusLabel: 'مفتوحة',
          startsOn: '2026-09-01',
          endsOn: '2026-09-30',
          subscriptionClosesOn: '2026-09-07',
          isDueToClose: false,
          periodMonths: 1,
          investorProfitSharePercent: '50.00',
          openingStockCost: '0.00',
          openingCash: '0.00',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — السطرُ يرث اتجاه الصفحة: البدايةُ يميناً، والسهمُ يمشي منها إلى النهاية.
    final window = tester.renderObject<RenderParagraph>(find.text('2026-09-01 ← 2026-09-30'));

    expect(window.textDirection, TextDirection.rtl);
  });
}
