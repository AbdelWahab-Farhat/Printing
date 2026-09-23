import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
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

/// الأرقامُ الثلاثة على صفحة المستثمر — §٠.٨ من مواصفة الصندوق.
///
/// المديرُ يرى ما يراه صاحبُ المال على بوابته: **قيد التسليم**، و**معلّقة**، و**متاحة للسحب**.
/// وكانت الصفحةُ تعرض الثالثَ وحده، وربحُه في الصندوق لا يظهر في أيّ مكانٍ منها.
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

  testWidgets('the manager reads the three profit figures the investor reads', (tester) async {
    // Arrange — 750 في طلبيتين بلغتا «جاهزة»، و1,500 سُلِّمت ولم يُفرَج عنها، و300 متاحة.
    when(() => getInvestor(7)).thenAnswer(
      (_) async => const Right(
        Investor(
          id: 7,
          code: 'I7',
          name: 'أحمد',
          balances: InvestorBalances(wallet: WalletPots(capital: '2000.00', profit: '300.00')),
          profitFigures: ProfitFigures(
            awaitingDelivery: '750.00',
            ordersAwaitingDelivery: 2,
            pending: '1500.00',
            available: '300.00',
          ),
        ),
      ),
    );
    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    Finder tile(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(InvestorMoneyTile));
    Finder shows(String label, String text) =>
        find.descendant(of: tile(label), matching: find.text(text));

    expect(shows('ربح قيد التسليم', '750 د.ل'), findsOneWidget);
    expect(shows('ربح قيد التسليم', 'من طلبيتين في الطريق'), findsOneWidget);
    expect(shows('أرباح معلّقة', '1,500 د.ل'), findsOneWidget);
    expect(shows('أرباح متاحة للسحب', '300 د.ل'), findsOneWidget);
  });
}
