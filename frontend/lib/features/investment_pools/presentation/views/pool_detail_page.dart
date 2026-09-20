import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/investment_pools/models/capital_request.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/models/pool_expense.dart';
import 'package:dayaa/features/investment_pools/models/returned_goods_question.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/pool_detail_cubit.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/capital_request_sheet.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_expense_sheet.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_form_sheet.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_section.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/returned_goods_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One صندوق: what it holds, what it may spend, and what is waiting on somebody.
///
/// **The open returned-goods questions sit above everything else on purpose.** They are the one
/// thing on this screen that blocks an action somebody will try to take at the end of the month,
/// and a person who meets them for the first time on the close screen has already decided to
/// close.
class PoolDetailPage extends StatelessWidget {
  const PoolDetailPage({required this.poolId, super.key});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PoolDetailCubit>(
      create: (_) => sl<PoolDetailCubit>()..load(poolId),
      child: _PoolDetailView(poolId: poolId),
    );
  }
}

class _PoolDetailView extends StatelessWidget {
  const _PoolDetailView({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoolDetailCubit, PoolDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(switch (state) {
            PoolDetailLoaded(:final pool) => pool.name,
            _ => 'الصندوق',
          }),
          actions: [
            if (state case PoolDetailLoaded(:final pool))
              PermissionGate(
                permission: AppPermission.manageInvestors,
                child: IconButton(
                  tooltip: 'تعديل الصندوق',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final updated = await showPoolFormSheet(
                      context: context,
                      pool: pool,
                    );

                    if (updated != null && context.mounted) {
                      await context.read<PoolDetailCubit>().load(poolId);
                    }
                  },
                ),
              ),
          ],
        ),
        body: switch (state) {
          PoolDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PoolDetailFailure(:final failure) => _Failure(
            message: failure.message,
            onRetry: () => context.read<PoolDetailCubit>().load(poolId),
          ),
          PoolDetailLoaded() => _Loaded(state: state, poolId: poolId),
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.poolId});

  final PoolDetailLoaded state;
  final int poolId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PoolDetailCubit>();

    return RefreshIndicator(
      onRefresh: () => cubit.load(poolId),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
        children: [
          // First, because it is the only thing here that stops somebody doing something.
          if (state.openQuestions.isNotEmpty) ...[
            _ReturnedGoodsSection(
              questions: state.openQuestions,
              poolId: poolId,
            ),
            SizedBox(height: 16.h),
          ],

          _MoneySection(cash: state.cash),
          SizedBox(height: 16.h),

          _ShelvesSection(pool: state.pool),
          SizedBox(height: 16.h),

          _MembersSection(pool: state.pool),
          SizedBox(height: 16.h),

          _CapitalSection(
            pool: state.pool,
            requests: state.capitalRequests,
            poolId: poolId,
          ),
          SizedBox(height: 16.h),

          _ExpensesSection(poolId: poolId, expenses: state.expenses),
          SizedBox(height: 16.h),

          _LinksSection(poolId: poolId),
        ],
      ),
    );
  }
}

/// «بضاعة راجعة لم تُفحص» — the close is refused while any of these is open.
class _ReturnedGoodsSection extends StatelessWidget {
  const _ReturnedGoodsSection({required this.questions, required this.poolId});

  final List<ReturnedGoodsQuestion> questions;
  final int poolId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PoolSection(
      title: 'بضاعة راجعة تنتظر الفحص',
      tone: PoolSectionTone.warning,
      // Said plainly rather than left to be discovered on the close screen: the person reading
      // this is the one who can clear it.
      subtitle: 'لن تُقفَل الفترة قبل الإجابة عنها',
      children: [
        for (final question in questions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(question.stockItemName ?? 'مادة'),
            subtitle: Text(
              'طلبية ${question.orderCode ?? question.orderId.grouped}'
              ' · ${question.quantity.grouped}'
              ' · بتكلفة ${question.cost.grouped}',
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            trailing: AppButton(
              label: 'افحص',
              onPressed: () => showReturnedGoodsSheet(
                context: context,
                question: question,
                poolId: poolId,
              ),
            ),
          ),
      ],
    );
  }
}

/// What the pool may spend, and what it is holding.
///
/// **`unsettled_profit` and `deployable_cash` are printed apart and never summed.** Undrawn
/// profit is money the company holds and does not own; a total would invite somebody to spend it.
class _MoneySection extends StatelessWidget {
  const _MoneySection({required this.cash});

  final PoolDeployableCash? cash;

  @override
  Widget build(BuildContext context) {
    final value = cash;

    if (value == null) {
      return const PoolSection(
        title: 'المال',
        children: [Text('تعذّر حساب أرقام الصندوق')],
      );
    }

    return PoolSection(
      title: 'المال',
      children: [
        _MoneyRow(label: 'رأس المال', value: value.capital),
        _MoneyRow(label: 'قيمة الدفاتر', value: value.bookValue),
        _MoneyRow(label: 'بضاعة بالتكلفة', value: value.stockAtCost),
        const Divider(),
        _MoneyRow(
          label: 'قابل للصرف',
          value: value.deployableCash,
          emphasised: true,
        ),
        _MoneyRow(label: 'ربح غير موزَّع', value: value.unsettledProfit),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
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
    final style = context.textTheme.bodyMedium?.copyWith(
      fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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
          Text(value.grouped, style: style, textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

class _ShelvesSection extends StatelessWidget {
  const _ShelvesSection({required this.pool});

  final InvestmentPool pool;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'المواد',
      // The invariant, said once where somebody might otherwise wonder why a shelf is missing.
      subtitle: 'كل مادة تتبع صندوقاً واحداً فقط',
      children: [
        if (pool.stockItems.isEmpty)
          const Text('لا مواد بعد')
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final item in pool.stockItems)
                Chip(label: Text(item.name ?? 'مادة ${item.stockItemId}')),
            ],
          ),
      ],
    );
  }
}

/// Who is in it — **without a percentage**, because there is no stored one.
///
/// A pool's ownership is a capital ratio recomputed at every close. Printing a share here would
/// mean inventing a number that is only true until the next movement.
class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.pool});

  final InvestmentPool pool;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'الشركاء',
      subtitle: 'النسبة الآن من رأس المال — وتُحسب من جديد عند كل إقفال',
      children: [
        if (pool.investors.isEmpty)
          const Text('لا شركاء بعد')
        else
          for (final member in pool.investors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(
                    child: Text(member.name ?? 'مستثمر ${member.investorId}'),
                  ),
                  // His weight **now**, and what it is a weight of. Printed together because
                  // neither is much use alone: a percentage with no money behind it invites the
                  // question this row exists to answer.
                  Text(
                    '${member.sharePercent.grouped}٪',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    member.capital.grouped,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // **Said here, before he asks.** A refusal at the capital form with a date he has
              // never seen is a refusal he has to come back and ask about; this is the same date
              // the server would then give him.
              subtitle: member.capitalFreeOn == null
                  ? null
                  : Text(
                      'لا يُسحب رأس ماله قبل ${member.capitalFreeOn}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
              trailing: member.isCompany
                  ? const Chip(label: Text('الشركة'))
                  : null,
            ),
      ],
    );
  }
}

/// The capital queue, and the button that adds to it.
class _CapitalSection extends StatelessWidget {
  const _CapitalSection({
    required this.pool,
    required this.requests,
    required this.poolId,
  });

  final InvestmentPool pool;
  final List<CapitalRequest> requests;
  final int poolId;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final pending = requests.where((r) => r.canBeCancelled).toList();

    return PoolSection(
      title: 'رأس المال',
      children: [
        if (pending.isEmpty)
          const Text('لا طلبات معلّقة')
        else
          for (final request in pending)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${request.directionLabel} · ${request.amount.grouped}',
              ),
              subtitle: Text(
                request.investor?.name ?? 'مستثمر ${request.investorId}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                tooltip: 'إلغاء الطلب',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final failure = await context
                      .read<PoolDetailCubit>()
                      .cancelCapitalRequest(
                        poolId: poolId,
                        requestId: request.id,
                      );

                  if (failure != null && context.mounted) {
                    await showCustomSnackBar(
                      context: context,
                      title: failure.message,
                      type: SnackType.error,
                    );
                  }
                },
              ),
            ),
        SizedBox(height: 8.h),
        AppButton(
          label: 'حركة رأس مال',
          onPressed: () => showCapitalRequestSheet(
            context: context,
            poolId: poolId,
            timing: pool.capitalTiming,
          ),
        ),
      ],
    );
  }
}

/// Costs charged to the pool, and the button that adds one.
///
/// **The list is here because a form with no list is a form people fill in twice.** It was built
/// with only the button, on the argument that the close screen is where a cost matters — which is
/// true of the *total* and useless to somebody who has just pressed save and wants to know it
/// landed.
///
/// **«محسوبة مسبقاً» rows are drawn differently on purpose.** Shipping and customs typed on a
/// purchase order are already inside the cost of the goods; printed identically to a deducted row
/// they invite somebody to add up a total the close does not use.
class _ExpensesSection extends StatelessWidget {
  const _ExpensesSection({required this.poolId, required this.expenses});

  final int poolId;
  final List<PoolExpense> expenses;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PoolSection(
      title: 'المصاريف',
      subtitle: 'تُخصم من ربح الفترة التي تُسجَّل فيها',
      children: [
        if (expenses.isEmpty)
          Text(
            'لا مصاريف بعد',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final expense in expenses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Row(
                children: [
                  Expanded(child: Text(expense.name)),
                  Text(
                    expense.amount.grouped,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      // A row that is not subtracted must not read like one that is.
                      color: expense.isDeducted ? null : scheme.onSurfaceVariant,
                      decoration: expense.isReversed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                [
                  expense.kindLabel,
                  if (expense.incurredOn != null) expense.incurredOn!,
                  if (!expense.isDeducted) 'محسوبة مسبقاً — لا تُخصم',
                ].join(' · '),
                style: context.textTheme.bodySmall?.copyWith(
                  color: expense.isDeducted
                      ? scheme.onSurfaceVariant
                      : scheme.tertiary,
                ),
              ),
            ),
        SizedBox(height: 8.h),
        AppButton(
          label: 'سجّل مصروفة',
          onPressed: () async {
            final saved = await showPoolExpenseSheet(
              context: context,
              poolId: poolId,
            );

            // An expense moves what the period is worth, and the close screen reads it from
            // there — but the pool's own cash figure moved too, so the screen is reloaded.
            if (saved && context.mounted) {
              await context.read<PoolDetailCubit>().load(poolId);
            }
          },
        ),
      ],
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.poolId});

  final int poolId;

  @override
  Widget build(BuildContext context) {
    return PoolSection(
      title: 'أكثر',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('الفترات'),
          onTap: () => context.push(Routes.investmentPoolPeriods(poolId)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fact_check_outlined),
          title: const Text('التسويات'),
          onTap: () => context.push(Routes.investmentPoolSettlements(poolId)),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            AppButton(label: 'أعد المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
