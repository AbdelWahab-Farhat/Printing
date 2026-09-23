import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investors/models/fund_share.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Investor investor({
    FundShare? fund,
    List<DealPots> deals = const <DealPots>[],
  }) {
    return Investor(
      id: 7,
      code: 'I7',
      name: 'أحمد',
      balances: InvestorBalances(
        wallet: const WalletPots(capital: '0.00', profit: '0.00'),
        deals: deals,
      ),
      fund: fund,
    );
  }

  Future<void> open(WidgetTester tester, Investor shown) async {
    when(() => getInvestor(7)).thenAnswer((_) async => Right(shown));

    // طويلةٌ بما يكفي لبطاقاتها كلّها — القائمةُ تبني ما يظهر منها وحده.
    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  Finder inFund(String text) => find.descendant(
    of: find.ancestor(of: find.text('في الصندوق'), matching: find.byType(InvestorMoneyTile)),
    matching: find.text(text),
  );

  testWidgets('reads what he put in the fund, his share, and each deposit with its lock', (
    tester,
  ) async {
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
    expect(inFund('نصيبه من ربح P2: 37.50%'), findsOneWidget);
    expect(inFund('2,000 د.ل'), findsOneWidget);
    expect(inFund('محبوسة إلى 1 سبتمبر 2027'), findsOneWidget);
    expect(inFund('1,000 د.ل'), findsOneWidget);
    expect(inFund('متاحة للاسترداد'), findsOneWidget);
  });

  testWidgets('a fresh subscriber reads when his share starts, not a bare zero', (tester) async {
    // Arrange — اكتتب في نافذة فترةٍ بدأت، فنصيبُه منها صفر ومن التالية كامل.
    const fund = FundShare(
      capital: '1000.00',
      units: '1000.000000',
      unitPrice: '1.000000',
      value: '1000.00',
      sharePercent: '0.000000',
      shareStartsNextPeriod: true,
      period: FundPeriodBrief(code: 'P2', startsOn: '2026-10-01', endsOn: '2026-10-31'),
    );

    // Act
    await open(tester, investor(fund: fund));

    // Assert
    expect(inFund('نصيبه يبدأ من الفترة القادمة'), findsOneWidget);
    expect(inFund('نصيبه من ربح P2: 0.00%'), findsNothing);
  });

  testWidgets('no deals section when no deal holds anything of his', (tester) async {
    // Arrange — صفقةٌ قديمة أُقفلت فرجع منها كلُّ شيء: سطرُها صفرٌ على صفر.
    const fund = FundShare(
      capital: '3000.00',
      units: '3000.000000',
      unitPrice: '1.000000',
      value: '3000.00',
      sharePercent: '100.000000',
    );

    // Act
    await open(
      tester,
      investor(
        fund: fund,
        deals: const [DealPots(investorDealId: 3, capital: '0.00', profit: '0.00')],
      ),
    );

    // Assert — لا عنوانَ فوق فراغ، ولا سطرَ أصفار.
    expect(find.text('في الصفقات'), findsNothing);
    expect(find.text('لا مال له في أي صفقة'), findsNothing);
    expect(find.text('صفقة #3'), findsNothing);
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

  testWidgets('a legacy deal still holding his money stays listed', (tester) async {
    // Arrange — دفعةُ شراءٍ قديمة لم تُطوَ في الصندوق بعد: مالُه فيها، وإخفاؤها يُخفي ماله.
    const deals = [DealPots(investorDealId: 1, capital: '15851.00', profit: '905.55')];

    // Act
    await open(tester, investor(deals: deals));

    // Assert
    expect(find.text('في الصفقات'), findsOneWidget);
    expect(find.text('صفقة #1'), findsOneWidget);
  });
}
