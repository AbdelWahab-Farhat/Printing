import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/sales_statistics_cubit.dart';
import 'package:dayaa/features/reports/presentation/views/sales_statistics_page.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';
import 'package:dayaa/features/reports/usecases/get_sales_statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// إحصائيات المبيعات, as it is seen.
///
/// Real Cubit, real use case, fake repository — so the figures on screen are the ones that came
/// off the wire rather than ones a test described.
///
/// The load-bearing claims are the last three tests': **a row that earned money and weighs
/// nothing must still be drawn**, because its value is part of the total above it and hiding it
/// would make the table stop adding up; **the coverage caveat appears only when it means
/// something**; and **an empty period is answered in words**, not with five blocks of zeroes.
///
/// Arrange - Act - Assert throughout.
class _MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late _MockReportRepository reports;

  const board = SalesStatistics(
    period: StatisticsPeriod(from: '2026-08-01', to: '2026-09-08'),
    salesValue: SalesValue(plain: '5626.40', printed: '8193.00', total: '13819.40'),
    byType: [
      BagTypeRow(
        type: 'أكياس الشحن',
        value: '9157.90',
        weightKg: '294.700',
        plainKg: '111.200',
        printedKg: '183.500',
        pieces: 4150,
      ),
      // Stocked by the piece: real money, no weight anybody ever took.
      BagTypeRow(
        type: 'أكياس ورقية عادية -',
        value: '1072.50',
        weightKg: '0.000',
        plainKg: '0.000',
        printedKg: '0.000',
        pieces: 400,
      ),
    ],
    weightComparison: WeightComparison(
      plainKg: '154.200',
      printedKg: '211.100',
      totalKg: '365.300',
      printedSharePercent: '57.8',
      weightCoveragePercent: '92.2',
    ),
    printedPieces: PrintedPieces(count: 5270, weightKg: '211.100'),
    ordersCounted: 32,
  );

  setUp(() async {
    await Injector.reset();

    reports = _MockReportRepository();

    sl.registerFactory<SalesStatisticsCubit>(
      () => SalesStatisticsCubit(getStatistics: GetSalesStatistics(reports)),
    );
  });

  tearDown(Injector.reset);

  void stub({SalesStatistics? statistics, Failure? failure}) {
    when(
      () => reports.salesStatistics(from: any(named: 'from'), to: any(named: 'to')),
    ).thenAnswer((_) async => failure != null ? Left(failure) : Right(statistics ?? board));
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
      home: SalesStatisticsPage(),
    ),
  );

  /// Taller than the reference phone on purpose: the whole board then sits inside one viewport,
  /// and `find.text` reaches every figure without a drag standing between the test and what it
  /// is asserting.
  Future<void> openTheBoard(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 1600 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  testWidgets('the three money totals are read first, side by side', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheBoard(tester);

    // Assert — the whole period at the till in one row, each the server's own figure
    expect(find.text('الإجمالي'), findsWidgets);
    expect(find.text('13,819.4'), findsOneWidget);
    expect(find.text('5,626.4'), findsOneWidget);
    expect(find.text('8,193'), findsOneWidget);
  });

  testWidgets('the period drawn is the window the server echoed back', (tester) async {
    // Arrange — the app sends what a preset computed from the phone's clock; the server answers
    // about its own days, and those are the ones the figures belong to
    stub();

    // Act
    await openTheBoard(tester);

    // Assert
    expect(find.text('من 2026-08-01 إلى 2026-09-08'), findsOneWidget);
  });

  testWidgets('the denominator is on the board beside the money', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheBoard(tester);

    // Assert — «على كم طلبية؟» is the sanity check a reader makes before trusting any of it
    expect(find.text('على 32 طلبية'), findsOneWidget);
  });

  testWidgets('the printed share is the server\'s figure, not two weights divided', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheBoard(tester);

    // Assert — 211.1 of 365.3 is 57.79…, and a screen that divided it itself would print 57.8
    // only by luck; this is the string the server sent
    expect(find.text('نسبة المطبوع'), findsOneWidget);
    expect(find.text('57.8'), findsOneWidget);
    expect(find.text('365.3'), findsOneWidget);
  });

  testWidgets('the piece count is kept apart from the weights, in its own unit', (tester) async {
    // Arrange
    stub();

    // Act
    await openTheBoard(tester);

    // Assert — the figure the press's own share will be computed from
    expect(find.text('عدد الأكياس المطبوعة'), findsOneWidget);
    expect(find.text('5,270'), findsOneWidget);
    expect(find.text('قطعة'), findsOneWidget);
  });

  testWidgets('a row that earned money and weighs nothing is still drawn', (tester) async {
    // Arrange — أكياس ورقية عادية is stocked by the piece, so nobody ever weighed it. Hiding the
    // row would take its value out of a table that has to add up to the total above it.
    stub();

    // Act
    await openTheBoard(tester);

    // Assert — the untidy label is rendered exactly as it arrived, trailing dash and all
    expect(find.text('مبيعات الأكياس حسب النوع'), findsOneWidget);
    expect(find.text('أكياس ورقية عادية -'), findsOneWidget);
    expect(find.text('1,072.5'), findsOneWidget);
  });

  testWidgets('the coverage caveat is drawn when some value has no weight', (tester) async {
    // Arrange — 92.2%: without this line the kilograms look wrong beside their own dinars
    stub();

    // Act
    await openTheBoard(tester);

    // Assert
    expect(find.text('تغطية الوزن'), findsOneWidget);
    expect(find.text('92.2'), findsOneWidget);
  });

  testWidgets('the coverage caveat is absent when everything was weighed', (tester) async {
    // Arrange — at 100 it is noise
    stub(
      statistics: const SalesStatistics(
        period: StatisticsPeriod(from: '2026-03-01', to: '2026-03-31'),
        salesValue: SalesValue(plain: '0.00', printed: '1800.00', total: '1800.00'),
        byType: [
          BagTypeRow(
            type: 'كيس شحن',
            value: '1800.00',
            weightKg: '20.500',
            plainKg: '0.000',
            printedKg: '20.500',
            pieces: 1000,
          ),
        ],
        weightComparison: WeightComparison(
          plainKg: '0.000',
          printedKg: '20.500',
          totalKg: '20.500',
          printedSharePercent: '100.0',
          weightCoveragePercent: '100.0',
        ),
        printedPieces: PrintedPieces(count: 1000, weightKg: '20.500'),
        ordersCounted: 1,
      ),
    );

    // Act
    await openTheBoard(tester);

    // Assert
    expect(find.text('تغطية الوزن'), findsNothing);
  });

  testWidgets('a period with nothing in it is answered in words', (tester) async {
    // Arrange — zero is a real answer, and five blocks of zeroes is an answer nobody can tell
    // apart from a screen that failed to load
    stub(
      statistics: const SalesStatistics(
        period: StatisticsPeriod(from: '2026-03-01', to: '2026-03-31'),
        salesValue: SalesValue(plain: '0.00', printed: '0.00', total: '0.00'),
        byType: [],
        weightComparison: WeightComparison(
          plainKg: '0.000',
          printedKg: '0.000',
          totalKg: '0.000',
          printedSharePercent: '0.0',
          weightCoveragePercent: '0.0',
        ),
        printedPieces: PrintedPieces(count: 0, weightKg: '0.000'),
        ordersCounted: 0,
      ),
    );

    // Act
    await openTheBoard(tester);

    // Assert
    expect(find.text('لا مبيعات أكياس في هذه الفترة'), findsOneWidget);
    expect(find.text('مبيعات الأكياس حسب النوع'), findsNothing);
  });

  testWidgets('the pickers appear only once a custom period is asked for', (tester) async {
    // Arrange
    stub();
    await openTheBoard(tester);

    // Assert — the presets answer «أي فترة؟» on their own to begin with
    expect(find.text('من'), findsNothing);

    // Act
    await tester.tap(find.text('فترة مخصصة'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('من'), findsOneWidget);
    expect(find.text('إلى'), findsOneWidget);
  });

  testWidgets('a refused period reveals the pickers and is shown under one of them', (
    tester,
  ) async {
    // Arrange — the refusal arrives while «هذا الشهر» is still the lit chip, so the two pickers
    // are not on screen. A page that says «صحّح الفترة أعلاه» with nothing correctable above it
    // is a dead end, so the boxes come out with the message.
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
    await openTheBoard(tester);

    // Assert — the 422 is keyed by field precisely so it can be shown where the mistake was
    // made, and the page behind it says what to do rather than repeating the complaint
    expect(find.text('من'), findsOneWidget);
    expect(find.text('إلى'), findsOneWidget);
    expect(find.text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية'), findsOneWidget);
    expect(find.text('صحّح الفترة أعلاه لعرض الإحصائيات'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsNothing);
  });

  testWidgets('anything else the server refuses takes the page, with its own words', (
    tester,
  ) async {
    // Arrange
    stub(failure: const Failure.forbidden(message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء'));

    // Act
    await openTheBoard(tester);

    // Assert
    expect(find.text('ليس لديك صلاحية لتنفيذ هذا الإجراء'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
