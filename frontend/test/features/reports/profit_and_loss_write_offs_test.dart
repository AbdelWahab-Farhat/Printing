import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:dayaa/features/reports/presentation/views/profit_and_loss_page.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';
import 'package:dayaa/features/reports/usecases/get_profit_and_loss.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «المبالغ المشطوبة» — money the business decided it will never collect.
///
/// The server has published `write_offs` since the write-off feature shipped and this app has
/// never read it: the figure existed, in the payload, on a screen nobody could see it on.
///
/// **It is not a loss on the «الخسائر» card, and putting it there was the obvious mistake.** A
/// write-off forgives a receivable — nothing was made and nothing was spoiled — and this
/// statement recognises revenue when the order is delivered and carries no expense side at all,
/// so there is nowhere in the arithmetic above to hang a bad debt. `ProfitAndLossSummaryQuery`
/// says so in its own words and puts the key beside `cash_collected` rather than inside
/// `losses`. So it sits under the break in the page, on the reconciliation shelf النقد المحصَّل
/// already occupies — where «لا يُطرح من الربح أعلاه» is the whole point of the shelf.
///
/// Arrange - Act - Assert throughout.
class _MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late _MockReportRepository reports;

  const summary = ProfitAndLossSummary(
    period: PnlPeriod(from: '2026-03-01', to: '2026-03-31'),
    revenue: PnlRevenue(product: '12450.00', service: '300.00', total: '12750.00'),
    costOfGoodsSold: PnlCostOfGoodsSold(
      material: '4000.00',
      labor: '900.00',
      overhead: '350.00',
      total: '5250.00',
    ),
    grossProfit: '7500.00',
    cashCollected: '9100.00',
    writeOffs: '250.00',
    losses: PnlLosses(scrap: '120.00', partialDelivery: '400.00', total: '520.00'),
    ordersRecognized: 12,
  );

  setUp(() async {
    await Injector.reset();

    reports = _MockReportRepository();

    sl.registerFactory<ProfitAndLossCubit>(
      () => ProfitAndLossCubit(getSummary: GetProfitAndLoss(reports)),
    );
  });

  tearDown(Injector.reset);

  void stub({ProfitAndLossSummary? report, Failure? failure}) {
    when(
      () => reports.profitAndLoss(from: any(named: 'from'), to: any(named: 'to')),
    ).thenAnswer((_) async => failure != null ? Left(failure) : Right(report ?? summary));
  }

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
      home: ProfitAndLossPage(),
    ),
  );

  /// Taller than the reference phone, so the whole report sits in one viewport and `find.text`
  /// reaches every figure without a drag standing between the test and what it asserts.
  Future<void> openTheReport(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 1600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  test('the key the app had been dropping on the floor is parsed', () {
    // Arrange
    const json = {
      'period': {'from': '2026-03-01', 'to': '2026-03-31'},
      'revenue': {'product': '12450.00', 'service': '300.00', 'total': '12750.00'},
      'cost_of_goods_sold': {
        'material': '4000.00',
        'labor': '900.00',
        'overhead': '350.00',
        'total': '5250.00',
      },
      'gross_profit': '7500.00',
      'cash_collected': '9100.00',
      'write_offs': '250.00',
      'orders_recognized': 12,
    };

    // Act
    final parsed = ProfitAndLossSummary.fromJson(json);

    // Assert
    expect(parsed.writeOffs, '250.00');
  });

  testWidgets('the figure is stated, beside the cash it did not come in as', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('المبالغ المشطوبة'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('it sits below the break, not on the losses card', (tester) async {
    // Arrange — the mistake this test exists to prevent: «الخسائر» is what the shop made and
    // never sold, and a forgiven debt is neither made nor spoiled.
    stub();

    // Act
    await openTheReport(tester);
    final losses = tester.getTopLeft(find.text('الخسائر')).dy;
    final writeOffs = tester.getTopLeft(find.text('المبالغ المشطوبة')).dy;

    // Assert — under النقد المحصَّل, which is under the rule that ends the arithmetic.
    expect(writeOffs, greaterThan(losses));
    expect(writeOffs, greaterThan(tester.getTopLeft(find.text('النقد المحصَّل')).dy));
  });

  testWidgets('it says it is not taken off the profit above', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheReport(tester);

    // Assert — the one sentence that stops a reader subtracting it from 7,500.
    expect(find.textContaining('لا يُطرح من الربح أعلاه'), findsOneWidget);
  });

  testWidgets('a server that does not send it is not answered for', (tester) async {
    // Arrange
    stub(report: summary.copyWith(writeOffs: null));

    // Act
    await openTheReport(tester);

    // Assert — and النقد المحصَّل, which shares the block, is still drawn.
    expect(find.text('المبالغ المشطوبة'), findsNothing);
    expect(find.text('النقد المحصَّل'), findsOneWidget);
    expect(find.text('9,100'), findsOneWidget);
  });

  testWidgets('a period that forgave nothing still says so', (tester) async {
    // Arrange — zero is a real answer on this screen, the way it is for every other row.
    stub(report: summary.copyWith(writeOffs: '0.00'));

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('المبالغ المشطوبة'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}
