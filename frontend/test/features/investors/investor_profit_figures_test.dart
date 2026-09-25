import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetInvestor extends Mock implements GetInvestor {}

class _MockRecordWalletEntry extends Mock implements RecordWalletEntry {}

/// الأرقامُ الثلاثة على صفحة المستثمر — §٠.٨ من مواصفة الصندوق.
///
/// المديرُ يرى ما يراه صاحبُ المال على بوابته: مجموعَ الربح وبوّاباتِه الثلاث — **قيد التسليم**،
/// و**معلّقة**، و**متاحة للسحب** — ظاهرةً معه بلا زرّ، والبوابةُ تبقى بأزرارها.
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

    // Assert — المجموعُ أولاً: 750 + 1,500 + 300، وبوّاباتُه الثلاث ظاهرةٌ معه بلا لمسة
    // («أ · لمحة واحدة»، 2026-09-25).
    expect(find.text('الأرباح'), findsOneWidget);
    expect(find.text('2,550 د.ل'), findsOneWidget);
    expect(find.text('قيد التسليم'), findsOneWidget);
    expect(find.text('750 د.ل'), findsOneWidget);
    expect(find.text('معلّقة'), findsOneWidget);
    expect(find.text('1,500 د.ل'), findsOneWidget);
    expect(find.text('متاحة للسحب'), findsOneWidget);
    expect(find.text('300 د.ل'), findsOneWidget);
  });
}
