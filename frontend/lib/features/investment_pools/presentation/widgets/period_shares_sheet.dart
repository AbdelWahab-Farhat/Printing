import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/models/period_share.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_periods_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who got what, in a period that has closed.
///
/// **The frozen record, not a fresh calculation.** These are the weights the close actually applied
/// and the amounts it actually paid. Asked in December about September, today's weights on the
/// pool's screen bear no relation to the ones that were used — so recomputing would answer a
/// different question from the one somebody is asking.
Future<void> showPeriodSharesSheet({
  required BuildContext context,
  required InvestmentPeriod period,
}) {
  final cubit = context.read<PoolPeriodsCubit>();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider<PoolPeriodsCubit>.value(
      value: cubit,
      child: _PeriodShares(period: period),
    ),
  );
}

class _PeriodShares extends StatefulWidget {
  const _PeriodShares({required this.period});

  final InvestmentPeriod period;

  @override
  State<_PeriodShares> createState() => _PeriodSharesState();
}

class _PeriodSharesState extends State<_PeriodShares> {
  List<PeriodShare>? _shares;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<PoolPeriodsCubit>().shares(
      widget.period.id,
    );

    if (!mounted) return;

    setState(() {
      result.fold(
        (failure) => _error = failure.message,
        (shares) => _shares = shares,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shares = _shares;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
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
              'توزيع الفترة',
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
            SizedBox(height: 16.h),

            if (_error != null)
              Text(_error!, style: TextStyle(color: scheme.error))
            else if (shares == null)
              const Center(child: CircularProgressIndicator())
            else if (shares.isEmpty)
              Text(
                'لم تُوزَّع هذه الفترة بعد',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final share in shares) _ShareRow(share: share),
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share});

  final PeriodShare share;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isLoss = share.netShare.startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  share.investorName ?? 'مستثمر ${share.investorId}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (share.isCompany)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: const Chip(
                    label: Text('الشركة'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Text(
                share.netShare.grouped,
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isLoss ? scheme.error : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            // The working, beside the answer. The company's percentage is 100 of its own side —
            // its take is the residual of the division, not a slice of the investors' half — so
            // saying so beats printing a number that reads like a share of everything.
            share.isCompany
                ? 'حصة الشركة — الباقي بعد حصة المستثمرين · رأس مالها ${share.capital.grouped}'
                : 'رأس ماله ${share.capital.grouped} · نسبته ${share.sharePercent.grouped}٪ من حصة المستثمرين',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
