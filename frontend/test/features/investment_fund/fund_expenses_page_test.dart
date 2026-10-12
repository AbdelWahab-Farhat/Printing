import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_expenses_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

/// «مصاريف الصندوق» — كلُّ مصاريفه، وبجانب كلٍّ فترتُه، وفلترٌ بالفترة.
///
/// **ما يُثبَّت هنا أن الشاشة لا تجمع ولا تقرّر.** المجموعُ و«أيُعدّ» يصلان من الخادم، والفلترُ
/// سؤالٌ جديد للخادم لا تصفيةٌ لما حُمِّل.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeExpenses implements PeriodExpensesRepository {
  _FakeExpenses(this.pages);

  /// ما يُجاب به لكل فترة — `null` لـ«الكل».
  final Map<int?, Paginated<FundExpense>> pages;
  final asked = <int?>[];

  @override
  Future<Either<Failure, Paginated<FundExpense>>> fundExpenses({
    int? periodId,
    required int page,
  }) async {
    asked.add(periodId);

    return Right(pages[periodId] ?? const Paginated<FundExpense>(items: [], meta: _onePage));
  }

  @override
  Future<Either<Failure, PeriodExpenses>> periodExpenses(int periodId) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));

  @override
  Future<Either<Failure, Unit>> reverseExpense(int expenseId, {required String reason}) async =>
      const Left(Failure.server(message: 'لم يُستدعَ'));
}

class _MockFund extends Mock implements InvestmentFundRepository {}

const _onePage = PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0);

FundPeriod _period(int id, String status, String label) => FundPeriod(
  id: id,
  code: 'P$id',
  status: status,
  statusLabel: label,
  startsOn: '2026-0${8 + id}-01',
  endsOn: '2026-0${8 + id}-30',
  subscriptionClosesOn: '2026-0${8 + id}-07',
  isDueToClose: false,
  periodMonths: 1,
  investorProfitSharePercent: '50.00',
  openingStockCost: '0.00',
  openingCash: '0.00',
);

const _october = FundExpense(
  id: 52,
  kind: 'shipping',
  kindLabel: 'شحن',
  name: 'نقل أكتوبر',
  amount: '100.00',
  incurredOn: '2026-10-05',
  treasuryAccount: PeriodExpenseRef(id: 1, name: 'كاش'),
  period: FundExpensePeriod(id: 2, code: 'P2', status: 'open', statusLabel: 'مفتوحة'),
);

const _september = FundExpense(
  id: 41,
  kind: 'shipping',
  kindLabel: 'شحن',
  name: 'شحن سبتمبر',
  amount: '400.00',
  incurredOn: '2026-09-10',
  period: FundExpensePeriod(id: 1, code: 'P1', status: 'closing', statusLabel: 'قيد الإغلاق'),
);

Paginated<FundExpense> _page(List<FundExpense> items, String total) => Paginated<FundExpense>(
  items: items,
  meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
  extraMeta: {'expenses_total': total},
);

void main() {
  late _FakeExpenses expenses;

  setUpAll(() => registerFallbackValue(0));

  Future<void> register(Map<int?, Paginated<FundExpense>> pages) async {
    await sl.reset();
    expenses = _FakeExpenses(pages);
    final fund = _MockFund();
    when(fund.periods).thenAnswer(
      (_) async => Right([_period(2, 'open', 'مفتوحة'), _period(1, 'closing', 'قيد الإغلاق')]),
    );
    sl
      ..registerLazySingleton(() => GetFundExpenses(expenses))
      ..registerLazySingleton(() => GetFundPeriods(fund));
  }

  tearDown(() => sl.reset());

  /// الشاشةُ داخل موجّه — اللمسةُ على مصروفٍ تفتح فترتَه، و[opened] يكتب إلى أين.
  Widget host(void Function(Uri uri, Object? extra) opened) {
    final router = GoRouter(
      initialLocation: '/investment/expenses',
      routes: [
        GoRoute(
          path: '/investment/expenses',
          builder: (context, state) => const FundExpensesPage(),
        ),
        GoRoute(
          path: '/investment/periods/:id',
          builder: (context, state) {
            opened(state.uri, state.extra);

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

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('every expense is listed with its period beside it', (tester) async {
    // Arrange
    await register({null: _page([_october, _september], '500.00')});
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert — المجموعُ كما قاله الخادم، وكلُّ مصروفٍ برمز فترته في بطاقته.
    expect(find.text('كل المصاريف'), findsOneWidget);
    expect(find.text('500 د.ل'), findsOneWidget);
    expect(find.text('نقل أكتوبر'), findsOneWidget);
    expect(find.text('شحن سبتمبر'), findsOneWidget);

    final october = find.ancestor(of: find.text('نقل أكتوبر'), matching: find.byType(InkWell));
    expect(find.descendant(of: october.first, matching: find.text('P2')), findsOneWidget);
    expect(find.descendant(of: october.first, matching: find.text('100 د.ل')), findsOneWidget);
  });

  testWidgets('each period is a filter chip, newest first, after «الكل»', (tester) async {
    // Arrange
    await register({null: _page([_october, _september], '500.00')});
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert — بالترتيب الذي يقرؤه السطرُ العربيّ: «الكل» يميناً، ثم الأحدث.
    final all = tester.getCenter(find.text('الكل'));
    final p2 = tester.getCenter(find.widgetWithText(InkWell, 'P2').first);
    final p1 = tester.getCenter(find.widgetWithText(InkWell, 'P1').first);

    expect(all.dx, greaterThan(p2.dx));
    expect(p2.dx, greaterThan(p1.dx));
  });

  testWidgets('picking a period asks the server for that period and its total', (tester) async {
    // Arrange
    await register({
      null: _page([_october, _september], '500.00'),
      1: _page([_september], '400.00'),
    });
    tall(tester);
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Act — شريحةُ P1 في صفّ الفلاتر، لا رمزُ الفترة على البطاقة.
    await tester.tap(find.byKey(const ValueKey('expenses-period-1')));
    await tester.pumpAndSettle();

    // Assert — سؤالٌ جديد للخادم، والمجموعُ جوابُه لا جمعُ ما على الشاشة.
    expect(expenses.asked, [null, 1]);
    expect(find.text('مصاريف الفترة P1'), findsOneWidget);
    expect(find.text('400 د.ل'), findsNWidgets(2));
    expect(find.text('نقل أكتوبر'), findsNothing);
  });

  testWidgets('a tap opens the expense period on its «المصاريف» tab', (tester) async {
    // Arrange — نصيبُ كلِّ مستثمرٍ وزرُّ العكس هناك، لا مكرّرين هنا.
    await register({null: _page([_october], '100.00')});
    tall(tester);
    Uri? uri;
    Object? extra;
    await tester.pumpWidget(
      host((at, payload) {
        uri = at;
        extra = payload;
      }),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('نقل أكتوبر'));
    await tester.pumpAndSettle();

    // Assert
    expect(uri?.path, '/investment/periods/2');
    expect(uri?.queryParameters['tab'], 'expenses');
    expect(extra, 'P2');
  });

  testWidgets('a reversed expense stays, struck through, saying why', (tester) async {
    // Arrange
    await register({
      null: _page([
        _october.copyWith(
          counted: false,
          isReversed: true,
          reversal: const PeriodExpenseReversal(id: 60, reason: 'فاتورة مكرّرة'),
        ),
      ], '0.00'),
    });
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert
    final amount = tester.widget<Text>(find.text('100 د.ل'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
    expect(find.text('عُكس: فاتورة مكرّرة'), findsOneWidget);
  });

  testWidgets('an expense from before the first period carries no period chip', (tester) async {
    // Arrange
    await register({
      null: _page([
        const FundExpense(
          id: 9,
          kind: 'other',
          kindLabel: 'أخرى',
          name: 'رسوم قديمة',
          amount: '50.00',
          incurredOn: '2026-08-15',
        ),
      ], '50.00'),
    });
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert — بلا شريحة، وبلا بابٍ إلى فترةٍ لا توجد.
    final card = find.ancestor(of: find.text('رسوم قديمة'), matching: find.byType(InkWell));
    expect(find.descendant(of: card.first, matching: find.byIcon(AppIcons.periodOpen)), findsNothing);
    expect(tester.widget<InkWell>(card.first).onTap, isNull);
  });

  testWidgets('an expense on goods names its purchase order and how it split', (tester) async {
    // Arrange — FUND-EXPENSE-ON-GOODS: 400 دخلت تكلفةَ الرفّ و600 كُتبت على المبيعات.
    await register({
      null: _page([
        const FundExpense(
          id: 61,
          kind: 'shipping',
          kindLabel: 'شحن',
          name: 'شحن الحاوية',
          amount: '1000.00',
          incurredOn: '2026-09-15',
          period: FundExpensePeriod(id: 1, code: 'P1', status: 'closing', statusLabel: 'قيد الإغلاق'),
          purchaseOrder: FundExpensePurchaseOrder(id: 12),
          split: FundExpenseSplit(onGoods: '400.00', onSales: '600.00'),
        ),
      ], '1000.00'),
    });
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('أمر الشراء 12 · على البضاعة 400 · على المبيعات 600'), findsOneWidget);
  });

  testWidgets('no expenses in a period says so', (tester) async {
    // Arrange
    await register({null: _page(const [], '0.00')});
    tall(tester);

    // Act
    await tester.pumpWidget(host((_, _) {}));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا مصاريف على الصندوق'), findsOneWidget);
  });
}
