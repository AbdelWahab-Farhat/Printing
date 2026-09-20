import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_periods_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The confirmation for an **irreversible payout**.
///
/// **Every figure here comes from the server**, from the same query the close itself then uses.
/// Recomputing any of it in Dart is exactly how a person approves one number and the ledger
/// writes another — so this screen fetches and prints, and calculates nothing.
Future<void> showClosePeriodSheet({
  required BuildContext context,
  required int poolId,
  required InvestmentPeriod period,
}) {
  final cubit = context.read<PoolPeriodsCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<PoolPeriodsCubit>.value(
      value: cubit,
      child: _ClosePeriodSheet(poolId: poolId, period: period),
    ),
  );
}

class _ClosePeriodSheet extends StatefulWidget {
  const _ClosePeriodSheet({required this.poolId, required this.period});

  final int poolId;
  final InvestmentPeriod period;

  @override
  State<_ClosePeriodSheet> createState() => _ClosePeriodSheetState();
}

class _ClosePeriodSheetState extends State<_ClosePeriodSheet> {
  PeriodFigures? _figures;
  String? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<PoolPeriodsCubit>().figures(
      widget.period.id,
    );

    if (!mounted) return;

    setState(() {
      result.fold(
        (failure) => _error = failure.message,
        (figures) => _figures = figures,
      );
    });
  }

  Future<void> _close() async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'إقفال الفترة',
      description:
          'تُوزَّع الأرباح وتُصبح قابلة للسحب، وتُخصم الخسائر من رأس المال، '
          'ويُدفع لمن طلب الخروج. لا يمكن التراجع.',
      confirmLabel: 'أقفل',
    );

    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _closing = true);

    final failure = await context.read<PoolPeriodsCubit>().closePeriod(
      poolId: widget.poolId,
      periodId: widget.period.id,
    );

    if (!mounted) return;

    setState(() => _closing = false);

    if (failure != null) {
      // The server's own words. It refuses while a returned-goods question is unanswered, and
      // its message says so — restating that rule here would be a second copy to keep in step.
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم إقفال الفترة وتوزيع الأرباح');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final figures = _figures;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'إقفال الفترة',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '${widget.period.startsOn ?? ''} — ${widget.period.endsOn ?? ''}',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),

            if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error))
            else if (figures == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              _Row(label: 'مجمل الربح المحقق', value: figures.realizedMargin),
              _Row(
                label: 'مصاريف مخصومة',
                value: figures.deductibleExpenses,
                negative: true,
              ),
              _Row(label: 'تالف', value: figures.damageCost, negative: true),
              _Row(label: 'نقص', value: figures.shortageCost, negative: true),
              const Divider(),
              _Row(
                label: 'صافي الربح',
                value: figures.netProfit,
                emphasised: true,
              ),

              // **«محسوبة مسبقاً» — §6.2.4.** Shipping and customs typed on a purchase order are
              // already inside the cost of the layers that arrived. Printed here so nobody
              // wonders where they went, and deliberately outside the sum: subtracting them
              // again would charge the investors for one customs invoice twice.
              if (figures.recordedOnlyExpenses != '0.00') ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'محسوبة مسبقاً: ${figures.recordedOnlyExpenses.grouped}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'شحن وجمارك داخلة أصلاً في تكلفة البضاعة — لا تُخصم مرة ثانية',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              if (figures.hasUnansweredReturns)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    'فيه بضاعة راجعة من طلبيات ملغاة لم تُفحص بعد — أجب عنها من شاشة الصندوق قبل الإقفال.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                )
              else
                AppButton(
                  label: 'أقفل الفترة',
                  isLoading: _closing,
                  onPressed: _closing ? null : _close,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.negative = false,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool negative;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            negative ? '− ${value.grouped}' : value.grouped,
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
