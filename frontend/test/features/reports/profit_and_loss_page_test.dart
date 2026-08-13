import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/reports/models/profit_and_loss_summary.dart';
import 'package:printing/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:printing/features/reports/presentation/views/profit_and_loss_page.dart';
import 'package:printing/features/reports/repositories/report_repository.dart';
import 'package:printing/features/reports/usecases/get_profit_and_loss.dart';

/// الأرباح والخسائر, as it is seen.
///
/// Real Cubit, real use case, fake repository — so the figures on screen are the ones that came
/// off the wire rather than ones a test described.
///
/// The load-bearing claim here is the last two tests': **النقد المحصَّل is a different thing from
/// الربح الإجمالي and has to read as one.** It belongs to no order above it — it is every payment
/// whose day fell inside the window — so a screen that let it be mistaken for part of the
/// arithmetic would be inviting a cash-basis margin this business does not compute.
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
      () => reports.profitAndLoss(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => failure != null ? Left(failure) : Right(report ?? summary),
    );
  }

  /// The same frame the app boots into: ScreenUtil at the reference design size, Arabic, RTL.
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

  /// Taller than the reference phone on purpose: the whole report then sits inside one
  /// viewport, and `find.text` reaches every figure without a drag standing between the test
  /// and what it is asserting.
  Future<void> openTheReport(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 1100 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  testWidgets('the revenue block says what was earned, in grouped digits', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheReport(tester);

    // Assert — the server's decimals are dropped and the digits grouped; nothing is added up here
    expect(find.text('الإيراد'), findsOneWidget);
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('12,450'), findsOneWidget);
    expect(find.text('التصميم'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('إجمالي الإيراد'), findsOneWidget);
    expect(find.text('12,750'), findsOneWidget);
  });

  testWidgets('the cost is broken into its three parts and its own total', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheReport(tester);

    // Assert — all four as they arrived: the parts come from a different table than the total
    // and are allowed to disagree with it
    expect(find.text('تكلفة البضاعة المباعة'), findsOneWidget);
    expect(find.text('4,000'), findsOneWidget);
    expect(find.text('900'), findsOneWidget);
    expect(find.text('350'), findsOneWidget);
    expect(find.text('5,250'), findsOneWidget);
  });

  testWidgets('the period says how many orders it is actually about', (tester) async {
    // Arrange — an all-zero report has two meanings, and this line is what tells them apart
    stub();

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('12 طلبية محتسبة'), findsOneWidget);
    expect(find.text('من 2026-03-01 إلى 2026-03-31'), findsOneWidget);
  });

  testWidgets('a period nothing was delivered in says so rather than showing bare zeros', (
    tester,
  ) async {
    // Arrange
    stub(
      report: const ProfitAndLossSummary(
        period: PnlPeriod(from: '2026-04-01', to: '2026-04-30'),
        revenue: PnlRevenue(product: '0.00', service: '0.00', total: '0.00'),
        costOfGoodsSold: PnlCostOfGoodsSold(
          material: '0.00',
          labor: '0.00',
          overhead: '0.00',
          total: '0.00',
        ),
        grossProfit: '0.00',
        cashCollected: '150.00',
        ordersRecognized: 0,
      ),
    );

    // Act
    await openTheReport(tester);

    // Assert — and the deposit taken against work not yet delivered is still reported
    expect(find.text('لا طلبيات مسلَّمة أو مصفّاة في هذه الفترة'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
  });

  testWidgets('a losing period is said in a sentence, not only in a colour', (tester) async {
    // Arrange
    stub(
      report: const ProfitAndLossSummary(
        period: PnlPeriod(from: '2026-03-01', to: '2026-03-31'),
        revenue: PnlRevenue(product: '75.00', service: '0.00', total: '75.00'),
        costOfGoodsSold: PnlCostOfGoodsSold(
          material: '120.00',
          labor: '0.00',
          overhead: '0.00',
          total: '120.00',
        ),
        grossProfit: '-45.00',
        cashCollected: '0.00',
        ordersRecognized: 1,
      ),
    );

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('-45'), findsOneWidget);
    expect(find.text('الفترة خاسرة — التكلفة أكبر من الإيراد.'), findsOneWidget);
  });

  testWidgets('cash collected is named apart from the profit, never as part of it', (
    tester,
  ) async {
    // Arrange
    stub();

    // Act
    await openTheReport(tester);

    // Assert — two different headings over two different figures
    expect(find.text('الربح الإجمالي'), findsOneWidget);
    expect(find.text('7,500'), findsOneWidget);
    expect(find.text('النقد المحصَّل'), findsOneWidget);
    expect(find.text('9,100'), findsOneWidget);
  });

  testWidgets('cash collected says in words that it is not netted against the cost', (
    tester,
  ) async {
    // Arrange — the sentence is the point of the card: it is every payment in the window
    // whatever order it was against, and refunds are not taken off it
    stub();

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.textContaining('لا يُطرح من التكلفة ولا يدخل في الربح أعلاه'), findsOneWidget);
    expect(find.textContaining('المبالغ المستردة لا تُخصم منه'), findsOneWidget);
  });

  testWidgets('a refused date is shown under its own picker, not as a page of apology', (
    tester,
  ) async {
    // Arrange — the only 422 this screen can reach, and the server's own Arabic for it
    stub(
      failure: const Failure.server(
        message: 'البيانات المدخلة غير صحيحة',
        statusCode: 422,
        fieldErrors: {
          'to': ['تاريخ النهاية يجب أن يكون بعد تاريخ البداية'],
        },
      ),
    );

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية'), findsOneWidget);
    expect(find.text('صحّح الفترة أعلاه لعرض التقرير'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('anything else the server refuses takes the page, with its own words', (
    tester,
  ) async {
    // Arrange
    stub(failure: const Failure.forbidden(message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء'));

    // Act
    await openTheReport(tester);

    // Assert
    expect(find.text('ليس لديك صلاحية لتنفيذ هذا الإجراء'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
