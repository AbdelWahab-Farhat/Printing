import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/sales_statistics_cubit.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';
import 'package:dayaa/features/reports/usecases/get_sales_statistics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The ViewModel behind إحصائيات المبيعات.
///
/// **The presets are the load-bearing part** — they are the one thing this Cubit computes rather
/// than reads, and the week starting on Saturday is the piece of it a test has to hold down: it
/// is a fact about Libya that Dart's own calendar disagrees with, and nothing else in the app
/// would notice if it silently became Monday.
///
/// Arrange - Act - Assert throughout.
class _MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late _MockReportRepository reports;
  late SalesStatisticsCubit cubit;

  const statistics = SalesStatistics(
    period: StatisticsPeriod(from: '2026-08-01', to: '2026-09-08'),
    salesValue: SalesValue(plain: '5626.40', printed: '8193.00', total: '13819.40'),
    byType: [],
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

  void stub({SalesStatistics? board, Failure? failure}) {
    when(
      () => reports.salesStatistics(from: any(named: 'from'), to: any(named: 'to')),
    ).thenAnswer((_) async => failure != null ? Left(failure) : Right(board ?? statistics));
  }

  setUp(() {
    reports = _MockReportRepository();
    stub();
    cubit = SalesStatisticsCubit(getStatistics: GetSalesStatistics(reports));
  });

  tearDown(() => cubit.close());

  group('the default window', () {
    test('opens on this month so far, matching الأرباح والخسائر', () {
      // Arrange — a fresh Cubit, before anything is asked of it
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');

      // Act - the constructor

      // Assert
      expect(cubit.preset, StatisticsPeriodPreset.month);
      expect(cubit.from, '${now.year}-$month-01');
      expect(cubit.to, '${now.year}-$month-$day');
    });
  });

  group('the presets', () {
    test('اليوم is the one day at both ends', () {
      // Arrange — a Wednesday
      final now = DateTime(2026, 9, 9);

      // Act
      final (from, to) = StatisticsPeriodPreset.today.window(now);

      // Assert
      expect(from, '2026-09-09');
      expect(to, '2026-09-09');
    });

    test('هذا الشهر runs from the first of the month to today', () {
      // Arrange
      final now = DateTime(2026, 9, 9);

      // Act
      final (from, to) = StatisticsPeriodPreset.month.window(now);

      // Assert
      expect(from, '2026-09-01');
      expect(to, '2026-09-09');
    });

    test('the week starts on Saturday, because the shop is in Libya', () {
      // Arrange — Wednesday 2026-09-09; the Saturday before it is 2026-09-05
      final now = DateTime(2026, 9, 9);

      // Act
      final (from, to) = StatisticsPeriodPreset.week.window(now);

      // Assert
      expect(from, '2026-09-05');
      expect(to, '2026-09-09');
    });

    test('a Saturday is its own first day rather than a week back', () {
      // Arrange — the off-by-seven this arithmetic invites
      final now = DateTime(2026, 9, 5);

      // Act
      final (from, to) = StatisticsPeriodPreset.week.window(now);

      // Assert
      expect(from, '2026-09-05');
      expect(to, '2026-09-05');
    });

    test('a Friday is the sixth day of its week, not the first of the next', () {
      // Arrange — Friday 2026-09-11 belongs to the week that began Saturday 2026-09-05
      final now = DateTime(2026, 9, 11);

      // Act
      final (from, _) = StatisticsPeriodPreset.week.window(now);

      // Assert
      expect(from, '2026-09-05');
    });

    test('a week straddling a month boundary reaches back into the month before', () {
      // Arrange — Tuesday 2026-10-06; its Saturday is 2026-10-03… so take one that crosses:
      // Thursday 2026-10-01 belongs to the week that began Saturday 2026-09-26
      final now = DateTime(2026, 10);

      // Act
      final (from, to) = StatisticsPeriodPreset.week.window(now);

      // Assert
      expect(from, '2026-09-26');
      expect(to, '2026-10-01');
    });
  });

  group('selectPreset', () {
    test('overwrites both ends and re-reads', () async {
      // Arrange
      await cubit.load();

      // Act
      await cubit.selectPreset(StatisticsPeriodPreset.today, now: DateTime(2026, 9, 9));

      // Assert
      expect(cubit.preset, StatisticsPeriodPreset.today);
      expect(cubit.from, '2026-09-09');
      expect(cubit.to, '2026-09-09');
    });

    test('فترة مخصصة computes no window and asks for nothing', () async {
      // Arrange
      await cubit.load();
      final from = cubit.from;
      final to = cubit.to;
      clearInteractions(reports);

      // Act — it only reveals the pickers
      await cubit.selectPreset(StatisticsPeriodPreset.custom);

      // Assert
      expect(cubit.preset, StatisticsPeriodPreset.custom);
      expect(cubit.from, from);
      expect(cubit.to, to);
      verifyNever(() => reports.salesStatistics(from: any(named: 'from'), to: any(named: 'to')));
    });

    test('re-tapping the lit chip does not ask again', () async {
      // Arrange
      await cubit.selectPreset(StatisticsPeriodPreset.today, now: DateTime(2026, 9, 9));
      clearInteractions(reports);

      // Act
      await cubit.selectPreset(StatisticsPeriodPreset.today, now: DateTime(2026, 9, 9));

      // Assert
      verifyNever(() => reports.salesStatistics(from: any(named: 'from'), to: any(named: 'to')));
    });
  });

  group('setRange', () {
    test('moves one end and leaves the other where it was', () async {
      // Arrange
      await cubit.load();
      final to = cubit.to;

      // Act
      await cubit.setRange(from: '2026-01-01');

      // Assert
      expect(cubit.from, '2026-01-01');
      expect(cubit.to, to);
    });

    test('a hand-picked window moves the chip to فترة مخصصة', () async {
      // Arrange
      await cubit.load();

      // Act
      await cubit.setRange(from: '2026-01-01', to: '2026-01-31');

      // Assert
      expect(cubit.preset, StatisticsPeriodPreset.custom);
    });

    test('does not re-fetch when neither end moved', () async {
      // Arrange
      await cubit.load();
      clearInteractions(reports);

      // Act — re-picking the day already showing
      await cubit.setRange(from: cubit.from, to: cubit.to);

      // Assert
      verifyNever(() => reports.salesStatistics(from: any(named: 'from'), to: any(named: 'to')));
      // …but it is still a window somebody drew by hand
      expect(cubit.preset, StatisticsPeriodPreset.custom);
    });
  });

  group('loading', () {
    test('emits loading and then the board', () async {
      // Arrange — the skeleton has to take the page before the figures land, or the old month's
      // numbers sit under the new month's dates while the request runs.
      //
      // `expectLater` rather than a list a listener fills: stream events are delivered in a later
      // microtask than the one `load()` returns in, so a list read straight after the await is
      // read a beat too early and holds only the first of the two.
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const SalesStatisticsState.loading(),
          const SalesStatisticsState.loaded(statistics),
        ]),
      );

      // Act
      await cubit.load();

      // Assert
      await expectation;
    });

    test('a failure becomes a failure state', () async {
      // Arrange
      stub(failure: const Failure.server(message: 'غير مصرّح'));

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state, isA<SalesStatisticsFailure>());
    });

    test('a 422 leaves both ends of the period on the Cubit', () async {
      // Arrange — a period the user can no longer see is a period they cannot correct
      stub(
        failure: const Failure.server(
          message: 'البيانات المدخلة غير صحيحة',
          fieldErrors: {
            'to': ['تاريخ النهاية يجب أن يكون بعد تاريخ البداية'],
          },
        ),
      );

      // Act
      await cubit.setRange(from: '2026-03-31', to: '2026-03-01');

      // Assert
      expect(cubit.from, '2026-03-31');
      expect(cubit.to, '2026-03-01');
      expect(cubit.state.toError, 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      expect(cubit.state.hasUnrenderedErrors, isFalse);
    });
  });

  group('refresh', () {
    test('a failed refresh keeps the figures already on screen', () async {
      // Arrange
      await cubit.load();
      stub(failure: const Failure.server(message: 'انقطع الاتصال'));

      // Act
      await cubit.refresh();

      // Assert — real figures are not replaced by an error page
      expect(cubit.state, const SalesStatisticsState.loaded(statistics));
    });

    test('a refresh with nothing loaded yet is a first load', () async {
      // Arrange — straight from initial

      // Act
      await cubit.refresh();

      // Assert
      expect(cubit.state, const SalesStatisticsState.loaded(statistics));
    });
  });
}
