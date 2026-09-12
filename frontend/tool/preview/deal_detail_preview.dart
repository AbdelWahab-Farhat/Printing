// A harness, not a test: it draws the deal screen to PNGs so a change can be looked at without
// the phone. Named outside `test/` so `flutter test` never collects it.
//
//   flutter test tool/preview/deal_detail_preview.dart
//
// Two traps, both handled below: the app's text theme goes through GoogleFonts, which cannot
// fetch in a test, so the bundled Almarai is registered under the family the theme asks for; and
// Material's icon font is not loaded in a test, so icon glyphs come out as empty squares.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/deal_detail_page.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements InvestorRepository {}

const _deal = InvestorDeal(
  id: 22,
  code: 'D22',
  status: 'open',
  statusLabel: 'مفتوحة',
  investorProfitSharePercent: '50.00',
  companyStake: '17000.00',
  investorFundedPercent: '15.0000',
  balances: DealBalances(
    capital: '30000.00',
    profit: '1500.00',
    perInvestor: [
      DealInvestorStanding(investorId: 7, capital: '20000.00', profit: '1000.00'),
      DealInvestorStanding(investorId: 9, capital: '10000.00', profit: '500.00'),
    ],
  ),
  stock: DealStock(
    quantityReceived: '6000.000',
    quantityRemaining: '2000.000',
    quantitySold: '3900.000',
    quantityDamaged: '100.000',
    quantityShort: '0.000',
    unitLabel: 'كيس',
    costRemaining: '4000.00',
    costSold: '7800.00',
    costDamaged: '200.00',
    costShort: '0.00',
  ),
  ordersProfit: DealOrdersProfit(
    inFlight: DealProfitBucket(orders: 3, profit: '7400.00'),
    delivered: DealProfitBucket(orders: 5, profit: '11700.00'),
    total: DealProfitBucket(orders: 8, profit: '19100.00'),
  ),
  investors: [
    DealParticipant(
      id: 1,
      investorId: 7,
      investor: DealInvestorRef(id: 7, code: 'I7', name: 'أحمد المبروك'),
      committedAmount: '20000.00',
      sharePercent: '66.6667',
    ),
    DealParticipant(
      id: 2,
      investorId: 9,
      investor: DealInvestorRef(id: 9, code: 'I9', name: 'محمد الساعدي'),
      committedAmount: '10000.00',
      sharePercent: '33.3333',
    ),
  ],
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
  });

  testWidgets('draw the deal screen, one PNG per tab', (tester) async {
    await Injector.reset();
    final repository = _MockRepository();
    sl.registerSingleton<Session>(Session());
    sl.registerFactory<DealDetailCubit>(
      () => DealDetailCubit(
        getDeal: GetInvestorDeal(repository),
        changeState: ChangeDealState(repository),
        recordExpense: RecordDealExpense(repository),
      ),
    );
    when(() => repository.deal(22)).thenAnswer((_) async => const Right(_deal));

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
              Typography.material2021().black.apply(fontFamily: 'Cairo'),
            ).light(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const InvestorDealDetailPage(dealId: 22),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> shoot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await shoot('deal-1-profit');

    for (final (index, name) in [(1, 'deal-2-goods'), (2, 'deal-3-partners')]) {
      await tester.tap(find.text(index == 1 ? 'البضاعة' : 'المستثمرون'));
      await tester.pumpAndSettle();
      await shoot(name);
    }
  });
}
