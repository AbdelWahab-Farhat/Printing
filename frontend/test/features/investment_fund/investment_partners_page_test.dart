import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_partners_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// المستثمرون — تبويبان: **من يقتسم ربحَ هذه الفترة، ومن يقتسم ربحَ التي تليها.**
///
/// قرارُ المالك 2026-09-23: الشركاءُ خرجوا من اللوحة إلى هذه الصفحة، والقسمان صارا تبويبين.
/// وما يُثبَّت هنا أن من اكتتب في نافذة هذه الفترة لا يقف في تبويبها بصفر، بل في القادمة بنسبته.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements InvestmentFundRepository {
  _FakeRepository(this.held);

  final FundStanding held;

  @override
  Future<Either<Failure, FundStanding>> standing() async => Right(held);

  // بقيّةُ العقد — لا تُستدعى من هذه الشاشة.
  @override
  Future<Either<Failure, FundPeriod>> openPeriod() async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, FundPeriod>> closePeriod({String? overrideReason}) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

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
  cash: '4000.00',
  stockOnShelf: '0.00',
  goodsInFlight: '0.00',
  receivablesAtCost: '0.00',
  profitOwed: '0.00',
  total: '4000.00',
);

const _period = FundPeriod(
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
);

/// أحمد يقتسم هذه الفترة كلَّها، ومحمد اكتتب في نافذتها فنصيبُه يبدأ من التالية.
const _standing = FundStanding(
  valuation: _valuation,
  period: _period,
  investors: [
    FundHolder(
      investorId: 1,
      name: 'أحمد',
      units: '3000.000000',
      sharePercent: '100.000000',
      capital: '3000.00',
      profit: '400.00',
      nextSharePercent: '75.000000',
    ),
    FundHolder(
      investorId: 2,
      name: 'محمد',
      units: '1000.000000',
      sharePercent: '0.000000',
      capital: '1000.00',
      profit: '0.00',
      shareStartsNextPeriod: true,
      nextSharePercent: '25.000000',
    ),
  ],
);

void main() {
  Future<void> register(FundStanding standing) async {
    await sl.reset();
    final repository = _FakeRepository(standing);
    sl
      ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(repository))
      ..registerLazySingleton<OpenFundPeriod>(() => OpenFundPeriod(repository))
      ..registerLazySingleton<CloseFundPeriod>(() => CloseFundPeriod(repository))
      ..registerLazySingleton<DepositCapital>(() => DepositCapital(repository))
      ..registerLazySingleton<WithdrawCapital>(() => WithdrawCapital(repository))
      ..registerLazySingleton<RecordFundExpense>(() => RecordFundExpense(repository));
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
          child: InvestmentPartnersPage(),
        ),
      ),
    );
  }

  testWidgets('the page opens on this period, with a tab for the next', (tester) async {
    // Arrange
    await register(_standing);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — التبويبان باسمَي الفترتين، والحاليةُ هي المفتوحة.
    expect(find.text('الفترة الحالية'), findsOneWidget);
    expect(find.text('الفترة القادمة'), findsOneWidget);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('100.00%'), findsOneWidget);
  });

  testWidgets('a partner who just subscribed waits in the next tab, not as a zero in this one', (
    tester,
  ) async {
    // Arrange — مالُه في الصندوق ووحداتُه قائمة، ونصيبُه من هذا الشهر صفر. و«٠٫٠٠٪» بجانب
    // اسمه تُقرأ عطباً لا قاعدة.
    await register(_standing);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — لا يقف في تبويب هذه الفترة.
    expect(find.text('محمد'), findsNothing);
    expect(find.text('0.00%'), findsNothing);

    // Act
    await tester.tap(find.text('الفترة القادمة'));
    await tester.pumpAndSettle();

    // Assert — يقف في القادمة بنسبته فيها، وكلمةٌ تقول إنه ينضمّ.
    expect(find.text('محمد'), findsOneWidget);
    expect(find.text('ينضمّ'), findsOneWidget);
    expect(find.text('25.00%'), findsOneWidget);
    expect(find.text('75.00%'), findsOneWidget);
  });

  testWidgets('a partner row is a door into that investor', (tester) async {
    // Arrange — الاسمُ على السطر ونسبتُه بجانبه، وما وراءهما — دفعاتُه، وسحوباتُه، ومتى يُفكّ
    // حبسُ ماله — على شاشة المستثمر.
    await register(_standing);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — بطاقةٌ تُنقر، وسهمٌ يقول ذلك قبل أن يجرّب أحد.
    final row = find.ancestor(of: find.text('أحمد'), matching: find.byType(InkWell));

    expect(row, findsOneWidget);
    expect(tester.widget<InkWell>(row).onTap, isNotNull);
    expect(find.descendant(of: row, matching: find.byIcon(AppIcons.forward)), findsOneWidget);
  });
}
