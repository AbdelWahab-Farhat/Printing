// A harness, not a test: it draws the fund dashboard and «مصاريف الصندوق» to PNGs so they can be
// looked at without the phone. Named outside `test/` so `flutter test` never collects it.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/fund_expenses_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_expenses_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_fund_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/repositories/period_expenses_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFund extends Mock implements InvestmentFundRepository {}

class _MockExpenses extends Mock implements PeriodExpensesRepository {}

const _open = FundPeriod(
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

const _closing = FundPeriod(
  id: 1,
  code: 'P1',
  status: 'closing',
  statusLabel: 'قيد الإغلاق',
  startsOn: '2026-09-20',
  endsOn: '2026-09-30',
  subscriptionClosesOn: '2026-09-30',
  isDueToClose: false,
  owedOrders: 1,
  periodMonths: 1,
  investorProfitSharePercent: '50.00',
  openingStockCost: '0.00',
  openingCash: '0.00',
);

const _standing = FundStanding(
  goodsOnOrder: '2020.00',
  valuation: FundValuation(
    cash: '58.55',
    stockOnShelf: '6754.51',
    goodsInFlight: '379.56',
    receivablesAtCost: '42.52',
    profitOwed: '2383.48',
    total: '4851.66',
  ),
  unitPrice: '0.000001',
  unitsOutstanding: '3000',
  period: _open,
  waitingPeriods: [_closing],
);

const _expenses = Paginated<FundExpense>(
  items: [
    FundExpense(
      id: 7,
      kind: 'shipping',
      kindLabel: 'شحن',
      name: 'نقل بضاعة من الميناء',
      amount: '250.00',
      incurredOn: '2026-10-09',
      treasuryAccount: PeriodExpenseRef(id: 1, name: 'بريمولا قرجي'),
      recordedBy: PeriodExpenseRef(id: 3, name: 'عبدالوهاب'),
      period: FundExpensePeriod(id: 2, code: 'P2', status: 'open', statusLabel: 'مفتوحة'),
    ),
    FundExpense(
      id: 6,
      kind: 'customs',
      kindLabel: 'جمارك',
      name: 'تخليص جمركي',
      amount: '1200.00',
      incurredOn: '2026-10-03',
      treasuryAccount: PeriodExpenseRef(id: 1, name: 'بريمولا قرجي'),
      period: FundExpensePeriod(id: 2, code: 'P2', status: 'open', statusLabel: 'مفتوحة'),
    ),
    FundExpense(
      id: 5,
      kind: 'shipping',
      kindLabel: 'شحن',
      name: 'شحن بنغازي',
      amount: '400.00',
      incurredOn: '2026-09-25',
      treasuryAccount: PeriodExpenseRef(id: 2, name: 'بريمولا ولي العهد'),
      recordedBy: PeriodExpenseRef(id: 3, name: 'عبدالوهاب'),
      period: FundExpensePeriod(id: 1, code: 'P1', status: 'closing', statusLabel: 'قيد الإغلاق'),
      counted: false,
      isReversed: true,
      reversal: PeriodExpenseReversal(id: 8, reason: 'فاتورة مكرّرة'),
    ),
    FundExpense(
      id: 4,
      kind: 'other',
      kindLabel: 'أخرى',
      name: 'رسوم بنكية',
      amount: '35.00',
      incurredOn: '2026-09-21',
      period: FundExpensePeriod(id: 1, code: 'P1', status: 'closing', statusLabel: 'قيد الإغلاق'),
    ),
  ],
  meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 4),
  extraMeta: {'expenses_total': '1485.00'},
);

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Cairo');
    for (final file in ['Almarai-Regular.ttf', 'Almarai-Bold.ttf']) {
      loader.addFont(
        File('assets/fonts/$file').readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
      );
    }
    await loader.load();

    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytes()
              .then((bytes) => ByteData.view(bytes.buffer)),
        );
      await icons.load();
    }
  });

  final screens = <String, (Widget, Size)>{
    'fund-dashboard': (const InvestmentFundPage(), const Size(430, 1180)),
    'fund-expenses': (const FundExpensesPage(), const Size(430, 932)),
  };

  for (final MapEntry(key: name, value: (screen, size)) in screens.entries) {
    testWidgets('draw $name', (tester) async {
      await Injector.reset();
      final fund = _MockFund();
      final expenses = _MockExpenses();

      when(fund.standing).thenAnswer((_) async => const Right(_standing));
      when(fund.periods).thenAnswer((_) async => const Right([_open, _closing]));
      when(
        () => expenses.fundExpenses(
          periodId: any(named: 'periodId'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => const Right(_expenses));

      sl
        ..registerSingleton<Session>(
          Session()..adopt(
            const AuthUser(
              id: 1,
              name: 'مدير',
              phone: '0910000000',
              permissions: ['investors.money.record', 'investor_deals.expenses.record'],
            ),
          ),
        )
        ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(fund))
        ..registerLazySingleton<OpenFundPeriod>(() => OpenFundPeriod(fund))
        ..registerLazySingleton<CloseFundPeriod>(() => CloseFundPeriod(fund))
        ..registerLazySingleton<GetFundPeriods>(() => GetFundPeriods(fund))
        ..registerLazySingleton<DepositCapital>(() => DepositCapital(fund))
        ..registerLazySingleton<WithdrawCapital>(() => WithdrawCapital(fund))
        ..registerLazySingleton<RecordFundExpense>(() => RecordFundExpense(fund))
        ..registerLazySingleton<GetFundExpenses>(() => GetFundExpenses(expenses));

      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final key = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MaterialTheme(
                Typography.material2021().white.apply(fontFamily: 'Cairo'),
              ).dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    });
  }
}
