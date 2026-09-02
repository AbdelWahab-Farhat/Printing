import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/presentation/viewmodel/profit_and_loss_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الأرباح والخسائر — the shop's period read in one screen.
///
/// **The chain is read downwards and it is one chain: الإيراد ← الربح.** Everything in
/// it belongs to the same arithmetic, in the same column, so a reader can follow it without
/// being told how.
///
/// **The three totals are read first, in [_Totals], and everything under them is a breakdown.**
/// الإيراد، التكلفة، الربح in one row of tiles: the whole period in a phone-width glance, with
/// the parts of each underneath for whoever wants them. الربح is the server's own figure —
/// revenue *minus* cost, never the revenue drawn a second time — and the cost total it was
/// computed against is a cached column on the orders, while المواد, العمالة and المصاريف العامة
/// under it are summed from the order *lines*: two different tables, allowed to disagree, so
/// neither is ever derived from the other here.
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
/// **Nothing is charted, and no figure is explained in a sentence under it.** A donut of the
/// revenue split was drawn here and taken out again: every figure on this screen is a period
/// total with no series behind it, and a picture of three amounts that are already printed is a
/// picture that only costs a screenful. The small print under the blocks went the same way — a
/// caveat nobody was reading, under numbers that had to be scrolled to.
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        _Totals(summary: summary),
        SizedBox(height: 24.h),

        _Section(
          title: 'تفاصيل الإيراد',
          child: Column(
            children: [
              _MoneyRow(label: 'المنتجات', value: revenue.product),
              SizedBox(height: 10.h),
              _MoneyRow(label: 'التصميم', value: revenue.service),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _CostOfGoodsSold(cost: summary.costOfGoodsSold),

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

/// The period in one row: الإيراد، التكلفة، الربح.
///
/// **Three tiles rather than three cards down a page.** They are the same three figures the
/// blocks underneath break down, and they were each taking a block of their own — one of them a
/// card the height of a hand — for a number that is read in a second. Side by side they are also
/// *compared* rather than merely listed, which is the one thing a reader wants from them and the
/// reason they are in the order of the arithmetic: earned, spent, left.
///
/// **الربح is coloured only when it is a loss.** The payment board learned this: a mark that
/// appears in every state is a mark nobody reads, so a profit is drawn in the same ink as the two
/// beside it and the error tone is kept for the period that has to be acted on — never alone, a
/// losing period says so in a sentence under the row.
class _Totals extends StatelessWidget {
  const _Totals({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
              Expanded(
                child: _TotalTile(label: 'الإيراد', value: summary.revenue.total),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _TotalTile(label: 'التكلفة', value: summary.costOfGoodsSold.total),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _TotalTile(
                  label: 'الربح',
                  // Already carries its own `-`; the tile prints the server's string as it came.
                  value: summary.grossProfit,
                  tone: summary.isLoss ? scheme.error : null,
                ),
              ),
            ],
          ),
        ),
        if (summary.isLoss) ...[
          SizedBox(height: 8.h),
          Text(
            'الفترة خاسرة — التكلفة أكبر من الإيراد.',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// One of the three: what it is, and what it came to.
///
/// The currency is inside each tile rather than once above the row — three tiles side by side
/// have no heading between them to hang a single «د.ل» off, and a bare `1,615` at the top of a
/// money screen is the one number a reader should never have to assume the unit of.
class _TotalTile extends StatelessWidget {
  const _TotalTile({required this.label, required this.value, this.tone});

  final String label;
  final String value;

  /// Overrides the ink of the amount — the loss tone, and nothing else.
  final Color? tone;

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
          // A third of a phone is not much room for `12,450`, and a figure that overflows its
          // tile is worse than a figure drawn a point smaller.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  groupedDecimal(value),
                  // A Latin run: `12,450` renders as `450,12` without this, which is a different
                  // number rather than a rendering glitch.
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone ?? scheme.onSurface,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'د.ل',
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

/// تفاصيل التكلفة — what the period's cost was made of.
///
/// **The three parts as they arrived, and no fourth number computed from them.** إجمالي التكلفة
/// is a tile above, and it is a cached column on the orders while these three are summed from the
/// order *lines* — two tables with two scopes, allowed to disagree. Adding the three up here to
/// check the tile would be the screen inventing a figure the server never gave it.
class _CostOfGoodsSold extends StatelessWidget {
  const _CostOfGoodsSold({required this.cost});

  final PnlCostOfGoodsSold cost;

  @override
  Widget build(BuildContext context) {
    final tones = _costTones(context.colorScheme);

    return _Section(
      title: 'تفاصيل التكلفة',
      child: Column(
        children: [
          _MoneyRow(label: 'المواد', value: cost.material, dot: tones[0]),
          SizedBox(height: 10.h),
          _MoneyRow(label: 'العمالة', value: cost.labor, dot: tones[1]),
          SizedBox(height: 10.h),
          _MoneyRow(label: 'المصاريف العامة', value: cost.overhead, dot: tones[2]),
          SizedBox(height: 12.h),
          _CostMix(cost: cost),
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
    final parts = [
      cost.material,
      cost.labor,
      cost.overhead,
    ].map((value) => num.tryParse(value)?.toDouble() ?? 0).toList();

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
              // A year's takings is a long number, and `titleLarge` beside a label and an icon
              // runs out of phone before it runs out of digits — scaled down rather than
              // overflowed, because a clipped amount is a wrong amount.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    groupedDecimal(summary.cashCollected),
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
  const _Section({required this.title, required this.child});

  final String title;
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
            Text('د.ل', style: context.textTheme.bodySmall?.copyWith(color: scheme.outline)),
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

/// One figure: what it is on one side, what it is on the other.
///
/// [value] arrives as the server's decimal string and is grouped by string surgery — never
/// parsed. `'0.00'` is a real answer here, so a zero row is drawn like any other rather than
/// hidden: a cost of nothing is a fact about the period.
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.dot});

  final String label;
  final String value;

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
        if (dot case final tone?) ...[_Dot(tone: tone), SizedBox(width: 8.w)],
        Text(label, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          groupedDecimal(value),
          textDirection: TextDirection.ltr,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
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
          Text(message, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
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
        Row(
          children: [
            Expanded(
              child: _SkeletonBox(height: 68.h, radius: 16.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SkeletonBox(height: 68.h, radius: 16.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SkeletonBox(height: 68.h, radius: 16.r),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _SkeletonBox(height: 96.h, radius: 16.r),
        SizedBox(height: 20.h),
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
          'صحّح الفترة أعلاه لعرض التقرير',
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
