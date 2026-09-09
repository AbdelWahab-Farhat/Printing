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
          SizedBox(height: 12.h),
          _SplitBar(plain: weight.plainKg, printed: weight.printedKg),
          SizedBox(height: 12.h),
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
            SizedBox(height: 8.h),
            // Without this the kilograms look wrong beside their own dinars, and no reader can
            // tell «باعوا قليلاً» from «ما وزنوهش».
            Text(
              'الباقي أكياس تُعَدّ بالقطعة أو عمل لدى مورّد: تدخل في المال، ولا وزن لها.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

/// The سادة/مطبوع split, as one pill the width of the block.
///
/// **One track cut in two, not two boxes set beside each other.** The earlier version drew a
/// segment per part with a gap between them, which is right for الأرباح والخسائر — three costs
/// that come from different tables and are only *displayed* together. These two are one
/// measurement split once, and a seam down the middle of a single rounded track is what says so.
/// Rounded on the outside only: the ends belong to the whole, the join does not.
///
/// **It grows into place.** A bar that is simply present when the figures land reads as a static
/// picture; one that runs out to its share in under half a second reads as a proportion being
/// measured, which is what it is. `TweenAnimationBuilder` re-runs the tween whenever the share
/// changes, so moving the period animates from the old split to the new one rather than cutting.
///
/// Drawn by hand rather than by the chart library: there is no axis, scale or touch layer here
/// for `fl_chart` to be carrying. The two colours are the ones the rows beside it wear, which is
/// what ties a length to its figure — the bar itself is never asked to carry a label.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.plain, required this.printed, this.height});

  final String plain;
  final String printed;

  /// Slimmer inside a type card than under the totals, where it is the block's own summary.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final plainKg = num.tryParse(plain)?.toDouble() ?? 0;
    final printedKg = num.tryParse(printed)?.toDouble() ?? 0;
    final total = plainKg + printedKg;

    // Nothing was weighed. An empty track reads as a bar that failed to draw, which is worse than
    // no bar at all — and the figures around it already say the period weighs nothing.
    if (total <= 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height ?? 12.h,
        child: Stack(
          children: [
            // The whole, in سادة's ink: what is not printed is plain, so the track needs no
            // segment of its own and the two can never round to more than their container.
            Positioned.fill(
              child: ColoredBox(color: scheme.tertiary.withValues(alpha: 0.40)),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: printedKg / total),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, share, _) => FractionallySizedBox(
                // Directional, so the fill runs from the side the page is read from.
                alignment: AlignmentDirectional.centerStart,
                widthFactor: share,
                child: ColoredBox(color: scheme.tertiary),
              ),
            ),
          ],
        ),
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

/// مبيعات الأكياس حسب النوع — one card per material, heaviest first as the server sorts it.
///
/// **This was a five-column table and it did not survive a phone.** «النوع · كجم · سادة · مطبوع ·
/// د.ل» across 430 logical pixels left «أكياس يد خارجية -» wrapped over two lines beside four
/// figures each scaled down until they were smaller than the label above them, and a reader had
/// to carry a column heading in their head all the way down the page to know which number was
/// which. Six materials of that is a grid to be decoded rather than a list to be read.
///
/// **So each material is a card that says its own name for every figure it carries.** The weight
/// is the number the eye lands on, because it is what the list is ordered by; the split runs
/// underneath as a bar with its two figures named beneath it; the money and the piece count sit
/// on the closing line. Nothing is a column, so nothing depends on a heading three screens up.
///
/// **A row with real value and no weight is correct, not a bug.** أكياس ورقية عادية is stocked by
/// the piece, so it earns money and weighs nothing. Its card keeps its money and its pieces and
/// simply has no bar to draw — the value is part of the total above, and dropping the card would
/// make the list stop adding up to it.
class _ByTypeBlock extends StatelessWidget {
  const _ByTypeBlock({required this.rows});

  final List<BagTypeRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مبيعات الأكياس حسب النوع',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        for (final row in rows) ...[
          _TypeCard(row: row),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }
}

/// One material: what it weighed, how that split, and what it earned.
class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.row});

  final BagTypeRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // Rendered exactly as it arrived — trailing dash included. See the page note.
                  row.type,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // The number the list is sorted by, so it is the one drawn largest.
              _Amount(value: row.weightKg, unit: 'كجم', emphasised: true),
            ],
          ),
          if (row.hasWeight) ...[
            SizedBox(height: 10.h),
            _SplitBar(plain: row.plainKg, printed: row.printedKg, height: 8.h),
            SizedBox(height: 8.h),
            Row(
              children: [
                _Dot(tone: scheme.tertiary.withValues(alpha: 0.40)),
                SizedBox(width: 6.w),
                _SplitFigure(label: 'سادة', value: row.plainKg),
                SizedBox(width: 14.w),
                _Dot(tone: scheme.tertiary),
                SizedBox(width: 6.w),
                _SplitFigure(label: 'مطبوع', value: row.printedKg),
              ],
            ),
          ],
          SizedBox(height: 10.h),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          SizedBox(height: 10.h),
          Row(
            children: [
              if (row.pieces > 0) ...[
                Text(
                  'مطبوع',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(width: 6.w),
                _Amount(value: row.pieces.grouped, unit: 'قطعة'),
              ],
              const Spacer(),
              _Amount(value: row.value, unit: 'د.ل'),
            ],
          ),
        ],
      ),
    );
  }
}

/// One half of a split, named beside its own figure rather than under a column heading.
class _SplitFigure extends StatelessWidget {
  const _SplitFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(width: 6.w),
            Text(
              groupedDecimal(value),
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A figure and the unit it is in, kept together so neither can be read without the other.
class _Amount extends StatelessWidget {
  const _Amount({required this.value, required this.unit, this.emphasised = false});

  /// Already grouped where it is a count; grouped here where it is a decimal string.
  final String value;
  final String unit;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              groupedDecimal(value),
              // A Latin run: `12,450` renders as `450,12` without this, which is a different
              // number rather than a rendering glitch.
              textDirection: TextDirection.ltr,
              style: (emphasised ? text.titleMedium : text.bodyMedium)?.copyWith(
                fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(width: 4.w),
            Text(unit, style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
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
