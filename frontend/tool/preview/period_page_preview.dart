// أداةٌ لا اختبار: ترسم شاشة الفترة (تبويب «الطلبيات») إلى PNG لتُرى بلا هاتف — بأرقام لقطة
// الهاتف (P2، 2026-10-25). خارج `test/` فلا يجمعها `flutter test`.
//
//   PREVIEW_OUT=/tmp/out flutter test tool/preview/period_page_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/investment_period_page.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/investment_fund/usecases/period_expenses_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetPeriodOrders extends Mock implements GetPeriodOrders {}

class _MockGetPeriodExpenses extends Mock implements GetPeriodExpenses {}

class _MockReverseFundExpense extends Mock implements ReverseFundExpense {}

PeriodOrder _order(int id, String status, String amount) => PeriodOrder(
  orderId: id,
  code: '$id',
  status: 'ready',
  statusLabel: status,
  customerName: 'عميل تجريبي',
  grandTotal: '0.00',
  investorsTotal: amount,
  profitState: PeriodProfitState.awaitingPeriodEnd,
  profitStateLabel: 'بانتظار انتهاء الفترة',
  states: const [PeriodProfitState.awaitingPeriodEnd],
  byState: PeriodOrderByState(awaitingPeriodEnd: amount),
  investors: [PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: amount)],
);

final _p2 = PeriodOrders(
  period: const FundPeriod(
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
  ),
  orders: [_order(1308, 'جاهزة للطباعة', '50.02'), _order(1307, 'جاهزة', '1000.39')],
  investors: const [
    PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: '1050.41', pending: '1050.41'),
  ],
  totals: const PeriodOrdersTotals(
    orders: 2,
    investorsTotal: '1050.41',
    byState: PeriodStatesTotals(
      awaitingPeriodEnd: PeriodStateTotal(orders: 2, amount: '1050.41'),
    ),
  ),
);

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Cairo بأوزانه من تطبيق العميل إن وُجد بجانبه — أقربُ إلى الهاتف — وإلا Almarai كبقية الأدوات.
    final cairo = Directory('../frontend-client/assets/fonts');
    final files = cairo.existsSync()
        ? ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'].map((w) => '${cairo.path}/Cairo-$w.ttf')
        : ['assets/fonts/Almarai-Regular.ttf', 'assets/fonts/Almarai-Bold.ttf'];
    final loader = FontLoader('Cairo');
    for (final file in files) {
      loader.addFont(File(file).readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
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

  testWidgets('draw period page', (tester) async {
    await Injector.reset();
    final getOrders = _MockGetPeriodOrders();
    when(() => getOrders(2)).thenAnswer((_) async => Right(_p2));
    sl
      ..registerLazySingleton<GetPeriodOrders>(() => getOrders)
      ..registerLazySingleton<GetPeriodExpenses>(_MockGetPeriodExpenses.new)
      ..registerLazySingleton<ReverseFundExpense>(_MockReverseFundExpense.new);

    tester.view.physicalSize = const Size(430, 1100);
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
            theme: MaterialTheme(Typography.material2021().white.apply(fontFamily: 'Cairo')).dark(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const InvestmentPeriodPage(periodId: 2, periodCode: 'P2'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/period-page.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
