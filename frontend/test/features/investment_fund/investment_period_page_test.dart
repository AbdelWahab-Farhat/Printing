import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/models/fund_purchase_order_option.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_period_page.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_status_chip.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشةُ الفترة الواحدة — «أيُّ طلبيةٍ أعطت المستثمرين ربحاً، وكم أخذ كلُّ واحد».
///
/// **ما يُثبَّت هنا أن الشاشة لا تجمع ولا تقسم.** الأرقامُ صفوفُ دفتر المحافظ كما وصلت، بما
/// فيها المجموع: عميلٌ يعيد جمعها يصير تعريفاً ثانياً للقسمة — ذاك الذي يخالف الخادمَ يوم
/// يُعكَس صفّ.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements InvestmentFundRepository {
  _FakeRepository(this.held, {this.failure});

  final PeriodOrders held;
  final Failure? failure;
  int asked = 0;
  int? askedFor;

  @override
  Future<Either<Failure, PeriodOrders>> periodOrders(int periodId) async {
    asked++;
    askedFor = periodId;

    return failure == null ? Right(held) : Left(failure!);
  }

  // بقيّةُ العقد — لا تُستدعى من هذه الشاشة، وتُنفَّذ لأن الواجهة تطلبها.
  @override
  Future<Either<Failure, FundStanding>> standing() async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, FundPeriod>> openPeriod() async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason}) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, List<FundPeriod>>> periods() async => const Right(<FundPeriod>[]);

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
    int? treasuryAccountId,
    int? purchaseOrderId,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, List<FundPurchaseOrderOption>>> purchaseOrders() async => const Right([]);
}

/// تبويبُ المصاريف — فارغٌ هنا؛ تفصيلُه في `period_expenses_tab_test.dart`.
class _FakeExpenses implements PeriodExpensesRepository {
  @override
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId) async =>
      const Right(PeriodExpenses(period: _period));

  @override
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason}) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Paginated<FundExpense>>> fundExpenses({
    int? periodId,
    required int page,
  }) async => const Left(Failure.server(message: 'لم يُستدعَ'));
}

const _period = FundPeriod(
  id: 7,
  code: 'P7',
  status: 'closed',
  statusLabel: 'مغلقة',
  startsOn: '2026-09-01',
  endsOn: '2026-09-30',
  subscriptionClosesOn: '2026-09-07',
  isDueToClose: true,
  periodMonths: 1,
  investorProfitSharePercent: '50.00',
  openingStockCost: '14000.00',
  openingCash: '12000.00',
  netProfit: '1500.00',
  investorsPool: '750.00',
  companyShare: '750.00',
  salesRevenue: '9000.00',
  closingStockCost: '12000.00',
);

void main() {
  Future<_FakeRepository> register(PeriodOrders held, {Failure? failure}) async {
    await sl.reset();
    final repository = _FakeRepository(held, failure: failure);
    final expenses = _FakeExpenses();
    sl
      ..registerSingleton<Session>(Session())
      ..registerLazySingleton<GetPeriodOrders>(() => GetPeriodOrders(repository))
      ..registerLazySingleton<GetPeriodExpenses>(() => GetPeriodExpenses(expenses))
      ..registerLazySingleton<ReverseFundExpense>(() => ReverseFundExpense(expenses));

    return repository;
  }

  Widget host({PeriodTab opensOn = PeriodTab.orders}) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: InvestmentPeriodPage(periodId: 7, periodCode: 'P7', opensOn: opensOn),
        ),
      ),
    );
  }

  testWidgets('each order says what it gave and to whom', (tester) async {
    // Arrange — نصفُ السؤال «أي طلبية أعطت»، ونصفُه «كم أخذ كل مستثمر». فالصفُّ يحمل الاثنين
    // ولا يُخفي الثاني خلف نقرةٍ ثانية.
    await register(
      const PeriodOrders(
        period: _period,
        orders: [
          PeriodOrder(
            orderId: 91,
            code: 'ORD-0091',
            status: 'delivered',
            statusLabel: 'تم الاستلام',
            customerName: 'مطعم البركة',
            grandTotal: '3000.00',
            investorsTotal: '750.00',
            investors: [
              PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '562.50'),
              PeriodInvestorShare(investorId: 2, name: 'سالم', amount: '187.50'),
            ],
          ),
        ],
        investors: [
          PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '562.50'),
          PeriodInvestorShare(investorId: 2, name: 'سالم', amount: '187.50'),
        ],
        totals: PeriodOrdersTotals(orders: 1, investorsTotal: '750.00'),
      ),
    );

    // Act — الشاشةُ أطولُ من إطار الاختبار الافتراضي بترويستها وسجلّها، فيُوسَّع الإطار بدل
    // أن يُمرَّر إلى كل صفٍّ يُفحص.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الرقمُ بلا «طلبية» قبله، والعميلُ وحالتُها سطرٌ تحته. والاسمان مرّتين: مرّةً في
    // «المستثمرون» بوحدته، ومرّةً سطراً تحت الطلبية — رقمان مختلفان متى تعدّدت الطلبيات.
    expect(find.text('ORD-0091'), findsOneWidget);
    expect(find.text('طلبية ORD-0091'), findsNothing);
    expect(find.textContaining('مطعم البركة'), findsOneWidget);
    expect(find.textContaining('تم الاستلام'), findsOneWidget);
    expect(find.text('562.5 د.ل'), findsOneWidget);
    expect(find.text('187.5 د.ل'), findsOneWidget);
    expect(find.textContaining('562.5'), findsNWidgets(2));
    expect(find.textContaining('187.5'), findsNWidgets(2));
  });

  testWidgets('one partner alone is not repeated under the order', (tester) async {
    // Arrange — سطرُ الشركاء تحت الطلبية يقسم رقمَها؛ وشريكٌ واحد يأخذه كلَّه، فسطرُه تكرار.
    await register(
      const PeriodOrders(
        period: _period,
        orders: [
          PeriodOrder(
            orderId: 91,
            code: 'ORD-0091',
            status: 'delivered',
            statusLabel: 'تم الاستلام',
            grandTotal: '3000.00',
            investorsTotal: '640.00',
            investors: [PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '640.00')],
          ),
        ],
        totals: PeriodOrdersTotals(orders: 1, investorsTotal: '640.00'),
      ),
    );
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — مرّةً في المجموع، ومرّةً على الطلبية.
    expect(find.text('640 د.ل'), findsNWidgets(2));
    expect(find.textContaining('أحمد'), findsNothing);
  });

  testWidgets('the pool is the figure the server sent, over the orders it came from', (
    tester,
  ) async {
    // Arrange — المجموعُ يصل محسوباً؛ جمعُه هنا تعريفٌ ثانٍ يخالف الخادمَ يوم يُعكَس صفّ.
    await register(
      const PeriodOrders(
        period: _period,
        orders: [
          PeriodOrder(
            orderId: 91,
            code: 'ORD-0091',
            status: 'delivered',
            statusLabel: 'تم الاستلام',
            grandTotal: '3000.00',
            investorsTotal: '750.00',
          ),
          PeriodOrder(
            orderId: 92,
            code: 'ORD-0092',
            status: 'delivered',
            statusLabel: 'تم الاستلام',
            grandTotal: '900.00',
            investorsTotal: '155.55',
          ),
        ],
        totals: PeriodOrdersTotals(orders: 2, investorsTotal: '905.55'),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — والعددُ على البلاطات تحته، لا جملةً تحت الرقم.
    expect(find.text('ربح المستثمرين'), findsOneWidget);
    expect(find.text('905.55 د.ل'), findsOneWidget);
    expect(find.text('من 2 طلبية'), findsNothing);
  });

  testWidgets('a correction keeps its minus instead of reading as a payment', (tester) async {
    // Arrange — عكسُ طلبيةٍ من فترةٍ أُقفلت يقع على المفتوحة اليوم. وإسقاطُ إشارته يجعل ردَّ
    // مالٍ يُقرأ ربحاً — وهو نصفُ ما تفسده هذه الشاشةُ لو أخفتها.
    await register(
      const PeriodOrders(
        period: _period,
        orders: [
          PeriodOrder(
            orderId: 88,
            code: 'ORD-0088',
            status: 'cancelled',
            statusLabel: 'ملغاة',
            grandTotal: '1200.00',
            investorsTotal: '-300.00',
            investors: [PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '-300.00')],
          ),
        ],
        totals: PeriodOrdersTotals(orders: 1, investorsTotal: '-300.00'),
      ),
    );

    // Act — البطاقاتُ والبحثُ والشرائحُ فوق القائمة تدفعها تحت الإطار الافتراضي.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — في المجموع وعلى الطلبية، أحمرَ بإشارته؛ ولا جملةَ تشرحه.
    final amounts = find.text('-300 د.ل');
    expect(amounts, findsNWidgets(2));
    final error = Theme.of(tester.element(amounts.last)).colorScheme.error;
    expect(tester.widget<Text>(amounts.last).style?.color, error);
    expect(find.text('رُدَّ من نصيب المستثمرين'), findsNothing);
  });

  testWidgets('a period that paid nobody says so rather than drawing an empty list', (
    tester,
  ) async {
    // Arrange — فترةٌ مفتوحة لم تصل طلبيتُها الأولى بعد.
    await register(const PeriodOrders(period: _period));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('لم تُعطِ طلبيةٌ ربحاً للمستثمرين في هذه الفترة بعد'),
      findsOneWidget,
    );
  });

  testWidgets('the frozen figures of a closed period sit under its window', (tester) async {
    // Arrange — بها وُزّع المال، ولا تُعاد قراءتُها من الدفاتر بعد اليوم.
    await register(const PeriodOrders(period: _period));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الرمزُ في الشريط وحده، والنافذةُ والحصّةُ سطرٌ بجانب شريحة الحالة.
    expect(find.text('الفترة P7'), findsOneWidget);
    expect(find.widgetWithText(PeriodStatusChip, 'مغلقة'), findsOneWidget);
    expect(find.textContaining('1 – 30 سبتمبر 2026'), findsOneWidget);
    expect(find.textContaining('حصة المستثمرين'), findsOneWidget);
    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.text('9,000 د.ل'), findsOneWidget);
  });

  testWidgets('a closed period lists its expenses beside the profit, not inside it', (
    tester,
  ) async {
    // Arrange — قرارُ المالك: القائمةُ كما هي، والمصاريفُ ونصيبُ المستثمرين منها تحت المبيعات.
    await register(
      PeriodOrders(
        period: _period.copyWith(expensesAmount: '400.00', expensesOnInvestors: '200.00'),
      ),
    );
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — وصافي الربح على رقمه: ربحُ الطلبيات وحده.
    expect(find.text('المصاريف'), findsNWidgets(2));
    expect(find.text('400 د.ل'), findsOneWidget);
    expect(find.text('منها على المستثمرين'), findsOneWidget);
    expect(find.text('200 د.ل'), findsOneWidget);
    expect(find.text('1,500 د.ل'), findsOneWidget);
  });

  testWidgets('the expenses tab opens beside the orders', (tester) async {
    // Arrange
    await register(const PeriodOrders(period: _period));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('المصاريف'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا مصاريف على الصندوق في هذه الفترة'), findsOneWidget);
  });

  testWidgets('opened from the fund expenses, it starts on «المصاريف»', (tester) async {
    // Arrange — لمسةُ مصروفٍ في «مصاريف الصندوق» تأتي لتقرأ نصيبَ كلِّ مستثمرٍ منه.
    await register(const PeriodOrders(period: _period));

    // Act
    await tester.pumpWidget(host(opensOn: PeriodTab.expenses));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا مصاريف على الصندوق في هذه الفترة'), findsOneWidget);
  });

  testWidgets('a waiting period says how many orders still hold it', (tester) async {
    // Arrange — «قيد الإغلاق»: أرقامُها لم تُجمَّد بعد، وطلبيتان لم تصلا أو لم تُحصَّلا.
    await register(
      const PeriodOrders(
        period: FundPeriod(
          id: 8,
          code: 'P8',
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
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الشريطُ يأخذ رمزَ الفترة كما وصلت، لا ما فُتحت به الشاشة.
    expect(find.text('الفترة P8'), findsOneWidget);
    expect(find.text('الفترة P7'), findsNothing);
    expect(find.widgetWithText(PeriodStatusChip, 'قيد الإغلاق'), findsOneWidget);
    expect(find.text('تنتظر طلبيتين'), findsOneWidget);
  });

  // ───────────── §١١: أيُّ طلبيةٍ استُلم ربحُها، وأيُّها ينتظر ─────────────

  const closing = FundPeriod(
    id: 7,
    code: 'P7',
    status: 'closing',
    statusLabel: 'قيد الإغلاق',
    startsOn: '2026-09-01',
    endsOn: '2026-09-30',
    subscriptionClosesOn: '2026-09-07',
    isDueToClose: false,
    periodMonths: 1,
    investorProfitSharePercent: '50.00',
    openingStockCost: '0.00',
    openingCash: '0.00',
  );

  const released = PeriodOrder(
    orderId: 91,
    code: 'ORD-0091',
    status: 'delivered',
    statusLabel: 'تم الاستلام',
    customerName: 'مطعم البركة',
    grandTotal: '400.00',
    investorsTotal: '50.00',
    profitState: PeriodProfitState.released,
    profitStateLabel: 'استُلم الربح',
    states: [PeriodProfitState.released],
    byState: PeriodOrderByState(released: '50.00'),
    investors: [PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '50.00')],
  );

  const held = PeriodOrder(
    orderId: 92,
    code: 'ORD-0092',
    status: 'delivered',
    statusLabel: 'تم الاستلام',
    customerName: 'مخبز النور',
    grandTotal: '500.00',
    investorsTotal: '70.00',
    profitState: PeriodProfitState.awaitingPayment,
    profitStateLabel: 'بانتظار التحصيل',
    states: [PeriodProfitState.awaitingPayment],
    byState: PeriodOrderByState(awaitingPayment: '70.00'),
    uncollected: true,
    investors: [PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '70.00')],
  );

  const closingTotals = PeriodOrdersTotals(
    orders: 2,
    investorsTotal: '120.00',
    byState: PeriodStatesTotals(
      released: PeriodStateTotal(orders: 1, amount: '50.00'),
      awaitingPayment: PeriodStateTotal(orders: 1, amount: '70.00'),
    ),
  );

  Future<void> tall(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('each state carries the count and the sum the server sent', (tester) async {
    // Arrange — «شن هما الطلبيات الي تم استلام ربحهم والقيمة مع بعضهم».
    await register(
      const PeriodOrders(period: closing, orders: [released, held], totals: closingTotals),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — ثلاثُ بلاطاتٍ بسؤال المالك (2026-10-21) وتصميم ب (2026-10-25): ما استُلم، وما
    // ينتظر، وما في الطريق — كلٌّ برقمه بلا وحدة وعددِ طلبياته. والبلاطاتُ هي المرشّح، فلا
    // صفَّ شرائح يكرّر أسماءها.
    expect(find.text('استُلم ربحها'), findsOneWidget);
    expect(find.text('في الانتظار'), findsOneWidget);
    expect(find.text('قيد التسليم'), findsOneWidget);
    expect(find.byType(FilterOptionChip), findsNothing);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('50 د.ل'), findsOneWidget);
    expect(find.text('70 د.ل'), findsOneWidget);
    expect(find.text('طلبية واحدة'), findsNWidgets(2));
    expect(find.text('لا طلبيات'), findsOneWidget);
  });

  testWidgets('no sentence explains a tile — its name does', (tester) async {
    // Arrange — «ملاحظاتك الغبية»: سببُ الانتظار، و«ليس في المجموع أعلاه»، و«يُفرج عنه…» —
    // بلاطةُ «قيد التسليم» مخطّطةٌ بلا لون فتُقرأ خارج المجموع دون أن تُقال.
    await register(
      PeriodOrders(
        period: closing.copyWith(status: 'open', statusLabel: 'مفتوحة'),
        orders: const [held],
        totals: const PeriodOrdersTotals(
          orders: 1,
          investorsTotal: '70.00',
          byState: PeriodStatesTotals(
            awaitingPeriodEnd: PeriodStateTotal(orders: 1, amount: '70.00'),
          ),
        ),
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('حتى تنتهي الفترة'), findsNothing);
    expect(find.text('يُفرج عنه بعد انتهاء الفترة'), findsNothing);
    expect(find.text('حتى يُحصَّل ثمنها'), findsNothing);
    expect(find.text('متوقَّع عند التسليم — ليس في المجموع أعلاه'), findsNothing);
  });

  testWidgets('tapping a state shows only its orders, and tapping again shows all', (
    tester,
  ) async {
    // Arrange
    await register(
      const PeriodOrders(period: closing, orders: [released, held], totals: closingTotals),
    );
    await tall(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — البلاطةُ تصفّي.
    await tester.tap(find.text('في الانتظار'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ORD-0092'), findsOneWidget);
    expect(find.text('ORD-0091'), findsNothing);

    // Act — ولمسُها ثانيةً يُطفئها.
    await tester.tap(find.text('في الانتظار'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ORD-0091'), findsOneWidget);
    expect(find.text('ORD-0092'), findsOneWidget);

    // Act — والمستلَمُ وحده.
    await tester.tap(find.text('استُلم ربحها'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ORD-0091'), findsOneWidget);
    expect(find.text('ORD-0092'), findsNothing);
  });

  testWidgets('the sort menu turns the list round', (tester) async {
    // Arrange — صفُّ شرائح الترتيب صار زرّاً واحداً بجانب العنوان.
    await register(
      const PeriodOrders(period: closing, orders: [released, held], totals: closingTotals),
    );
    await tall(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    double top(String code) => tester.getTopLeft(find.text(code)).dy;
    final newestFirst = top('ORD-0092') < top('ORD-0091');

    // Act
    await tester.tap(find.byTooltip('ترتيب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الأقدم'));
    await tester.pumpAndSettle();

    // Assert — بلا يومٍ يُرتَّبان برقمهما: الأحدثُ 92 أوّلاً، والأقدمُ 91.
    expect(newestFirst, isTrue);
    expect(top('ORD-0091') < top('ORD-0092'), isTrue);
  });

  testWidgets('the search finds an order by its customer', (tester) async {
    // Arrange
    await register(
      const PeriodOrders(period: closing, orders: [released, held], totals: closingTotals),
    );
    await tall(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byType(SearchField), 'النور');
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('ORD-0092'), findsOneWidget);
    expect(find.text('ORD-0091'), findsNothing);
  });

  testWidgets('an order on the road with no cost yet says so instead of a zero', (tester) async {
    // Arrange — §١٢أ: «قبل ذلك تكون مجهولة».
    await register(
      const PeriodOrders(
        period: closing,
        orders: [
          PeriodOrder(
            orderId: 93,
            code: 'ORD-0093',
            status: 'printing',
            statusLabel: 'قيد الطباعة',
            grandTotal: '900.00',
            investorsTotal: '0.00',
            profitState: PeriodProfitState.awaitingDelivery,
            profitStateLabel: 'قيد التسليم',
            states: [PeriodProfitState.awaitingDelivery],
            byState: PeriodOrderByState(),
          ),
        ],
        totals: PeriodOrdersTotals(
          byState: PeriodStatesTotals(
            awaitingDelivery: PeriodStateTotal(orders: 1, unpriced: 1),
          ),
        ),
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — مكانَ الرقم على الطلبية، وسطرُ عدٍّ على بلاطتها.
    expect(find.text('لم يُسعَّر بعد'), findsOneWidget);
    expect(find.text('منها طلبية واحدة لم تُسعَّر'), findsOneWidget);
    expect(find.text('يُحسب ربحها حين تصير جاهزة'), findsNothing);
  });

  testWidgets('a priced order on the road shows what it will give', (tester) async {
    // Arrange
    await register(
      const PeriodOrders(
        period: closing,
        orders: [
          PeriodOrder(
            orderId: 94,
            code: 'ORD-0094',
            status: 'ready',
            statusLabel: 'جاهزة',
            grandTotal: '18000.00',
            investorsTotal: '0.00',
            profitState: PeriodProfitState.awaitingDelivery,
            profitStateLabel: 'قيد التسليم',
            states: [PeriodProfitState.awaitingDelivery],
            byState: PeriodOrderByState(awaitingDelivery: '2250.00'),
            expectedInvestors: [
              PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '2250.00'),
            ],
          ),
        ],
        investors: [
          PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '0.00', expected: '2250.00'),
        ],
        totals: PeriodOrdersTotals(
          byState: PeriodStatesTotals(
            awaitingDelivery: PeriodStateTotal(orders: 1, amount: '2250.00'),
          ),
        ),
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — على الطلبية بوحدته، وعلى بلاطة «قيد التسليم» بلاها، وتحت الشريك؛ ولا جملةَ
    // «ربح متوقّع» — البلاطةُ ونقطةُ الصفّ تقولانها.
    expect(find.text('2,250 د.ل'), findsOneWidget);
    expect(find.text('2,250'), findsOneWidget);
    expect(find.text('في الطريق 2,250'), findsOneWidget);
    expect(find.text('ربح متوقّع عند التسليم'), findsNothing);
  });

  testWidgets('an unpaid order in an open period warns that its profit will be held', (
    tester,
  ) async {
    // Arrange — قرارُ المالك ٣.
    await register(
      PeriodOrders(
        period: closing.copyWith(status: 'open', statusLabel: 'مفتوحة'),
        orders: [
          held.copyWith(
            profitState: PeriodProfitState.awaitingPeriodEnd,
            profitStateLabel: 'بانتظار انتهاء الفترة',
            states: [PeriodProfitState.awaitingPeriodEnd],
            byState: const PeriodOrderByState(awaitingPeriodEnd: '70.00'),
          ),
        ],
        totals: const PeriodOrdersTotals(
          orders: 1,
          investorsTotal: '70.00',
          byState: PeriodStatesTotals(
            awaitingPeriodEnd: PeriodStateTotal(orders: 1, amount: '70.00'),
          ),
        ),
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — في سطر العميل والحالة، بلون الخطأ.
    expect(find.textContaining('غير محصّلة'), findsOneWidget);
  });

  testWidgets('each partner sees what reached the wallet and what waits', (tester) async {
    // Arrange
    await register(
      const PeriodOrders(
        period: closing,
        orders: [released, held],
        investors: [
          PeriodInvestorShare(
            investorId: 1,
            name: 'أحمد',
            amount: '120.00',
            released: '50.00',
            pending: '70.00',
          ),
        ],
        totals: closingTotals,
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('استُلم 50 · ينتظر 70'), findsOneWidget);
  });

  testWidgets('a partner whose whole share waits is not told twice', (tester) async {
    // Arrange — «ينتظر 1,050.41» تحت «1,050.41 د.ل» كان الرقمَ نفسَه مرّتين.
    await register(
      PeriodOrders(
        period: closing.copyWith(status: 'open', statusLabel: 'مفتوحة'),
        orders: const [held],
        investors: const [
          PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '70.00', pending: '70.00'),
        ],
        totals: const PeriodOrdersTotals(
          orders: 1,
          investorsTotal: '70.00',
          byState: PeriodStatesTotals(
            awaitingPeriodEnd: PeriodStateTotal(orders: 1, amount: '70.00'),
          ),
        ),
      ),
    );
    await tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('المستثمرون'), findsOneWidget);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('ينتظر 70'), findsNothing);
  });

  testWidgets('a refusal is shown in the server words, with a way back', (tester) async {
    // Arrange
    final repository = await register(
      const PeriodOrders(period: _period),
      failure: const Failure.server(message: 'تعذّر الوصول إلى الخادم'),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    // Assert — وبرقم الفترة نفسِه، لا برقمٍ يُعاد تخمينُه.
    expect(find.text('تعذّر الوصول إلى الخادم'), findsOneWidget);
    expect(repository.asked, 2);
    expect(repository.askedFor, 7);
  });
}
