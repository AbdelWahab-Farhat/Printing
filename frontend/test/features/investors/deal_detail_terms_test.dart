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

/// The deal screen's terms: the company as a partner, said only when it is one.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorRepository {}

void main() {
  late _MockRepository repository;

  /// A closed deal, so the screen offers no action and needs no session behind it.
  InvestorDeal dealWith({
    String companyStake = '0.00',
    String fundedPercent = '100.0000',
    String? printingSalePrice,
    DealOrdersProfit? ordersProfit,
  }) => InvestorDeal(
    id: 22,
    code: 'D22',
    status: 'closed',
    statusLabel: 'مقفلة',
    investorProfitSharePercent: '50.00',
    companyStake: companyStake,
    investorFundedPercent: fundedPercent,
    printingSalePrice: printingSalePrice,
    ordersProfit: ordersProfit,
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
    // The speed dial reads the session even when it has nothing to offer.
    sl.registerSingleton<Session>(Session());
    sl.registerFactory<DealDetailCubit>(
      () => DealDetailCubit(
        getDeal: GetInvestorDeal(repository),
        changeState: ChangeDealState(repository),
        recordExpense: RecordDealExpense(repository),
      ),
    );
  });

  tearDown(Injector.reset);

  testWidgets('a deal the company put money into names its stake and the partners\' fraction', (
    tester,
  ) async {
    // Arrange — the owner's example: 17,000 on the company, the partners owning 15%.
    when(() => repository.deal(22)).thenAnswer(
      (_) async => Right(dealWith(companyStake: '17000.00', fundedPercent: '15.0000')),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the half-of-profit line as before, and beneath it the second term the split
    // runs on, in the words the owner used for it.
    expect(find.text('D22 · للمستثمرين 50% من الربح'), findsOneWidget);
    expect(find.text('الشركة شريك بـ 17,000 د.ل · للمستثمرين 15% من البضاعة'), findsOneWidget);
  });

  testWidgets('a deal built by hand says nothing about the company, as before', (tester) async {
    // Arrange — no stake, all of the goods the partners'.
    when(() => repository.deal(22)).thenAnswer((_) async => Right(dealWith()));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('D22 · للمستثمرين 50% من الربح'), findsOneWidget);
    expect(find.textContaining('الشركة شريك'), findsNothing);
  });

  testWidgets('a deal that sells to the press says at what price, on the header', (tester) async {
    // Arrange — «كأننا بنشروه من المستثمر»، بـ32 للكيلو.
    when(() => repository.deal(22)).thenAnswer(
      (_) async => Right(dealWith(printingSalePrice: '32.000')),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the term that decides which road this deal earns on, beside the percentages.
    expect(find.text('تبيع السادة للمطبعة بـ 32 د.ل للوحدة'), findsOneWidget);
  });

  testWidgets('a deal without the term keeps the header as it was', (tester) async {
    // Arrange
    when(() => repository.deal(22)).thenAnswer((_) async => Right(dealWith()));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — nothing is printed for the ordinary case; «بلا سعر» would be a word on the screen
    // for every deal that ever existed before the term.
    expect(find.textContaining('تبيع السادة للمطبعة'), findsNothing);
  });

  testWidgets('a deal says what its orders made it, the road apart from the door', (tester) async {
    // Arrange — one parcel delivered and one still out, each having made the deal 3,000.
    when(() => repository.deal(22)).thenAnswer(
      (_) async => Right(
        dealWith(
          ordersProfit: const DealOrdersProfit(
            inFlight: DealProfitBucket(orders: 1, profit: '3000.00'),
            delivered: DealProfitBucket(orders: 1, profit: '3000.00'),
            total: DealProfitBucket(orders: 2, profit: '6000.00'),
          ),
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the two figures the owner asked for and the sum under them. The money on the road
    // is money the deal stands to make, so it is said in its own row rather than folded into one
    // figure a person cannot take apart.
    expect(find.text('ربح الطلبيات'), findsOneWidget);
    expect(find.text('جارية'), findsOneWidget);
    expect(find.text('مسلَّمة'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('3,000 د.ل'), findsNWidgets(2));
    expect(find.text('6,000 د.ل'), findsOneWidget);
  });

  testWidgets('a deal nothing has been sold out of yet says nothing about order profit', (
    tester,
  ) async {
    // Arrange — the goods are on the shelf and no order has touched them.
    when(() => repository.deal(22)).thenAnswer(
      (_) async => Right(
        dealWith(
          ordersProfit: const DealOrdersProfit(
            inFlight: DealProfitBucket(),
            delivered: DealProfitBucket(),
            total: DealProfitBucket(),
          ),
        ),
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — three rows of zeros is a table about nothing; «بِيع ٠» in the goods section above
    // is where a deal that has sold nothing says so.
    expect(find.text('ربح الطلبيات'), findsNothing);
  });
}