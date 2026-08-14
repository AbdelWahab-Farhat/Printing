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
/// **The chain is read downwards and it is one chain: الإيراد ← التكلفة ← الربح.** Everything in
/// it belongs to the same arithmetic, in the same column, so a reader can follow it without
/// being told how. **[_CashCollected] is deliberately not in it** — it is separated by a divider
/// and its own words, because the money that came in over these days has nothing to do with the
/// orders above: it is every payment in the business whose day fell inside the window, whichever
/// order it was against and whatever stage that order is at. Pairing it with a cost would imply
/// a cash-basis margin this business does not compute — the materials were already paid for
/// through purchase orders — so it is never subtracted from anything and never sits in the same
/// column.
///
/// **Nothing is charted.** Every figure is a period total with no series behind it, and a bar of
/// four totals is a shape that adds nothing to four numbers with words beside them.
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
    final cost = summary.costOfGoodsSold;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      children: [
        _Recognition(summary: summary),
        SizedBox(height: 20.h),

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

        _Section(
          title: 'تكلفة البضاعة المباعة',
          // There is no third column for machine time, so a reader looking for «تشغيل آلة»
          // needs to be told where it went rather than left to conclude it was dropped.
          note: 'تشغيل الآلة يدخل ضمن المصاريف العامة.',
          child: Column(
            children: [
              _MoneyRow(label: 'المواد', value: cost.material),
              SizedBox(height: 10.h),
              _MoneyRow(label: 'العمالة', value: cost.labor),
              SizedBox(height: 10.h),
              _MoneyRow(label: 'المصاريف العامة', value: cost.overhead),
              const _TotalDivider(),
              _MoneyRow(label: 'إجمالي التكلفة', value: cost.total, isTotal: true),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _GrossProfit(summary: summary),

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

/// What the figures above are about — and, when there is nothing, why.
///
/// **The count comes first.** An all-zero report has two meanings — nothing was delivered, or
/// the period is wrong — and this line is the only thing on the screen that tells them apart.
class _Recognition extends StatelessWidget {
  const _Recognition({required this.summary});

  final ProfitAndLossSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary.hasRecognisedOrders
              ? '${summary.ordersRecognized.grouped} طلبية محتسبة'
              : 'لا طلبيات مسلَّمة أو مصفّاة في هذه الفترة',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          // The server's own window, not the one on the pickers: it is the normalised one, and
          // it is what these figures were counted over.
          summary.period.label,
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 2.h),
        Text(
          'يُحتسب الإيراد على الطلبيات المسلَّمة والمصفّاة وحدها، بتاريخ التسليم أو التصفية.',
          style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
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
  const _Section({required this.title, required this.child, this.note});

  final String title;
  final Widget child;
  final String? note;

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
  const _MoneyRow({required this.label, required this.value, this.isTotal = false});

  final String label;
  final String value;

  /// The line the block adds up to — the server's own total, never a sum computed here.
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
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
        _SkeletonBox(height: 56.h, radius: 12.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 120.h, radius: 16.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 150.h, radius: 16.r),
        SizedBox(height: 20.h),
        _SkeletonBox(height: 92.h, radius: 20.r),
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
