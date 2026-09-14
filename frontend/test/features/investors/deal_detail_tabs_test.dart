import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/deal_detail_page.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The deal screen's three tabs: the money, the goods, and the people.
///
/// **The terms stay out of them.** The percentages the split runs on are what every figure in
/// every tab is read against, so they sit above the bar and are on screen whichever tab is open.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorRepository {}

void main() {
  late _MockRepository repository;

  /// A closed deal with all three tabs' worth of answers on it, so the screen offers no action
  /// and needs no session behind it.
  InvestorDeal dealWith() => const InvestorDeal(
    id: 22,
    code: 'D22',
    status: 'closed',
    statusLabel: 'مقفلة',
    investorProfitSharePercent: '50.00',
    balances: DealBalances(
      capital: '30000.00',
      profit: '1500.00',
      perInvestor: [DealInvestorStanding(investorId: 7, capital: '30000.00', profit: '1500.00')],
    ),
    stock: DealStock(
      quantityReceived: '6000.000',
      quantityRemaining: '4000.000',
      quantitySold: '2000.000',
      quantityDamaged: '0.000',
      quantityShort: '0.000',
      unitLabel: 'كيس',
      costRemaining: '8000.00',
      costSold: '4000.00',
      costDamaged: '0.00',
      costShort: '0.00',
    ),
    ordersProfit: DealOrdersProfit(
      inFlight: DealProfitBucket(orders: 1, profit: '3000.00'),
      delivered: DealProfitBucket(orders: 1, profit: '3000.00'),
      total: DealProfitBucket(orders: 2, profit: '6000.00'),
    ),
    investors: [
      DealParticipant(
        id: 1,
        investorId: 7,
        investor: DealInvestorRef(id: 7, code: 'I7', name: 'أحمد'),
        committedAmount: '30000.00',
        sharePercent: '100.0000',
      ),
    ],
  );

  Widget host() => ScreenUtilInit(
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
        child: InvestorDealDetailPage(dealId: 22),
      ),
    ),
  );

  setUp(() async {
    await Injector.reset();
    repository = _MockRepository();
    sl.registerSingleton<Session>(Session());
    sl.registerFactory<DealDetailCubit>(
      () => DealDetailCubit(
        getDeal: GetInvestorDeal(repository),
        changeState: ChangeDealState(repository),
        recordExpense: RecordDealExpense(repository),
      ),
    );
    when(() => repository.deal(22)).thenAnswer((_) async => Right(dealWith()));
  });

  tearDown(Injector.reset);

  testWidgets('the money is the tab a deal opens on', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the first question asked of a deal is what it has made, so it is the one already
    // answered when the screen opens. The goods and the people are a tap away, not gone.
    expect(find.text('رأس المال في الصفقة'), findsOneWidget);
    expect(find.text('أرباح المستثمرين حتى الآن'), findsOneWidget);
    expect(find.text('ربح الطلبيات'), findsOneWidget);
    expect(find.text('طلبيات الصفقة'), findsOneWidget);

    expect(find.text('وصل'), findsNothing);
    expect(find.text('أحمد'), findsNothing);
  });

  testWidgets('the terms stay on screen whichever tab is open', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — over to the goods.
    await tester.tap(find.text('البضاعة'));
    await tester.pumpAndSettle();

    // Assert — the header is above the bar, not inside a tab: «للمستثمرين 50% من الربح» is what
    // every figure in every tab is read against.
    expect(find.text('D22 · للمستثمرين 50% من الربح'), findsOneWidget);
    expect(find.text('وصل'), findsOneWidget);
    expect(find.text('6,000 كيس'), findsOneWidget);
  });

  testWidgets('the partners are behind their own tab', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('المستثمرون'));
    await tester.pumpAndSettle();

    // Assert — the man, his slice, and what he is standing at.
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('مموَّل فعلياً'), findsOneWidget);
  });
}
