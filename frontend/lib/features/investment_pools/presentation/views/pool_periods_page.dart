import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_periods_cubit.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/close_period_sheet.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/period_shares_sheet.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// فترات الصندوق — **what actually closes**, since the pool itself never does.
class PoolPeriodsPage extends StatelessWidget {
  const PoolPeriodsPage({required this.poolId, super.key});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PoolPeriodsCubit>(
      create: (_) => sl<PoolPeriodsCubit>()..load(poolId),
      child: _PeriodsView(poolId: poolId),
    );
  }
}

class _PeriodsView extends StatelessWidget {
  const _PeriodsView({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PoolPeriodsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('الفترات')),
      body: BlocBuilder<PoolPeriodsCubit, PoolPeriodsState>(
        builder: (context, state) => switch (state) {
          PoolPeriodsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PoolPeriodsFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
          PoolPeriodsLoaded(:final periods) => RefreshIndicator(
            onRefresh: () => cubit.load(poolId),
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
              children: [
                if (periods.every((period) => !period.isOpen)) ...[
                  _OpenNextCard(poolId: poolId),
                  SizedBox(height: 16.h),
                ],
                for (final period in periods) ...[
                  _PeriodCard(period: period, poolId: poolId),
                  SizedBox(height: 12.h),
                ],
                if (periods.isEmpty) const Text('لا فترات بعد'),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// Only shown when a pool somehow has **no** open period.
///
/// Normally unreachable: a close opens the next one in the same transaction, so a pool is never
/// without one. Kept because «unreachable» and «cannot happen» are different words, and a pool
/// stuck without a period would otherwise have no way back.
class _OpenNextCard extends StatelessWidget {
  const _OpenNextCard({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'لا توجد فترة مفتوحة',
      tone: PoolSectionTone.warning,
      subtitle: 'لن تُسجَّل أرباح جديدة حتى تُفتح فترة',
      children: [
        AppButton(
          label: 'افتح الفترة القادمة',
          onPressed: () async {
            final result = await context.read<PoolPeriodsCubit>().openNext(
              poolId,
            );

            if (!context.mounted) return;

            result.fold(
              (failure) => context.showError(failure.message),
              (opened) {
                // Anybody whose wallet could no longer cover what he asked for is named here.
                // His request stays pending and the period opened regardless — which somebody
                // has to be told rather than left to notice at the next close.
                if (opened.short.isNotEmpty) {
                  context.showError(
                    'فُتحت الفترة، لكن ${opened.short.length.grouped} طلب رأس مال لم ينفَّذ لعدم كفاية الرصيد',
                  );

                  return;
                }

                context.showSuccess('تم فتح الفترة');
              },
            );
          },
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.poolId});

  final InvestmentPeriod period;
  final int poolId;

  @override
  Widget build(BuildContext context) {
    final snapshot = period.snapshot;

    return PoolSection(
      title: '${period.startsOn ?? ''} — ${period.endsOn ?? ''}',
      // The one line that says both where it stands and whether anybody should act.
      subtitle: period.isOverdue
          ? '${period.statusLabel} · متأخرة ${period.daysOverdue.grouped} يوماً'
          : period.statusLabel,
      tone: period.isOverdue
          ? PoolSectionTone.warning
          : PoolSectionTone.plain,
      children: [
        if (period.isOpen) ...[
          // **Said here, where the button is.** The server refuses the close over an unanswered
          // question anyway — discovering that by pressing the button is a wasted trip, and the
          // person reading this is the one who can clear it.
          if (period.blockedByReturnedGoods) ...[
            Text(
              'فيها بضاعة راجعة لم تُفحص — أجب عنها من شاشة الصندوق قبل الإقفال',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
            SizedBox(height: 8.h),
          ],
          AppButton(
            label: 'أقفل الفترة',
            onPressed: () => showClosePeriodSheet(
              context: context,
              poolId: poolId,
              period: period,
            ),
          ),
        ]
        else if (snapshot != null) ...[
          // **The distribution, one tap away from the figures that produced it.** «صافي الربح
          // 10,500» without «من أخذ ماذا» is the question this screen most often gets asked.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () =>
                  showPeriodSharesSheet(context: context, period: period),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('من أخذ ماذا'),
            ),
          ),
          _Figure(label: 'مجمل الربح المحقق', value: snapshot.realizedMargin),
          _Figure(label: 'مصاريف مخصومة', value: snapshot.deductibleExpenses),
          _Figure(label: 'تالف', value: snapshot.damageCost),
          _Figure(label: 'نقص', value: snapshot.shortageCost),
          const Divider(),
          _Figure(
            label: 'صافي الربح',
            value: snapshot.netProfit,
            emphasised: true,
          ),
          SizedBox(height: 8.h),
          // The terms actually applied, so a period read next year explains itself without
          // anybody having to know what the settings said that month.
          Text(
            'حصة المستثمرين ${snapshot.investorSharePercentApplied.grouped}٪'
            ' · وزن رأس مالهم ${snapshot.investorCapitalWeightApplied.grouped}٪',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
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
            value.grouped,
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
