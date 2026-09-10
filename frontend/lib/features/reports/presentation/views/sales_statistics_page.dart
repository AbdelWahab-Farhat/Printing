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

/// The two days, and three chips that fill them.
///
/// **The pickers are always on screen, and the presets are shortcuts to them rather than an
/// alternative to them.** They used to hide behind a «فترة مخصصة» chip, which meant the reader
/// could not see which days they were being shown without first working out that a chip was
/// hiding them — and tapping اليوم would then make the boxes disappear again. One control that is
/// always there, and three one-tap ways to fill it, is the same feature with nothing to discover.
///
/// **So there is no «فترة مخصصة» chip.** [StatisticsPeriodPreset.custom] is still the state a
/// hand-picked window is in — it is simply the state where no chip is lit, which is what a person
/// who just used the pickers expects to see.
///
/// **Stateful for one reason: the chip that is lit is not in the Cubit's state.** The period lives
/// *beside* the state, on the Cubit, so moving it changes nothing a `Cubit` would emit — see the
/// note on `SalesStatisticsCubit.preset`. Every change that alters the figures runs a load and
/// repaints anyway; this `setState` is what covers the one that does not.
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
              // `custom` is a state, not a shortcut: it is what «no chip lit» means, and a chip
              // that only ever says «you used the boxes below» is a chip with nothing to do.
              for (final preset in StatisticsPeriodPreset.values)
                if (preset != StatisticsPeriodPreset.custom)
                  ChoiceChip(
                    label: Text(preset.label),
                    selected: cubit.preset == preset,
                    onSelected: (_) => _select(preset),
                  ),
            ],
          ),
          // **Always drawn.** A preset fills these rather than replacing them, so the two days
          // never leave the screen — and the page behind a refusal says «صحّح الفترة أعلاه»,
          // which is only true while there is something above to correct. The 422 is keyed by
          // field precisely so it can be shown under the box it is about; this is what
          // guarantees there is a box.
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
        // **The period is not restated here.** `SalesStatisticsQuery` echoes back the same two
        // day strings it was handed — `from` and `to` are formatted straight off the filters —
        // so the echo never differs from what the pickers above are already showing, and a
        // second copy of «من … إلى …» is a line that can only ever agree with itself.
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
          _FigureRow(
            label: 'سادة',
            value: weight.plainKg,
            dot: scheme.tertiary.withValues(alpha: 0.40),
          ),
          SizedBox(height: 10.h),
          _FigureRow(label: 'مطبوع', value: weight.printedKg, dot: scheme.tertiary),
          SizedBox(height: 10.h),
          // The server's own division, printed rather than recomputed — the question the whole
          // comparison exists to answer, given once here rather than left to a reader dividing
          // two figures on a phone.
          _FigureRow(label: 'نسبة المطبوع', value: weight.printedSharePercent, unit: '٪'),
          if (!weight.isFullyCovered) ...[
            SizedBox(height: 10.h),
            // **«تغطية الوزن» was the label here and nobody could read it.** The figure is the
            // share of the period's *money* that has a weight behind it, and naming it after the
            // coverage rather than after what is covered left a reader guessing at both. At 100
            // it is noise and is not drawn at all.
            _FigureRow(
              label: 'من المبيعات لها وزن',
              value: weight.weightCoveragePercent,
              unit: '٪',
            ),
          ],
          // **Under all of them, not between two of them.** The strip sat below الإجمالي, where
          // it cut the four figures into one and three and broke the column they read down. At
          // the foot of the block it is the picture of the نسبة directly above it, drawn in the
          // two colours whose dots the reader has already passed.
          SizedBox(height: 14.h),
          _WeightMix(weight: weight),
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
/// **Two segments with a gap, not one pill with a seam.** A single animated track was tried here
/// and taken out again: at eight logical pixels the join between two tones of one hue reads as a
/// smudge rather than a boundary, and a bar that grows on every load draws the eye to the one
/// thing on the block that is already said twice in the figures above it. The gap does the work the
/// animation was reaching for, and does it while standing still.
///
/// Drawn by hand rather than by the chart library: a one-dimensional strip is two boxes in a row,
/// and there is no axis, scale or touch layer here for `fl_chart` to be carrying — it earns its
/// place on the type breakdown below, where the comparison is between six things rather than two.
/// The two colours are the ones the rows above wear, which is what ties a segment to its figure.
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
          _PressFigure(
            icon: AppIcons.printedProduct,
            label: 'عدد الأكياس المطبوعة',
            value: pieces.countLabel,
            unit: 'قطعة',
          ),
          SizedBox(height: 10.h),
          // The same bags on the scale, so the count is never read as a weight — and at the
          // count's own size, because the two are one pair and a smaller weight read as a
          // footnote to a figure it is the equal of.
          _PressFigure(label: 'وزنها', value: groupedDecimal(pieces.weightKg), unit: 'كجم'),
        ],
      ),
    );
  }
}

/// One figure of the press's pair, at the size the pair is read at.
class _PressFigure extends StatelessWidget {
  const _PressFigure({required this.label, required this.value, required this.unit, this.icon});

  final String label;
  final String value;
  final String unit;

  /// Drawn on the row that carries it; the other row keeps its width so the labels line up.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        if (icon case final glyph?)
          Icon(glyph, size: 18.sp, color: scheme.onSurfaceVariant)
        else
          SizedBox(width: 18.sp),
        SizedBox(width: 8.w),
        Text(label, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        // A busy month is a long number, and `titleLarge` beside a label and an icon runs out of
        // phone before it runs out of digits — scaled down rather than overflowed, because a
        // clipped count is a wrong count. `Expanded` and no spacer, so it is scaled down at the
        // end of the row rather than centred in the half of it a spacer left over.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              value,
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Text(unit, style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// مبيعات الأكياس حسب النوع — one row per material, heaviest first as the server sorts it.
///
/// **A table rather than a picture.** The reader of this block came to read figures, and five
/// materials as five slices answer «كم نصيب كل نوع؟» at the cost of the four numbers each one is
/// actually carrying — weight, the سادة/مطبوع split, and what it earned. The شارة under
/// «السادة مقابل المطبوع» above already draws the one proportion on this board worth seeing
/// rather than reading.
///
/// **The units are stated once, in the heading row.** Twenty figures with a unit apiece is
/// twenty pieces of ink saying five things, and the four number columns are narrow enough that a
/// «كجم» beside each would take the width the names need.
///
/// **A row with real value and no weight is correct, not a bug.** أكياس ورقية عادية is stocked by
/// the piece, so it earns money and weighs nothing; its `0.000` is drawn as the figure it is
/// rather than as «—», because its value is part of the total above and hiding the row would make
/// the table stop adding up. The same holds at the other end: a material that earned nothing
/// keeps its row for the weight it took off the shelf.
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
                  _HeadCell(label: 'كجم', numeric: true),
                  _HeadCell(label: 'سادة', numeric: true),
                  _HeadCell(label: 'مطبوع', numeric: true),
                  _HeadCell(label: 'د.ل', numeric: true),
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

/// One heading, sitting on the same edge of the cell as the column it names.
///
/// A figure column stacks on its right edge, so its heading does too — a label parked on the far
/// side of its own cell reads as the heading of the column beside it, which is the one thing a
/// table of five columns must never do. The name column keeps the start edge, where the names
/// themselves begin.
class _HeadCell extends StatelessWidget {
  const _HeadCell({required this.label, this.numeric = false});

  final String label;

  /// Whether this heading tops a column of figures rather than the names.
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: numeric ? _figureGap : 4.w, vertical: 8.h),
      child: Align(
        alignment: numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.outline),
        ),
      ),
    );
  }
}

/// The air on either side of a figure, so four narrow columns stay four columns.
///
/// Read at the top of the file rather than typed at each of the eight call sites: the heading and
/// the figures under it have to be inset by the same amount or they stop being one column.
double get _figureGap => 6.w;

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
      padding: EdgeInsets.symmetric(horizontal: _figureGap, vertical: 8.h),
      child: Align(
        // The right edge, not the end edge. These are Latin numbers: stacking them on the right
        // puts the units under the units and the point under the point, whichever side of the
        // screen the column landed on. `centerEnd` resolves to the *left* in Arabic, which is
        // what left every figure column ragged down the edge the eye reads it by.
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
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
        // `Expanded`, and no `Spacer` before it: a bare `Flexible` is `flex: 1` like the spacer
        // was, so the two of them split the free space down the middle and every figure on the
        // block stopped halfway across its own row.
        Expanded(
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
