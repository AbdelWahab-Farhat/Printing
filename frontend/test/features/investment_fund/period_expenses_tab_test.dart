import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/period_expenses_tab.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// تبويبُ «المصاريف» في شاشة الفترة — ما خرج من الصندوق، وما تحمّله المستثمرون منه.
///
/// **ما يُثبَّت هنا أن الشاشة لا تجمع ولا تقرّر.** المجاميعُ و«أيُعدّ» تصل من الخادم، وما لا
/// يُعدّ يبقى سطراً يقول لماذا.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeRepository implements PeriodExpensesRepository {
  _FakeRepository(this.held);

  PeriodExpenses held;
  int asked = 0;
  (int, String)? reversed;

  @override
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId) async {
    asked++;

    return Right(held);
  }

  @override
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason}) async {
    reversed = (expenseId, reason);

    return const Right(unit);
  }
}

const _period = FundPeriod(
  id: 7,
  code: 'P7',
  status: 'open',
  statusLabel: 'مفتوحة',
  startsOn: '2026-10-01',
  endsOn: '2026-10-31',
  subscriptionClosesOn: '2026-10-07',
  isDueToClose: false,
  periodMonths: 1,
  investorProfitSharePercent: '50.00',
  openingStockCost: '0.00',
  openingCash: '10000.00',
);

const _shipping = PeriodExpense(
  id: 41,
  kind: 'shipping',
  kindLabel: 'شحن',
  name: 'شحن بنغازي',
  amount: '400.00',
  incurredOn: '2026-10-10',
  treasuryAccount: PeriodExpenseRef(id: 1, name: 'الخزنة'),
  recordedBy: PeriodExpenseRef(id: 3, name: 'فرحات'),
  canReverse: true,
  investorsAmount: '200.00',
  investors: [
    PeriodInvestorShare(investorId: 1, name: 'سالم', amount: '120.00'),
    PeriodInvestorShare(investorId: 2, name: 'خالد', amount: '80.00'),
  ],
);

void main() {
  late _FakeRepository repository;

  Future<void> register(PeriodExpenses held, {List<String> permissions = const []}) async {
    await sl.reset();
    repository = _FakeRepository(held);
    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
      )
      ..registerLazySingleton(() => GetPeriodExpenses(repository))
      ..registerLazySingleton(() => ReverseFundExpense(repository));
  }

  tearDown(() => sl.reset());

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
          child: Scaffold(body: PeriodExpensesTab(periodId: 7)),
        ),
      ),
    );
  }

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('each expense says what it cost and what each investor bore', (tester) async {
    // Arrange
    await register(
      const PeriodExpenses(
        period: _period,
        expenses: [_shipping],
        totals: PeriodExpensesTotals(expensesTotal: '400.00', investorsTotal: '200.00'),
      ),
    );
    tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — المجموعُ كما وصل، ونصيبُ كلِّ شريكٍ تحت المصروف لا خلف نقرة.
    expect(find.text('400 د.ل'), findsNWidgets(2));
    expect(find.text('منها على المستثمرين 200 د.ل'), findsOneWidget);
    expect(find.text('شحن بنغازي'), findsOneWidget);
    expect(find.text('شحن'), findsOneWidget);
    expect(find.textContaining('الخزنة'), findsOneWidget);
    expect(find.textContaining('سجّله فرحات'), findsOneWidget);
    expect(find.text('على المستثمرين'), findsOneWidget);
    expect(find.text('120 د.ل'), findsOneWidget);
    expect(find.text('80 د.ل'), findsOneWidget);
  });

  testWidgets('a reversed expense stays on the list, struck through, with its reason', (
    tester,
  ) async {
    // Arrange — عُكس في فترته المفتوحة: لا يُعدّ، ولا يحمّل أحداً.
    await register(
      const PeriodExpenses(
        period: _period,
        expenses: [
          PeriodExpense(
            id: 42,
            kind: 'customs',
            kindLabel: 'جمارك',
            name: 'جمرك مكرّر',
            amount: '300.00',
            counted: false,
            isReversed: true,
            reversal: PeriodExpenseReversal(id: 43, reason: 'فاتورة مكرّرة', periodCode: 'P7'),
          ),
        ],
      ),
      permissions: ['investors.money.reverse'],
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — ولا زرَّ عكسٍ على ما عُكس.
    final amount = tester.widget<Text>(find.text('300 د.ل'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('عُكس في الفترة P7: فاتورة مكرّرة'), findsOneWidget);
    expect(find.text('عكس المصروف'), findsNothing);
  });

  testWidgets('one reversed after its period closed still counts there, and says so', (
    tester,
  ) async {
    // Arrange
    await register(
      PeriodExpenses(
        period: _period,
        expenses: [
          _shipping.copyWith(
            isReversed: true,
            reversal: const PeriodExpenseReversal(id: 44, reason: 'خطأ', periodCode: 'P8'),
          ),
        ],
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    final amount = tester.widget<Text>(find.text('400 د.ل'));
    expect(amount.style?.decoration, isNot(TextDecoration.lineThrough));
    expect(
      find.text('عُكس بعد إقفال الفترة في الفترة P8: خطأ — يبقى في أرقامها، والردُّ هناك'),
      findsOneWidget,
    );
  });

  testWidgets('a refund from a closed period sits under its own heading, as a refund', (
    tester,
  ) async {
    // Arrange — مصروفُ فترةٍ أُقفلت عُكس اليوم، فرُدّ ما حُمِّل على هذه الفترة.
    await register(
      PeriodExpenses(
        period: _period,
        corrections: [
          _shipping.copyWith(
            counted: false,
            isReversed: true,
            investorsAmount: '-200.00',
            investors: const [
              PeriodInvestorShare(investorId: 1, name: 'سالم', amount: '-120.00'),
              PeriodInvestorShare(investorId: 2, name: 'خالد', amount: '-80.00'),
            ],
          ),
        ],
        totals: const PeriodExpensesTotals(investorsTotal: '-200.00'),
      ),
    );
    tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا مصاريف على الصندوق في هذه الفترة'), findsOneWidget);
    expect(find.text('تصحيحات من فترات سابقة'), findsOneWidget);
    expect(find.text('رُدَّ إلى المستثمرين'), findsOneWidget);
    expect(find.text('رُدَّ إلى المستثمرين 200 د.ل'), findsOneWidget);
    expect(find.text('120 د.ل'), findsOneWidget);
  });

  testWidgets('the reverse button needs the money-reverse grant', (tester) async {
    // Arrange
    await register(const PeriodExpenses(period: _period, expenses: [_shipping]));
    tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('عكس المصروف'), findsNothing);
  });

  testWidgets('a closed period\'s expense offers no reversal, whatever the grant', (tester) async {
    // Arrange — قرارُ المالك 2026-10-05: أرقامُها أُعلنت. الخادمُ يقولها، والشاشةُ لا تخمّن.
    await register(
      PeriodExpenses(period: _period, expenses: [_shipping.copyWith(canReverse: false)]),
      permissions: ['investors.money.reverse'],
    );
    tall(tester);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('شحن بنغازي'), findsOneWidget);
    expect(find.text('عكس المصروف'), findsNothing);
  });

  testWidgets('reversing asks for a reason, then reads the tab again', (tester) async {
    // Arrange
    await register(
      const PeriodExpenses(period: _period, expenses: [_shipping]),
      permissions: ['investors.money.reverse'],
    );
    tall(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('عكس المصروف'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField).last, 'فاتورة مكرّرة');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'عكس المصروف').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — بالرقم والسبب، ثم تُقرأ المجاميعُ من الخادم لا تُرقَّع هنا.
    expect(repository.reversed, (41, 'فاتورة مكرّرة'));
    expect(repository.asked, 2);
  });
}
