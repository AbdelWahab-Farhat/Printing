import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_period_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
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
  Future<Either<Failure, Unit>> recordExpense({
    required String kind,
    required String name,
    required String amount,
    required String incurredOn,
    String? notes,
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
    sl
      ..registerSingleton<Session>(Session())
      ..registerLazySingleton<GetPeriodOrders>(() => GetPeriodOrders(repository));

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
          child: InvestmentPeriodPage(periodId: 7, periodCode: 'P7'),
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

    // Assert — الاسمان مرّتين: مرّةً في سجلّ الفترة ومرّةً داخل الطلبية، وهما رقمان مختلفان
    // متى تعدّدت الطلبيات.
    expect(find.text('طلبية ORD-0091'), findsOneWidget);
    expect(find.text('تم الاستلام'), findsOneWidget);
    expect(find.textContaining('مطعم البركة'), findsOneWidget);
    expect(find.text('نصيب المستثمرين'), findsOneWidget);
    expect(find.text('562.5 د.ل'), findsNWidgets(2));
    expect(find.text('187.5 د.ل'), findsNWidgets(2));
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

    // Assert
    expect(find.text('ربح المستثمرين من طلبيات الفترة'), findsOneWidget);
    expect(find.text('905.55 د.ل'), findsOneWidget);
    expect(find.text('من 2 طلبية'), findsOneWidget);
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

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('رُدَّ من نصيب المستثمرين'), findsOneWidget);
    expect(find.text('-300 د.ل'), findsNWidgets(3));
    expect(find.text('نصيب المستثمرين'), findsNothing);
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

  testWidgets('the frozen figures of a closed period ride its header', (tester) async {
    // Arrange — بها وُزّع المال، ولا تُعاد قراءتُها من الدفاتر بعد اليوم.
    await register(const PeriodOrders(period: _period));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الفترة P7 — مغلقة'), findsOneWidget);
    expect(find.text('2026-09-01 ← 2026-09-30'), findsOneWidget);
    expect(find.text('صافي الربح'), findsOneWidget);
    expect(find.text('9,000 د.ل'), findsOneWidget);
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
