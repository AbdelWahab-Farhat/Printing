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

/// «الخسائر» — goods this business made and never sold.
///
/// Two of them, named separately because they are two different failures: bags spoiled on the
/// press, and bags made, counted and left on the counter by the customer who ordered them.
///
/// **Reported, never subtracted.** Both figures are already inside الربح الإجمالي by
/// construction — the material left the shelf and the cost was recognised — so a card that
/// looked like a deduction would tell the same story twice, and a reader who took it off that
/// number would be wrong by exactly this amount. That is what the line under the heading is
/// for, and it is the claim these tests are really guarding.
///
/// **Nullable, and the card is simply absent.** An app talking to a server from before this
/// feature must still draw its report rather than crash on a key that is not there.
///
/// Arrange - Act - Assert throughout.
class _MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late _MockReportRepository reports;

  const losses = PnlLosses(scrap: '120.00', partialDelivery: '400.00', total: '520.00');

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
    losses: losses,
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
      ..physicalSize = const Size(430 * 3, 1400 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  group('the payload', () {
    test('parses the block the server sends', () {
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
        'losses': {'scrap': '120.00', 'partial_delivery': '400.00', 'total': '520.00'},
        'orders_recognized': 12,
      };

      // Act
      final parsed = ProfitAndLossSummary.fromJson(json);

      // Assert — the server's own strings, to the قرش, never re-added here.
      expect(parsed.losses?.scrap, '120.00');
      expect(parsed.losses?.partialDelivery, '400.00');
      expect(parsed.losses?.total, '520.00');
    });

    test('a server that predates the feature still parses', () {
      // Arrange — the same payload with the block taken out of it.
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
        'orders_recognized': 12,
      };

      // Act
      final parsed = ProfitAndLossSummary.fromJson(json);

      // Assert
      expect(parsed.losses, isNull);
      expect(parsed.grossProfit, '7500.00');
    });
  });

  group('the card', () {
    testWidgets('names the two losses apart, and adds them up once', (tester) async {
      // Arrange
      stub();

      // Act
      await openTheReport(tester);

      // Assert — two failures with two different fixes; a single «خسائر ٥٢٠» would hide which.
      expect(find.text('الخسائر'), findsOneWidget);
      expect(find.text('خسارة تلف'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('خسارة تسليم جزئي'), findsOneWidget);
      expect(find.text('400'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
      expect(find.text('520'), findsOneWidget);
    });

    testWidgets('says out loud that it is already inside the profit above', (tester) async {
      // Arrange
      stub();

      // Act
      await openTheReport(tester);

      // Assert — the two lines this card costs, and the reason it does not read as a
      // subtraction: a reader who takes 520 off 7,500 is wrong by exactly 520.
      expect(find.textContaining('محتسبة ضمن الربح أعلاه'), findsOneWidget);
    });

    testWidgets('is absent against a server that does not send it', (tester) async {
      // Arrange
      stub(report: summary.copyWith(losses: null));

      // Act
      await openTheReport(tester);

      // Assert — and the rest of the report is still drawn.
      expect(find.text('الخسائر'), findsNothing);
      expect(find.text('7,500'), findsOneWidget);
    });

    testWidgets('a period that lost nothing says so rather than vanishing', (tester) async {
      // Arrange — zero is a real answer here, the way it is for every other row on this screen.
      stub(
        report: summary.copyWith(
          losses: const PnlLosses(scrap: '0.00', partialDelivery: '0.00', total: '0.00'),
        ),
      );

      // Act
      await openTheReport(tester);

      // Assert — «لا خسائر هذه الفترة» is worth reading; a card that disappears on a good month
      // teaches nobody where the figure lives on a bad one.
      expect(find.text('الخسائر'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });
  });
}
