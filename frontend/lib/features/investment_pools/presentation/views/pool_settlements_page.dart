import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/features/investment_pools/models/investment_settlement.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_settlements_cubit.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تسويات الصندوق — where the money is, and every position somebody has signed.
///
/// **The drift is at the top, alone, before any of the eleven reassuring totals.** It is the one
/// figure that cannot be read anywhere else in the app, because it is a comparison of two
/// derivations that never consult each other. A screen that buries it turns a finding into
/// decoration.
class PoolSettlementsPage extends StatelessWidget {
  const PoolSettlementsPage({required this.poolId, super.key});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PoolSettlementsCubit>(
      create: (_) => sl<PoolSettlementsCubit>()..load(poolId),
      child: _SettlementsView(poolId: poolId),
    );
  }
}

class _SettlementsView extends StatelessWidget {
  const _SettlementsView({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PoolSettlementsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('التسويات')),
      body: BlocBuilder<PoolSettlementsCubit, PoolSettlementsState>(
        builder: (context, state) => switch (state) {
          PoolSettlementsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PoolSettlementsFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
          PoolSettlementsLoaded(:final snapshot, :final settlements) =>
            RefreshIndicator(
              onRefresh: () => cubit.load(poolId),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
                children: [
                  _DriftBanner(snapshot: snapshot),
                  SizedBox(height: 16.h),
                  _DueSection(snapshot: snapshot),
                  SizedBox(height: 16.h),
                  _PositionSection(snapshot: snapshot),
                  SizedBox(height: 16.h),
                  _SignSection(poolId: poolId),
                  SizedBox(height: 16.h),
                  _HistorySection(settlements: settlements),
                ],
              ),
            ),
        },
      ),
    );
  }
}

/// «الدفاتر تطابق البضاعة» — or by how much they do not.
class _DriftBanner extends StatelessWidget {
  const _DriftBanner({required this.snapshot});

  final SettlementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hasDrift = snapshot.drift != '0.00' && snapshot.drift != '-0.00';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: hasDrift ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDrift ? Icons.error_outline : Icons.verified_outlined,
                color: hasDrift
                    ? scheme.onErrorContainer
                    : scheme.onSecondaryContainer,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  hasDrift ? 'يوجد فرق غير مفسَّر' : 'الدفاتر مطابقة',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasDrift
                        ? scheme.onErrorContainer
                        : scheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (hasDrift)
                Text(
                  snapshot.drift.grouped,
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onErrorContainer,
                  ),
                ),
            ],
          ),
          if (hasDrift) ...[
            SizedBox(height: 8.h),
            // Said plainly, because the usual cause is a specific and findable act.
            Text(
              'أرقام الدفاتر لا تساوي ما تعطيه الحركات. الغالب أن بضاعة خرجت من الرف '
              'بتسوية مخزنية لم تُحمَّل على أحد. الفرق يُسجَّل ولا يُعالَج تلقائياً.',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// When the last review was signed, and when the next one falls due.
///
/// **Derived from «مدة التسوية», never stored** — shorten the cycle and this date moves; a
/// settlement already signed keeps the date it was signed on.
///
/// A pool nobody has ever settled is not overdue and says so plainly. Inventing a due date from
/// the day it opened would put a warning on every new pool, which is how people learn to ignore
/// warnings.
class _DueSection extends StatelessWidget {
  const _DueSection({required this.snapshot});

  final SettlementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final due = snapshot.nextSettlementDueOn;

    return PoolSection(
      title: 'دورة المراجعة',
      subtitle: 'كل ${snapshot.settlementPeriodMonths.grouped} أشهر',
      tone: snapshot.settlementIsOverdue
          ? PoolSectionTone.warning
          : PoolSectionTone.plain,
      children: [
        if (snapshot.lastSettledOn == null)
          Text(
            'لم تُجرَ تسوية لهذا الصندوق بعد',
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else ...[
          _Row(label: 'آخر تسوية', value: snapshot.lastSettledOn!),
          _Row(
            label: 'التسوية القادمة',
            value: due ?? '—',
            emphasised: true,
            hint: snapshot.settlementIsOverdue ? 'متأخرة' : null,
          ),
        ],
      ],
    );
  }
}

class _PositionSection extends StatelessWidget {
  const _PositionSection({required this.snapshot});

  final SettlementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'الوضع الحالي',
      children: [
        _Row(label: 'رأس مال المستثمرين', value: snapshot.investorCapital),
        _Row(label: 'رأس مال الشركة', value: snapshot.companyCapital),
        _Row(
          label: 'إجمالي رأس المال',
          value: snapshot.totalCapital,
          emphasised: true,
        ),
        const Divider(),
        _Row(label: 'قابل للصرف', value: snapshot.deployableCash),
        _Row(label: 'بضاعة بالتكلفة', value: snapshot.stockAtCost),

        // Real money the company is holding that `deployable_cash` does not count as spendable.
        // Printed beside it and **never added to it** — whether this month's margin should buy
        // next month's lorry is the owner's decision, not this screen's.
        _Row(
          label: 'ربح الفترة الجارية غير الموزَّع',
          value: snapshot.undeployedCurrentProfit,
          hint: 'غير داخل في «قابل للصرف»',
        ),
        const Divider(),
        _Row(
          label: 'مستحقات على الزبائن',
          value: snapshot.receivables,
          hint: 'مُثبتة كربح ولم تُحصَّل بعد',
        ),
        _Row(
          label: 'أرباح مستحقة لم تُسحب',
          value: snapshot.liabilities,
          hint: 'مال بيد الشركة لا تملكه — لا يُستعمل كرأس مال عامل',
        ),
        const Divider(),
        _Row(label: 'تالف حتى تاريخه', value: snapshot.damageToDate),
        _Row(label: 'نقص حتى تاريخه', value: snapshot.shortageToDate),
        _Row(
          label: 'أرباح موزَّعة حتى تاريخه',
          value: snapshot.distributedProfitToDate,
        ),
        if (snapshot.companyAbsorbedLoss != '0.00')
          _Row(
            label: 'خسارة تحمّلتها الشركة',
            value: snapshot.companyAbsorbedLoss,
            hint: 'خسارة تجاوزت رأس مال الشريك',
          ),
      ],
    );
  }
}

class _SignSection extends StatelessWidget {
  const _SignSection({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'اعتماد التسوية',
      subtitle: 'تُثبَّت الأرقام أعلاه باسم من يعتمدها — ولا يتحرّك أي مال',
      children: [
        AppButton(
          label: 'اعتمد التسوية',
          onPressed: () async {
            final confirmed = await showCustomDialog(
              context: context,
              title: 'اعتماد التسوية',
              description:
                  'تُسجَّل أرقام الصندوق كما هي الآن، بتاريخ اليوم. '
                  'لا يتحرّك مال ولا تُقفَل فترة.',
              confirmLabel: 'اعتمد',
            );

            if (!(confirmed ?? false) || !context.mounted) return;

            final failure = await context.read<PoolSettlementsCubit>().sign(
              poolId: poolId,
            );

            if (!context.mounted) return;

            if (failure != null) {
              context.showError(failure.message);

              return;
            }

            context.showSuccess('سُجّلت التسوية');
          },
        ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.settlements});

  final List<InvestmentSettlement> settlements;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PoolSection(
      title: 'تسويات سابقة',
      children: [
        if (settlements.isEmpty)
          const Text('لا تسويات بعد')
        else
          for (final settlement in settlements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                settlement.hasDrift
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: settlement.hasDrift ? scheme.error : null,
              ),
              title: Text(
                '${settlement.code ?? ''} · ${settlement.settledOn ?? ''}',
              ),
              subtitle: Text(
                settlement.hasDrift
                    ? 'فرق ${settlement.drift.grouped}'
                    : 'مطابقة · رأس المال ${settlement.totalCapital.grouped}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: settlement.hasDrift
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.hint,
    this.emphasised = false,
  });

  final String label;
  final String value;

  /// One quiet line under the figure, for the thing somebody would otherwise assume wrongly.
  final String? hint;

  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (hint != null)
            Text(
              hint!,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
