import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الأرباح والخسائر — the shop's period read in one screen.
///
/// **The chain is read downwards and it is one chain: الإيراد ← الربح.** Everything in
/// it belongs to the same arithmetic, in the same column, so a reader can follow it without
/// being told how.
///
/// **تكلفة البضاعة المباعة is printed in full — all four figures, none of them added up here.**
/// The three parts are summed from the order *lines* and the total from a cached column on the
/// orders themselves, two different tables with two different scopes, so they are allowed to
/// disagree and the block says so in a line underneath rather than quietly reconciling them.
/// الربح الإجمالي below is still the server's own number, revenue *minus* that cost — never the
/// revenue drawn a second time.
///
/// **Nor is anything said above the figures.** The pickers name the period, and the rule about
/// which orders are counted was a paragraph nobody was asking for.
///
/// **[_CashCollected] is deliberately not in it** — it is separated by a divider
/// and its own words, because the money that came in over these days has nothing to do with the
/// orders above: it is every payment in the business whose day fell inside the window, whichever
/// order it was against and whatever stage that order is at. Pairing it with a cost would imply
/// a cash-basis margin this business does not compute — the materials were already paid for
/// through purchase orders — so it is never subtracted from anything and never sits in the same
/// column.
///
/// **One chart, and it draws the one thing the figures do not say: a share.** There is no series
/// behind any of this — every figure is a period total — so a bar per total would be four
/// numbers redrawn. [_RevenueSplit] instead divides the revenue into what it cost and what was
/// left, and puts هامش الربح in the middle of it: a percent that appears nowhere else on the
/// screen and cannot be read off the amounts at a glance.
///
/// **A losing period is not a donut.** A negative arc is not a shape, and «-60%» in the middle of
/// a ring is a figure that invites the wrong reading — so [_RevenueAgainstCost] takes over and
/// draws the two amounts side by side, which is the whole story of a period that spent more than
/// it earned. A period that earned nothing at all is not charted either: there is no revenue to
/// divide, and the rows underneath say the period plainly enough on their own.
class ProfitAndLossPage extends StatelessWidget {
  const ProfitAndLossPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfitAndLossCubit>(
      // Screen-scoped and closed with the screen; `..load()` so the first frame is already
      // asking about this month rather than waiting to be told which month.
      create: (_) => sl<ProfitAndLossCubit>()..load(),
      child: const _ProfitAndLossView(),
    );
  }
}

class _ProfitAndLossView extends StatelessWidget {
  const _ProfitAndLossView();

  /// Moves one end of the window and re-reads.
  ///
  /// The same `showDatePicker` the purchase-order form uses, and the day is formatted the same
  /// way: a plain `YYYY-MM-DD`, which is the only thing the API filters on.
  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final cubit = context.read<ProfitAndLossCubit>();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأرباح والخسائر')),
      body: SafeArea(
        child: BlocBuilder<ProfitAndLossCubit, ProfitAndLossState>(
          builder: (context, state) {
            final cubit = context.read<ProfitAndLossCubit>();

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: AppIcons.today,
                          label: 'من',
                          value: cubit.from,
                          // The server's own sentence, under the box it is about — which is the
                          // whole reason a 422 keys its messages by field.
                          error: state.fromError,
                          onTap: () => _pick(context, isFrom: true),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _PickerTile(
                          icon: AppIcons.month,
                          label: 'إلى',
                          value: cubit.to,
                          error: state.toError,
                          onTap: () => _pick(context, isFrom: false),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (state) {
                    ProfitAndLossInitial() || ProfitAndLossLoading() => const _ReportSkeleton(),
                    // A refused date is already painted under the picker it belongs to; a page
                    // of «البيانات المدخلة غير صحيحة» over it would say the same thing twice
                    // and less usefully.
                    ProfitAndLossFailure() when !state.hasUnrenderedErrors =>
                      const _CorrectThePeriod(),
                    ProfitAndLossFailure(:final failure) => _FailureView(
                      message: failure.message,
                      onRetry: cubit.load,
                    ),
                    ProfitAndLossLoaded(:final summary) => RefreshIndicator(
                      onRefresh: cubit.refresh,
                      child: _Report(summary: summary),
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

/// The figures, in the order they are read.
class _Report extends StatelessWidget {
  const _Report({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final revenue = summary.revenue;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        _Section(
          title: 'الإيراد',
          // Said out loud because the number invites the wrong reading: this is not what the
          // customers were billed.
          note: 'لا يشمل سعر التوصيل، ولا يُطرح منه الخصم.',
          child: Column(
            children: [
              _MoneyRow(label: 'المنتجات', value: revenue.product),
              SizedBox(height: 10.h),
              _MoneyRow(label: 'التصميم', value: revenue.service),
              const _TotalDivider(),
              _MoneyRow(label: 'إجمالي الإيراد', value: revenue.total, isTotal: true),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _CostOfGoodsSold(cost: summary.costOfGoodsSold),
        SizedBox(height: 20.h),

        _GrossProfit(summary: summary),

        // Drawn from the two figures above it and never from a third: the arcs are the cost and
        // the profit the server sent, so the picture cannot disagree with the rows.
        if (summary.hasRevenue) ...[
          SizedBox(height: 20.h),
          if (summary.isLoss)
            _RevenueAgainstCost(summary: summary)
          else
            _RevenueSplit(summary: summary),
        ],

        // The break in the page. Everything above is one arithmetic; what follows is not part
        // of it, and the gap plus the rule are what say so before a word is read.
        SizedBox(height: 32.h),
        const Divider(height: 1),
        SizedBox(height: 24.h),

        _CashCollected(summary: summary),
      ],
    );
  }
}

/// The one loud number on the screen.
///
/// **Coloured only when it is a loss.** The payment board learned this: a mark that appears in
/// every state is a mark nobody reads, so a profit is drawn in plain ink — it is already the
/// biggest thing here — and the error tone is kept for the period that has to be acted on. The
/// colour is never alone either: a losing period says so in a sentence underneath.
class _GrossProfit extends StatelessWidget {
  const _GrossProfit({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = summary.isLoss ? scheme.error : scheme.onSurface;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: summary.isLoss
              ? scheme.error.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الربح الإجمالي',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  summary.grossProfitLabel,
                  // A Latin run: `12,450` renders as `450,12` without this, which is a
                  // different number rather than a rendering glitch.
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'د.ل',
                style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (summary.isLoss) ...[
            SizedBox(height: 6.h),
            Text(
              'الفترة خاسرة — التكلفة أكبر من الإيراد.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// تكلفة البضاعة المباعة — the three parts and the total the orders themselves carry.
///
/// **All four are printed as they arrived.** [PnlCostOfGoodsSold.total] is a cached column on the
/// orders; المواد, العمالة and المصاريف العامة are summed from the order *lines*. The two come
/// from different tables with different scopes and are allowed to disagree, so the note under the
/// block says so rather than the screen quietly adding three numbers up and printing a fourth it
/// was never given.
class _CostOfGoodsSold extends StatelessWidget {
  const _CostOfGoodsSold({required this.cost});

  final PnlCostOfGoodsSold cost;

  @override
  Widget build(BuildContext context) {
    final tones = _costTones(context.colorScheme);

    return _Section(
      title: 'تكلفة البضاعة المباعة',
      note: 'المواد والعمالة والمصاريف من بنود الطلبيات، والإجمالي من الطلبيات نفسها.',
      child: Column(
        children: [
          _MoneyRow(label: 'المواد', value: cost.material, dot: tones[0]),
          SizedBox(height: 10.h),
          _MoneyRow(label: 'العمالة', value: cost.labor, dot: tones[1]),
          SizedBox(height: 10.h),
          _MoneyRow(label: 'المصاريف العامة', value: cost.overhead, dot: tones[2]),
          SizedBox(height: 12.h),
          _CostMix(cost: cost),
          const _TotalDivider(),
          _MoneyRow(label: 'إجمالي التكلفة', value: cost.total, isTotal: true),
        ],
      ),
    );
  }
}

/// The mix of the three parts, as one strip the width of the block.
///
/// **Proportions of their own sum, never of the total above them** — those two figures come from
/// different tables and need not agree, so a strip measured against إجمالي التكلفة could end
/// short of its own container and read as a fourth, missing part.
///
/// Drawn by hand rather than by the chart library: a one-dimensional strip is three boxes in a
/// row, and there is no axis, scale or touch layer here for `fl_chart` to be carrying. The colours
/// are the same three the rows above wear, which is what ties a segment to its figure — the strip
/// is never asked to carry a label of its own.
class _CostMix extends StatelessWidget {
  const _CostMix({required this.cost});

  final PnlCostOfGoodsSold cost;

  @override
  Widget build(BuildContext context) {
    final tones = _costTones(context.colorScheme);
    final parts = [cost.material, cost.labor, cost.overhead]
        .map((value) => num.tryParse(value)?.toDouble() ?? 0)
        .toList();

    // A period whose cost was never recorded is a row of zeros, and a strip of nothing is worse
    // than no strip: an empty bar reads as a bar that failed to draw.
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
                key: ValueKey('cost-mix-$index'),
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

/// أين ذهب الإيراد — the period's revenue divided into what it cost and what was left.
///
/// **Two arcs and a percent, and the percent is the reason the chart exists.** The amounts are
/// already printed above in full; what the rows cannot say at a glance is the *share*, and هامش
/// الربح in the middle of the ring is a figure that appears nowhere else on the screen.
///
/// **The arcs are the cost and the profit, not the revenue.** Those two are what the server sent
/// and what the rows above print, so the ring can never disagree with them — measuring the arcs
/// against إجمالي الإيراد instead would let a قرش of rounding open a sliver of unexplained gap.
///
/// The two tones are the app's own `primary` and the neutral beside it rather than two accents:
/// the generated Material palette is a single teal family, and its accents sit close enough that
/// a colourblind reader — and, checked rather than guessed, a reader with full colour vision too
/// — cannot tell `primary` from `tertiary` in two arcs. A strong colour against a recessive
/// neutral separates for everyone, and says the right thing besides: the teal is the part the
/// shop kept. Neither arc is identified by its colour alone — each is named in the legend.
class _RevenueSplit extends StatelessWidget {
  const _RevenueSplit({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = summary.grossMarginLabel;

    // Geometry, and only geometry: these two are never printed. Every amount on this screen is
    // the server's own string, and a `double` is not allowed anywhere near one.
    final kept = num.tryParse(summary.grossProfit)?.toDouble() ?? 0;
    final spent = num.tryParse(summary.costOfGoodsSold.total)?.toDouble() ?? 0;

    return _Section(
      title: 'أين ذهب الإيراد',
      showsCurrency: false,
      child: Row(
        children: [
          SizedBox(
            height: 132.h,
            width: 132.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    // Nothing here responds to a finger: a two-arc ring has no detail a tooltip
                    // could add that the rows above do not already print.
                    pieTouchData: PieTouchData(enabled: false),
                    borderData: FlBorderData(show: false),
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 40.r,
                    sections: [
                      PieChartSectionData(
                        value: kept,
                        color: scheme.primary,
                        radius: 16.r,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: spent,
                        color: _spentTone(scheme),
                        radius: 16.r,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                if (margin case final share?)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        share,
                        // `59%` renders as `%59` without this — a percent sign is a Latin run.
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'هامش الربح',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendEntry(tone: scheme.primary, label: 'الربح'),
                SizedBox(height: 10.h),
                _LegendEntry(tone: _spentTone(scheme), label: 'التكلفة'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What a losing period gets instead of a donut: the two amounts, side by side.
///
/// **A negative arc is not a shape.** A ring can only divide something into parts of itself, and
/// a period that spent more than it earned has no share of its revenue left to divide — so the
/// two figures are drawn against each other, which is the whole story: the cost bar is taller
/// than the revenue bar, and the sentence on الربح الإجمالي above already says why in words.
///
/// The cost wears the error tone here and nowhere else on this screen — it is the figure that has
/// to be acted on — and it is never the colour alone that says so: both bars are named, and the
/// card sits under a card that says «الفترة خاسرة» in a sentence.
class _RevenueAgainstCost extends StatelessWidget {
  const _RevenueAgainstCost({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // Geometry only, exactly as in [_RevenueSplit]; the labels under the bars print the server's
    // own strings.
    final earned = num.tryParse(summary.revenue.total)?.toDouble() ?? 0;
    final spent = num.tryParse(summary.costOfGoodsSold.total)?.toDouble() ?? 0;

    return _Section(
      title: 'الإيراد مقابل التكلفة',
      showsCurrency: false,
      child: SizedBox(
        height: 150.h,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            minY: 0,
            // Headroom, so the taller bar stops short of the card's own edge rather than
            // touching it and reading as clipped.
            maxY: (earned > spent ? earned : spent) * 1.15,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: const BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              // No y-axis: the amounts are printed under the bars and again in the blocks above,
              // and a scale of five interpolated numbers is a ruler nobody asked for.
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44.h,
                  getTitlesWidget: (value, meta) => _BarLabel(
                    label: value == 0 ? 'تكلفة' : 'إيراد',
                    amount: value == 0 ? summary.costOfGoodsSold.total : summary.revenue.total,
                  ),
                ),
              ),
            ),
            // `fl_chart` lays its groups out left to right whatever the `Directionality` around
            // it, so the pair is ordered backwards here to be read forwards: إيراد lands on the
            // right, where an Arabic reader starts.
            barGroups: [
              _bar(x: 0, value: spent, tone: scheme.error),
              _bar(x: 1, value: earned, tone: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar({required int x, required double value, required Color tone}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: tone,
          width: 40.w,
          // Rounded at the top and square on the baseline: a bar that curves where it meets the
          // axis reads as floating above it.
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
        ),
      ],
    );
  }
}

/// What a bar is called and what it is worth, under it.
class _BarLabel extends StatelessWidget {
  const _BarLabel({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 2.h),
          Text(
            groupedDecimal(amount),
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// A mark and the word for it — what keeps an arc from being identified by its colour alone.
class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.tone, required this.label});

  final Color tone;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(tone: tone),
        SizedBox(width: 8.w),
        Text(
          label,
          // The word wears the ink of every other word on the screen; the mark beside it is what
          // carries the colour. A label painted in its own series colour is a legend that reads
          // as a status.
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
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

/// The three steps المواد, العمالة and المصاريف العامة are drawn in, in that order.
///
/// **One hue at three strengths, not three accents.** The parts of a cost are one measure split
/// three ways, which is what a sequential ramp is for; and the generated palette has no three
/// accents that separate anyway — `tertiary` and `secondary` in it are a blue-grey and a
/// teal-grey a deuteranope cannot tell apart, and neither can most people. Stepping one hue
/// instead separates by lightness, which survives every kind of colour vision and a photocopier.
///
/// Alpha over the card's own surface rather than three literal colours: `theme.dart` is generated
/// and replaced wholesale, so a hex written here would quietly stop matching the app around it.
/// The three steps are `1.0 / 0.62 / 0.40`, and the last one is not lower than that on purpose:
/// a fainter third step separates from the second by less than the eye reliably resolves, and on
/// the dark surface it stops being visible at all. Measured in both brightnesses, not judged.
List<Color> _costTones(ColorScheme scheme) => [
  scheme.tertiary,
  scheme.tertiary.withValues(alpha: 0.62),
  scheme.tertiary.withValues(alpha: 0.40),
];

/// The recessive half of [_RevenueSplit] — the part of the revenue that left.
///
/// Each brightness takes the neutral that actually separates on it: `outlineVariant` disappears
/// into a dark card, and `outline` on a light one sits close enough to `primary` that the two
/// arcs stop being two. Both pairs were measured, not eyeballed.
Color _spentTone(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark ? scheme.outline : scheme.outlineVariant;

/// Money that came in, reported beside the report and never inside it.
///
/// **Not netted against anything, and said so in words.** It is every payment whose day fell in
/// the window, whichever order it was against — a deposit on a job still in printing counts here
/// and appears nowhere above. It is also gross: a refund is not taken off it, so «صافي» is a
/// word this card must never use.
class _CashCollected extends StatelessWidget {
  const _CashCollected({required this.summary});

  final ProfitAndLossSummary summary;

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
              Icon(AppIcons.payment, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Text(
                'النقد المحصَّل',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                groupedDecimal(summary.cashCollected),
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'د.ل',
                style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'كل ما دخل الصندوق في هذه الفترة، أياً كانت الطلبية التي دُفع عليها. '
            'لا يُطرح من التكلفة ولا يدخل في الربح أعلاه، والمبالغ المستردة لا تُخصم منه.',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A block of figures under one heading.
///
/// The currency is stated once, in the heading, so every row underneath is a bare number —
/// the same trick the price grid on a product uses, and for the same reason: «د.ل» repeated
/// down a column is four words competing with the four numbers they qualify.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.note,
    this.showsCurrency = true,
  });

  final String title;
  final Widget child;
  final String? note;

  /// Whether «د.ل» belongs beside the heading.
  ///
  /// It does over a column of amounts, and it does not over a chart: the two figures a chart
  /// carries are a share and a shape, and a currency printed over them qualifies neither.
  final bool showsCurrency;

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
            if (showsCurrency)
              Text(
                'د.ل',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
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
        if (note case final line?) ...[
          SizedBox(height: 6.h),
          Text(
            line,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// One figure: what it is on one side, what it is on the other.
///
/// [value] arrives as the server's decimal string and is grouped by string surgery — never
/// parsed. `'0.00'` is a real answer here, so a zero row is drawn like any other rather than
/// hidden: a cost of nothing is a fact about the period.
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.dot,
  });

  final String label;
  final String value;

  /// The line the block adds up to — the server's own total, never a sum computed here.
  final bool isTotal;

  /// The colour this row wears in [_CostMix], if it is drawn there.
  ///
  /// The mark is what ties a segment of the strip to the figure it is, which is why the strip
  /// itself carries no labels of its own.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        if (dot case final tone?) ...[
          _Dot(tone: tone),
          SizedBox(width: 8.w),
        ],
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          groupedDecimal(value),
          textDirection: TextDirection.ltr,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// The rule above a block's total.
class _TotalDivider extends StatelessWidget {
  const _TotalDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Divider(
        height: 1,
        color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
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
                  color: error == null
                      ? scheme.outlineVariant.withValues(alpha: 0.7)
                      : scheme.error,
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
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// The shape of the report, drawn before its figures arrive.
///
/// A skeleton rather than a spinner: the layout does not jump when the numbers land, and the
/// wait is spent looking at where they will be.
class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        _SkeletonBox(height: 120.h, radius: 16.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 150.h, radius: 16.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 92.h, radius: 20.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 190.h, radius: 16.r),
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
          'صحّح الفترة أعلاه لعرض التقرير',
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
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
