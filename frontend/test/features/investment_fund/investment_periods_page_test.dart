import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_periods_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// سجلُّ الفترات — والصفُّ فيه **بابٌ**، لا لوحةَ قراءةٍ مغلقة.
///
/// «للمستثمرين ٩٠٥» يفتح سؤالاً ولا يجيبه: أيُّ طلبيةٍ أعطته وكم أخذ كلُّ شريك. فما يستحقّ
/// اختباراً هنا أن النقرة تُفضي إلى ذلك التفصيل، ومعها رمزُ الفترة فلا يبقى الشريطُ فارغاً
/// ريثما يردّ الخادم.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements InvestmentFundRepository {
  _FakeRepository(this.held);

  final List<FundPeriod> held;

  @override
  Future<Either<Failure, List<FundPeriod>>> periods() async => Right(held);

  // بقيّةُ العقد — لا تُستدعى من هذه الشاشة.
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

const _closed = FundPeriod(
  id: 7,
  code: 'P7',
  status: 'closed',
  statusLabel: 'مغلقة',
  startsOn: '2026-08-01',
  endsOn: '2026-08-31',
  subscriptionClosesOn: '2026-08-07',
  isDueToClose: true,
  periodMonths: 1,
  investorProfitSharePercent: '50.00',
  openingStockCost: '0.00',
  openingCash: '0.00',
  netProfit: '1500.00',
  investorsPool: '750.00',
  companyShare: '750.00',
  salesRevenue: '9000.00',
  closingStockCost: '12000.00',
);

void main() {
  String? pushed;
  Object? carried;

  setUp(() {
    pushed = null;
    carried = null;
  });

  Future<void> register(List<FundPeriod> periods) async {
    await sl.reset();
    final repository = _FakeRepository(periods);
    sl.registerLazySingleton<GetFundPeriods>(() => GetFundPeriods(repository));
  }

  Widget host() {
    final router = GoRouter(
      initialLocation: '/investment/periods',
      routes: [
        GoRoute(
          path: '/investment/periods',
          builder: (context, state) => const InvestmentPeriodsPage(),
        ),
        GoRoute(
          path: '/investment/periods/:id',
          builder: (context, state) {
            pushed = state.uri.path;
            carried = state.extra;

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

  testWidgets('a closed period wears the figures it was paid out by', (tester) async {
    // Arrange — بها وُزّع المال، ولا تُعاد قراءتُها من الدفاتر بعد اليوم.
    await register(const [_closed]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('P7'), findsOneWidget);
    expect(find.text('للمستثمرين'), findsOneWidget);
    expect(find.text('750 د.ل'), findsNWidgets(2));
  });

  testWidgets('tapping a period opens what made its figure, carrying its code', (tester) async {
    // Arrange — الرمزُ يسافر مع النقرة فلا يبقى الشريطُ مجهولاً ريثما يردّ الخادم.
    await register(const [_closed]);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('P7'));
    await tester.pumpAndSettle();

    // Assert
    expect(pushed, '/investment/periods/7');
    expect(carried, 'P7');
  });

  testWidgets('a period waiting for its orders says how many hold it', (tester) async {
    // Arrange — §٠.٧: الحالةُ الثالثة. انتهت نافذتُها في موعدها، وبقيت لها ثلاثُ طلبيات.
    await register(const [
      FundPeriod(
        id: 8,
        code: 'P8',
        status: 'closing',
        statusLabel: 'قيد الإغلاق',
        startsOn: '2026-09-22',
        endsOn: '2026-09-30',
        subscriptionClosesOn: '2026-09-30',
        isDueToClose: false,
        owedOrders: 3,
        periodMonths: 1,
        investorProfitSharePercent: '50.00',
        openingStockCost: '0.00',
        openingCash: '0.00',
      ),
    ]);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('قيد الإغلاق'), findsOneWidget);
    expect(find.text('تنتظر 3 طلبيات'), findsOneWidget);
  });
}
