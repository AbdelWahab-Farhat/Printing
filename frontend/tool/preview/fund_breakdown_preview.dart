// A harness, not a test: it draws the fund dashboard and the four screens behind its figures to
// PNGs so they can be looked at without the phone. Named outside `test/` so `flutter test` never
// collects it.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/fund_breakdown_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_cash_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_goods_on_order_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_goods_out_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_profit_owed_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_shelf_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_fund_page.dart';
import 'package:dayaa/features/investment_fund/repositories/fund_breakdown_repository.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFund extends Mock implements InvestmentFundRepository {}

class _MockBreakdown extends Mock implements FundBreakdownRepository {}

final _now = DateTime.now();

final _cash = Paginated<FundCashEntry>(
  items: [
    FundCashEntry(
      id: 6,
      type: 'sale_proceeds',
      typeLabel: 'تحصيل مبيعات',
      isInflow: true,
      signedAmount: '312.50',
      balanceAfter: '9362.96',
      occurredAt: _now.subtract(const Duration(hours: 1)),
      description: 'طلبية 1043 · مكتبة النور',
      orderId: 1043,
    ),
    FundCashEntry(
      id: 5,
      type: 'stock_sold_to_press',
      typeLabel: 'بيع سادة للمطبعة',
      isInflow: true,
      signedAmount: '640.00',
      balanceAfter: '9050.46',
      occurredAt: _now.subtract(const Duration(hours: 3)),
      description: 'طلبية 1041 · محل الأمانة',
      orderId: 1041,
    ),
    FundCashEntry(
      id: 4,
      type: 'expense',
      typeLabel: 'مصروف',
      isInflow: false,
      signedAmount: '-45.00',
      balanceAfter: '8410.46',
      occurredAt: _now.subtract(const Duration(days: 1)),
      description: 'أجرة نقل',
    ),
    FundCashEntry(
      id: 3,
      type: 'purchase',
      typeLabel: 'شراء بضاعة',
      isInflow: false,
      signedAmount: '-12500.00',
      balanceAfter: '8455.46',
      occurredAt: _now.subtract(const Duration(days: 1, hours: 2)),
      description: 'أمر شراء #18 · مصنع الشرق للأكياس',
      purchaseOrderId: 18,
    ),
    FundCashEntry(
      id: 2,
      type: 'legacy_transfer',
      typeLabel: 'تحويل من صفقة سابقة',
      isInflow: true,
      signedAmount: '905.55',
      balanceAfter: '20955.46',
      occurredAt: _now.subtract(const Duration(days: 2)),
      description: 'عبدالرحمن',
      investorId: 1,
      notes: 'ربح عبدالرحمن من الصفقة D1',
    ),
    FundCashEntry(
      id: 1,
      type: 'deposit',
      typeLabel: 'إيداع رأس مال',
      isInflow: true,
      signedAmount: '20049.91',
      balanceAfter: '20049.91',
      occurredAt: _now.subtract(const Duration(days: 2, hours: 1)),
      description: 'عبدالرحمن',
      investorId: 1,
    ),
  ],
  meta: const PageMeta(currentPage: 1, perPage: 30, lastPage: 1, total: 6),
  extraMeta: const {'balance': '9362.96'},
);

const _shelf = FundShelf(
  total: '12216.17',
  materials: [
    FundShelfMaterial(
      stockItemId: 1,
      code: 'S12',
      name: 'كيس قماش 30×40',
      unitLabel: 'قطعة',
      quantity: '1800.000',
      value: '7560.00',
      batches: 2,
    ),
    FundShelfMaterial(
      stockItemId: 2,
      code: 'S7',
      name: 'كيس ورقي بني 25×35',
      unitLabel: 'قطعة',
      quantity: '2400.000',
      value: '3456.17',
      batches: 1,
    ),
    FundShelfMaterial(
      stockItemId: 3,
      code: 'R2',
      name: 'رول نايلون شفاف',
      unitLabel: 'كجم',
      quantity: '60.000',
      value: '1200.00',
      batches: 1,
    ),
  ],
);

final _inFlight = FundGoodsOut(
  total: '340.22',
  orders: [
    FundGoodsOrder(
      orderId: 1047,
      code: '1047',
      status: 'out_for_delivery',
      statusLabel: 'جاري التوصيل',
      customerName: 'مكتبة الفجر',
      placedAt: _now.subtract(const Duration(days: 3)),
      grandTotal: '720.00',
      paidAmount: '0.00',
      remaining: '720.00',
      cost: '340.22',
      goods: const [
        FundGoodsLine(
          stockItemId: 1,
          name: 'كيس قماش 30×40',
          unitLabel: 'قطعة',
          quantity: '81.000',
          cost: '340.22',
        ),
      ],
    ),
  ],
);

final _receivables = FundGoodsOut(
  total: '420.00',
  orders: [
    FundGoodsOrder(
      orderId: 1039,
      code: '1039',
      status: 'delivered',
      statusLabel: 'تم الاستلام',
      customerName: 'محل الأمانة',
      deliveredAt: _now.subtract(const Duration(days: 4)),
      grandTotal: '900.00',
      paidAmount: '300.00',
      remaining: '600.00',
      cost: '420.00',
      goods: const [
        FundGoodsLine(
          stockItemId: 2,
          name: 'كيس ورقي بني 25×35',
          unitLabel: 'قطعة',
          quantity: '300.000',
          cost: '420.00',
        ),
      ],
    ),
  ],
);

final _profit = FundProfitOwed(
  total: '1106.57',
  inWallets: const FundWalletProfit(
    total: '905.55',
    investors: [PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: '905.55')],
  ),
  unreleased: FundUnreleasedProfit(
    total: '201.02',
    orders: [
      PeriodOrder(
        orderId: 1043,
        code: '1043',
        status: 'delivered',
        statusLabel: 'تم الاستلام',
        customerName: 'مكتبة النور',
        occurredAt: _now.subtract(const Duration(days: 1)),
        grandTotal: '640.00',
        investorsTotal: '120.40',
        investors: const [
          PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: '80.27'),
          PeriodInvestorShare(investorId: 2, name: 'أحمد المبروك', amount: '40.13'),
        ],
      ),
      PeriodOrder(
        orderId: 1041,
        code: '1041',
        status: 'delivered',
        statusLabel: 'تم الاستلام',
        customerName: 'محل الأمانة',
        occurredAt: _now.subtract(const Duration(days: 2)),
        grandTotal: '980.00',
        investorsTotal: '86.62',
        investors: const [
          PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: '57.75'),
          PeriodInvestorShare(investorId: 2, name: 'أحمد المبروك', amount: '28.87'),
        ],
      ),
    ],
    adjustments: const [
      FundProfitAdjustment(kind: 'expense', label: 'مصروف: أجرة نقل', amount: '-6.00'),
    ],
  ),
);

final _onOrder = FundOnOrder(
  total: '12500.00',
  orders: [
    FundPurchaseOnOrder(
      purchaseOrderId: 18,
      vendorName: 'مصنع الشرق للأكياس',
      status: 'arrived',
      statusLabel: 'بانتظار الوصول',
      orderDate: _now.subtract(const Duration(days: 5)),
      value: '12500.00',
      lines: const [
        FundOnOrderLine(
          stockItemId: 1,
          name: 'كيس قماش 30×40',
          unitLabel: 'قطعة',
          quantityOrdered: '3000.000',
          quantityReceived: '0.000',
          quantityRemaining: '3000.000',
          value: '12500.00',
        ),
      ],
    ),
  ],
);

const _standing = FundStanding(
  goodsOnOrder: '12500.00',
  valuation: FundValuation(
    cash: '9362.96',
    stockOnShelf: '12216.17',
    goodsInFlight: '340.22',
    receivablesAtCost: '0.00',
    profitOwed: '1106.57',
    total: '20812.78',
  ),
  unitPrice: '0.582723',
  unitsOutstanding: '35132.56',
  period: FundPeriod(
    id: 1,
    code: 'P1',
    status: 'open',
    statusLabel: 'مفتوحة',
    startsOn: '2026-09-23',
    endsOn: '2026-09-30',
    subscriptionClosesOn: '2026-09-30',
    isDueToClose: false,
    periodMonths: 1,
    investorProfitSharePercent: '50.00',
    openingStockCost: '0.00',
    openingCash: '0.00',
    acceptsCapital: true,
    subscriptionServesNextPeriod: true,
  ),
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

  final screens = <String, Widget>{
    'fund-0-dashboard': const InvestmentFundPage(),
    'fund-1-cash': const FundCashPage(),
    'fund-1b-on-order': const FundGoodsOnOrderPage(),
    'fund-2-shelf': const FundShelfPage(),
    'fund-3-in-flight': const FundGoodsOutPage(stage: FundGoodsStage.inFlight),
    'fund-4-receivables': const FundGoodsOutPage(stage: FundGoodsStage.uncollected),
    'fund-5-profit-owed': const FundProfitOwedPage(),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('draw $name', (tester) async {
      await Injector.reset();
      final fund = _MockFund();
      final breakdown = _MockBreakdown();

      when(fund.standing).thenAnswer((_) async => const Right(_standing));
      when(() => breakdown.cash(page: any(named: 'page'))).thenAnswer((_) async => Right(_cash));
      when(breakdown.shelf).thenAnswer((_) async => const Right(_shelf));
      when(() => breakdown.goodsOut(FundGoodsStage.inFlight))
          .thenAnswer((_) async => Right(_inFlight));
      when(() => breakdown.goodsOut(FundGoodsStage.uncollected))
          .thenAnswer((_) async => Right(_receivables));
      when(breakdown.profitOwed).thenAnswer((_) async => Right(_profit));
      when(breakdown.onOrder).thenAnswer((_) async => Right(_onOrder));

      sl
        ..registerSingleton<Session>(Session())
        ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(fund))
        ..registerLazySingleton<OpenFundPeriod>(() => OpenFundPeriod(fund))
        ..registerLazySingleton<CloseFundPeriod>(() => CloseFundPeriod(fund))
        ..registerLazySingleton<DepositCapital>(() => DepositCapital(fund))
        ..registerLazySingleton<WithdrawCapital>(() => WithdrawCapital(fund))
        ..registerLazySingleton<RecordFundExpense>(() => RecordFundExpense(fund))
        ..registerLazySingleton<GetFundCash>(() => GetFundCash(breakdown))
        ..registerLazySingleton<GetFundOnOrder>(() => GetFundOnOrder(breakdown))
        ..registerLazySingleton<GetFundShelf>(() => GetFundShelf(breakdown))
        ..registerLazySingleton<GetFundGoodsOut>(() => GetFundGoodsOut(breakdown))
        ..registerLazySingleton<GetFundProfitOwed>(() => GetFundProfitOwed(breakdown));

      tester.view.physicalSize = const Size(430, 932);
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
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    });
  }
}
