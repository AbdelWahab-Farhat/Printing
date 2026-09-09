import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/reports/models/sales_statistics.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/sales_statistics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إحصائيات المبيعات — what was sold, and how much of it left the warehouse.
///
/// **Three units on one page, and that is what the layout is organised around.** د.ل is what the
/// shop earned, كجم is what the shelves lost, قطعة is what the press ran. They answer three
/// different questions about the same period, so they are three blocks rather than one wall of
/// figures — and every number carries its unit, because a reader landing halfway down the page
/// has nothing else to tell them which of the three they are looking at.
///
/// **عدد الأكياس المطبوعة is kept apart from the weights it sits beside.** It is the same bags on
/// a different measure, and it is the figure the printing engineer's share will one day be
/// computed from; folded in with the kilograms it would read as a heavier version of them.
///
/// **Nothing is derived here.** The server folds every figure out of one grouped row set, so the
/// type table adds up to the totals above it — but it is the *server* that guarantees that, and
/// this screen prints each figure from the key that carries it. نسبة المطبوع above all: it is a
/// division the server already did, and doing it again on two rounded weights is how a screen
/// ends up disagreeing with itself by a tenth.
///
/// **The type labels are rendered exactly as they arrive**, trailing dashes and all — several
/// shelves were auto-created from product names and read «أكياس شفافه -». Tidying them here would
/// hide a naming problem that also shows on the inventory screens; the fix belongs in the data.
class SalesStatisticsPage extends StatelessWidget {
  const SalesStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SalesStatisticsCubit>(
      // Screen-scoped and closed with the screen; `..load()` so the first frame is already asking
      // about this month rather than waiting to be told which month.
      create: (_) => sl<SalesStatisticsCubit>()..load(),
      child: const _SalesStatisticsView(),
    );
  }
}

class _SalesStatisticsView extends StatelessWidget {
  const _SalesStatisticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إحصائيات المبيعات')),
      body: SafeArea(
        child: BlocBuilder<SalesStatisticsCubit, SalesStatisticsState>(
          builder: (context, state) {
            final cubit = context.read<SalesStatisticsCubit>();

            return Column(
              children: [
                _PeriodSelector(state: state),
                Expanded(
                  child: switch (state) {
                    SalesStatisticsInitial() || SalesStatisticsLoading() => const _BoardSkeleton(),
                    // A refused date is already painted under the picker it belongs to; a page of
                    // «البيانات المدخلة غير صحيحة» over it would say the same thing twice and
                    // less usefully.
                    SalesStatisticsFailure() when !state.hasUnrenderedErrors =>
                      const _CorrectThePeriod(),
                    SalesStatisticsFailure(:final failure) => _FailureView(
                      message: failure.message,
                      onRetry: cubit.load,
                    ),
                    SalesStatisticsLoaded(:final statistics) => RefreshIndicator(
                      onRefresh: cubit.refresh,
                      child: _Board(statistics: statistics),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The four chips, and the two pickers they hide behind «فترة مخصصة».
///
/// **Stateful for one reason: the chip that is lit is not in the Cubit's state.** The period lives
/// *beside* the state, on the Cubit, so a preset that only reveals the pickers changes nothing a
/// `Cubit` would emit — see the note on `SalesStatisticsCubit.preset`. Every other change runs a
/// load and repaints anyway; this `setState` is what covers the two that do not.
class _PeriodSelector extends StatefulWidget {
  const _PeriodSelector({required this.state});

  final SalesStatisticsState state;

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  /// Moves one end of the window and re-reads.
  ///
  /// The same `showDatePicker` the الأرباح والخسائر screen uses, and the day is formatted the
  /// same way: a plain `YYYY-MM-DD`, which is the only thing the API filters on.
  Future<void> _pick({required bool isFrom}) async {
    final cubit = context.read<SalesStatisticsCubit>();
    final initial = DateTime.tryParse(isFrom ? cubit.from : cubit.to);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      // A report is asked for within a working lifetime, not within a century.
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked == null) return;

    final value =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    await cubit.setRange(from: isFrom ? value : null, to: isFrom ? null : value);

    if (mounted) setState(() {});
  }

  Future<void> _select(StatisticsPeriodPreset preset) async {
    await context.read<SalesStatisticsCubit>().selectPreset(preset);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SalesStatisticsCubit>();
    final state = widget.state;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final preset in StatisticsPeriodPreset.values)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: cubit.preset == preset,
                  onSelected: (_) => _select(preset),
                ),
            ],
          ),
          // The pickers are the «فترة مخصصة» chip's own contents, so they appear with it rather
          // than sitting above four chips that would then have nothing to do.
          //
          // **And they appear whenever the period itself was refused**, whichever chip is lit. A
          // preset cannot produce a 422 today — it always computes a valid `from` on or before a
          // valid `to` — but the page behind it says «صحّح الفترة أعلاه», and a screen that says
          // that while showing nothing correctable is a dead end. The message is keyed by field
          // precisely so it can be shown under the box it is about; this is what guarantees there
          // is a box.
          if (cubit.preset == StatisticsPeriodPreset.custom ||
              state.fromError != null ||
              state.toError != null) ...[
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: AppIcons.today,
                    label: 'من',
                    value: cubit.from,
                    // The server's own sentence, under the box it is about — which is the whole
                    // reason a 422 keys its messages by field.
                    error: state.fromError,
                    onTap: () => _pick(isFrom: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _PickerTile(
                    icon: AppIcons.month,
                    label: 'إلى',
                    value: cubit.to,
                    error: state.toError,
                    onTap: () => _pick(isFrom: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The figures, in the order they are read.
class _Board extends StatelessWidget {
  const _Board({required this.statistics});

  final SalesStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        // **The server's window, not the one the app sent.** The two differ whenever a preset was
        // computed from the phone's clock and the server's day begins somewhere else, and this is
        // the line that says which days the figures below are actually about.
        Text(
          statistics.period.label,
          style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: 12.h),

        if (!statistics.hasCountedOrders)
          const _EmptyPeriod()
        else ...[
          _SalesValueBlock(statistics: statistics),
          SizedBox(height: 20.h),

          _WeightBlock(statistics: statistics),

          // The break in the page. Everything above is dinars and kilograms of the same goods;
          // what follows counts the same bags a third way, and the gap plus the rule are what say
          // so before a word is read.
          SizedBox(height: 24.h),
          const Divider(height: 1),
          SizedBox(height: 20.h),

          _PrintedPiecesBlock(pieces: statistics.printedPieces),
          SizedBox(height: 24.h),

          _ByTypeBlock(rows: statistics.byType),
        ],
      ],
    );
  }
}

/// قيمة المبيعات — the period at the till, split سادة/مطبوع.
class _SalesValueBlock extends StatelessWidget {
  const _SalesValueBlock({required this.statistics});

  final SalesStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final value = statistics.salesValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `IntrinsicHeight` so the three are one band rather than three boxes of whatever height
        // their own number happened to need: a figure long enough to be scaled down would
        // otherwise leave its tile shorter than the two beside it. `stretch` alone cannot do it
        // inside a `ListView`, where the height is unbounded.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _TotalTile(label: 'الإجمالي', value: value.total, unit: 'د.ل')),
              SizedBox(width: 8.w),
              Expanded(child: _TotalTile(label: 'سادة', value: value.plain, unit: 'د.ل')),
              SizedBox(width: 8.w),
              Expanded(child: _TotalTile(label: 'مطبوع', value: value.printed, unit: 'د.ل')),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        // The honest denominator: an all-zero board could mean the shop sold nothing or that the
        // period was typed wrong, and this is the figure that tells the two apart.
        Text(
          'على ${statistics.ordersCounted.grouped} طلبية',
          style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// السادة مقابل المطبوع — the same period on the scale.
class _WeightBlock extends StatelessWidget {
  const _WeightBlock({required this.statistics});

  final SalesStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final weight = statistics.weightComparison;
    final scheme = context.colorScheme;

    return _Section(
      title: 'السادة مقابل المطبوع',
      unit: 'كجم',
      child: Column(
        children: [
          _FigureRow(label: 'الإجمالي', value: weight.totalKg, emphasised: true),
          SizedBox(height: 10.h),
          _FigureRow(label: 'سادة', value: weight.plainKg, dot: scheme.tertiary.withValues(alpha: 0.45)),
          SizedBox(height: 10.h),
          _FigureRow(label: 'مطبوع', value: weight.printedKg, dot: scheme.tertiary),
          SizedBox(height: 12.h),
          _WeightMix(weight: weight),
          SizedBox(height: 12.h),
          // The server's own division, printed rather than recomputed — the question the whole
          // comparison exists to answer, given once here rather than left to a reader dividing
          // two figures on a phone.
          _FigureRow(label: 'نسبة المطبوع', value: weight.printedSharePercent, unit: '٪'),
          if (!weight.isFullyCovered) ...[
            SizedBox(height: 10.h),
            _FigureRow(label: 'تغطية الوزن', value: weight.weightCoveragePercent, unit: '٪'),
            SizedBox(height: 8.h),
            // Without this the kilograms look wrong beside their own dinars, and no reader can
            // tell «باعوا قليلاً» from «ما وزنوهش». At 100 it is noise, so it is not drawn.
            Text(
              'جزء من المبيعات بلا وزن — أكياس تُعَدّ بالقطعة أو عمل لدى مورّد.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// The سادة/مطبوع split as one strip the width of the block.
///
/// Proportions of the two weights against each other, which is the same thing as against their
/// total — the server folds the total up from exactly these two, so unlike the cost strip on
/// الأرباح والخسائر there is no third table here for them to disagree with.
///
/// Drawn by hand rather than by the chart library: a one-dimensional strip is two boxes in a row,
/// and there is no axis, scale or touch layer for `fl_chart` to be carrying. The two colours are
/// the ones the rows above wear, which is what ties a segment to its figure.
class _WeightMix extends StatelessWidget {
  const _WeightMix({required this.weight});

  final WeightComparison weight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final parts = [
      weight.plainKg,
      weight.printedKg,
    ].map((value) => num.tryParse(value)?.toDouble() ?? 0).toList();
    final tones = [scheme.tertiary.withValues(alpha: 0.45), scheme.tertiary];

    // A period nothing was weighed in is a row of zeros, and a strip of nothing is worse than no
    // strip: an empty bar reads as a bar that failed to draw.
    if (parts.every((part) => part <= 0)) return const SizedBox.shrink();

    return SizedBox(
      height: 8.h,
      child: Row(
        // A `DecoratedBox` with no child has no height of its own, and a `Row` centres its
        // children by default — which lays every segment out at zero and leaves a strip that is
        // silently not there while every figure around it still reads correctly.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < parts.length; index++)
            if (parts[index] > 0) ...[
              // The gap between two segments is what keeps a pale one from bleeding into the
              // segment beside it; it is surface, not a colour of its own.
              if (index > 0) SizedBox(width: 2.w),
              Expanded(
                key: ValueKey('weight-mix-$index'),
                flex: (parts[index] * 1000).round(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tones[index],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/// عدد الأكياس المطبوعة — the press's own output, counted.
///
/// **Its own block, in its own unit, below a rule.** It is the same bags the مطبوع weight above
/// describes, and the whole reason it is separated is that it will one day be multiplied by a
/// rate: a count folded in among kilograms is a count somebody eventually reads as kilograms.
class _PrintedPiecesBlock extends StatelessWidget {
  const _PrintedPiecesBlock({required this.pieces});

  final PrintedPieces pieces;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.printedProduct, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Text(
                'عدد الأكياس المطبوعة',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              // A busy month is a long number, and `titleLarge` beside a label and an icon runs
              // out of phone before it runs out of digits — scaled down rather than overflowed,
              // because a clipped count is a wrong count.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    pieces.countLabel,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'قطعة',
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // The same bags on the scale, so the count is never read as a weight.
          _FigureRow(label: 'وزنها', value: pieces.weightKg, unit: 'كجم'),
        ],
      ),
    );
  }
}

/// مبيعات الأكياس حسب النوع — one row per material, heaviest first as the server sorts it.
///
/// **A row with real value and no weight is correct, not a bug.** أكياس ورقية عادية is stocked by
/// the piece, so it earns money and weighs nothing; its `0.000` is drawn as the figure it is
/// rather than as «—», because its value is part of the total above and hiding the row would make
/// the table stop adding up.
class _ByTypeBlock extends StatelessWidget {
  const _ByTypeBlock({required this.rows});

  final List<BagTypeRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مبيعات الأكياس حسب النوع',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Table(
            // The name takes what is left; the four figures take exactly what they need, so a
            // long material name shortens itself rather than squeezing the numbers it qualifies.
            columnWidths: const {
              0: FlexColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
              3: IntrinsicColumnWidth(),
              4: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // The units are stated once, here, rather than beside twenty figures.
              const TableRow(
                children: [
                  _HeadCell(label: 'النوع'),
                  _HeadCell(label: 'كجم'),
                  _HeadCell(label: 'سادة'),
                  _HeadCell(label: 'مطبوع'),
                  _HeadCell(label: 'د.ل'),
                ],
              ),
              for (final row in rows)
                TableRow(
                  children: [
                    _TypeCell(label: row.type),
                    _NumberCell(value: row.weightKg, emphasised: true),
                    _NumberCell(value: row.plainKg),
                    _NumberCell(value: row.printedKg),
                    _NumberCell(value: row.value),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.outline),
      ),
    );
  }
}

class _TypeCell extends StatelessWidget {
  const _TypeCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      child: Text(
        // Rendered exactly as it arrived — trailing dash included. See the class note.
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One figure in the table, at body size rather than caption size.
class _NumberCell extends StatelessWidget {
  const _NumberCell({required this.value, this.emphasised = false});

  final String value;

  /// The column the table is sorted by, drawn in the ink the eye lands on first.
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            groupedDecimal(value),
            // A Latin run: `12,450` renders as `450,12` without this, which is a different number
            // rather than a rendering glitch.
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
              color: emphasised ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the three totals: what it is, and what it came to.
///
/// The unit is inside each tile rather than once above the row — three tiles side by side have no
/// heading between them to hang a single «د.ل» off, and a bare `13,819` at the top of a money
/// screen is the one number a reader should never have to assume the unit of.
class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          SizedBox(height: 6.h),
          // A third of a phone is not much room for `13,819`, and a figure that overflows its tile
          // is worse than a figure drawn a point smaller.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  groupedDecimal(value),
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  unit,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A block of figures under one heading, with the unit stated once beside the heading.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.unit, required this.child});

  final String title;
  final String unit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const Spacer(),
            Text(unit, style: context.textTheme.bodySmall?.copyWith(color: scheme.outline)),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// One figure: what it is on one side, what it came to on the other.
///
/// [value] arrives as the server's decimal string and is grouped by string surgery — never
/// parsed. `'0.000'` is a real answer here, so a zero row is drawn like any other rather than
/// hidden: a weight of nothing is a fact about the period.
class _FigureRow extends StatelessWidget {
  const _FigureRow({
    required this.label,
    required this.value,
    this.unit,
    this.dot,
    this.emphasised = false,
  });

  final String label;
  final String value;

  /// Stated per row only where the block's heading does not already carry it — the percentages
  /// under a كجم heading, and the weight under a قطعة one.
  final String? unit;

  /// The colour this row wears in [_WeightMix], if it is drawn there.
  final Color? dot;

  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        if (dot case final tone?) ...[_Dot(tone: tone), SizedBox(width: 8.w)],
        Text(label, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              groupedDecimal(value),
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        if (unit case final label?) ...[
          SizedBox(width: 6.w),
          Text(label, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// The mark itself, at the size it is legible at rather than the size it is decorative at.
class _Dot extends StatelessWidget {
  const _Dot({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
    );
  }
}

/// A period in which nothing was delivered or settled.
///
/// **Said in words rather than painted as five blocks of zeroes.** Zero is not a failure and not
/// an empty screen — it is an answer, and four zeroed tiles under a chart of nothing is an answer
/// nobody can distinguish from a screen that failed to load.
class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
      child: Column(
        children: [
          Icon(
            AppIcons.report,
            size: 40.sp,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا مبيعات أكياس في هذه الفترة',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The shape of the board, drawn before its figures arrive.
///
/// A skeleton rather than a spinner: the layout does not jump when the numbers land, and the wait
/// is spent looking at where they will be.
class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 68.h, radius: 16.r)),
            SizedBox(width: 8.w),
            Expanded(child: _SkeletonBox(height: 68.h, radius: 16.r)),
            SizedBox(width: 8.w),
            Expanded(child: _SkeletonBox(height: 68.h, radius: 16.r)),
          ],
        ),
        SizedBox(height: 24.h),
        _SkeletonBox(height: 160.h, radius: 16.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 72.h, radius: 20.r),
        SizedBox(height: 24.h),
        _SkeletonBox(height: 140.h, radius: 16.r),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// What is left on the page once the server's complaint is already under a picker.
class _CorrectThePeriod extends StatelessWidget {
  const _CorrectThePeriod();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          'صحّح الفترة أعلاه لعرض الإحصائيات',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              // The server's own Arabic, not a generic apology: it usually says what to do.
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row that opens a date picker and shows what came back.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.error,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: error == null ? scheme.outlineVariant.withValues(alpha: 0.7) : scheme.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          value,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error case final message?) ...[
          SizedBox(height: 4.h),
          Text(message, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
      ],
    );
  }
}
