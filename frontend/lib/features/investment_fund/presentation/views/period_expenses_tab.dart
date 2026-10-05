import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/period_expenses_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_expense_card.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// تبويبُ «المصاريف» في شاشة الفترة — «لعرض المصاريف الخاصة بهذه الفترة وضمان الشفافية
/// للمستثمرين».
///
/// **والمجاميعُ كما وصلت.** الخادمُ يعرف أيُّ مصروفٍ يُعدّ في الفترة وأيُّها لا، وجمعُها هنا
/// تعريفٌ ثانٍ يخالفه يوم يُعكَس سطر.
class PeriodExpensesTab extends StatelessWidget {
  const PeriodExpensesTab({required this.periodId, super.key});

  final int periodId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PeriodExpensesCubit(
        periodId: periodId,
        getExpenses: sl(),
        reverseExpense: sl(),
      )..load(),
      child: BlocBuilder<PeriodExpensesCubit, PeriodExpensesState>(
        builder: (context, state) => switch (state) {
          PeriodExpensesLoading() => const Center(child: CircularProgressIndicator()),
          PeriodExpensesFailure(:final failure) => _Retry(message: failure.message),
          PeriodExpensesLoaded(:final held) => RefreshIndicator(
            onRefresh: () => context.read<PeriodExpensesCubit>().load(),
            child: _Body(held: held),
          ),
        },
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<PeriodExpensesCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.held});

  final PeriodExpenses held;

  @override
  Widget build(BuildContext context) {
    final canReverse = sl<Session>().can(AppPermission.reverseInvestorMoney);

    VoidCallback? reverseOf(PeriodExpense expense) => canReverse && expense.canReverse
        ? () => unawaited(_reverse(context, expense))
        : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        _Totals(totals: held.totals),
        SizedBox(height: 24.h),
        Text(
          'مصاريف الفترة',
          style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        if (held.expenses.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text('لا مصاريف على الصندوق في هذه الفترة', style: context.textTheme.bodyMedium),
          )
        else
          for (final expense in held.expenses)
            PeriodExpenseCard(
              key: ValueKey(expense.id),
              expense: expense,
              onReverse: reverseOf(expense),
            ),
        if (held.corrections.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'تصحيحات من فترات سابقة',
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            'مصاريف من فترةٍ أُقفلت، وقع ما حُمِّل أو رُدّ منها على هذه الفترة',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          for (final expense in held.corrections)
            PeriodExpenseCard(
              key: ValueKey('correction-${expense.id}'),
              expense: expense,
              onReverse: reverseOf(expense),
            ),
        ],
      ],
    );
  }

  Future<void> _reverse(BuildContext context, PeriodExpense expense) async {
    final cubit = context.read<PeriodExpensesCubit>();

    final reason = await askForReason(
      context,
      title: 'عكس «${expense.name}»',
      confirmLabel: 'عكس المصروف',
    );

    if (reason == null || !context.mounted) return;

    final failure = await cubit.reverse(expense, reason: reason);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('عُكس المصروف — عاد المالُ إلى الخزينة ونقدِ الصندوق');
  }
}

/// مجموعُ الفترة: ما خرج من الصندوق، وما تحمّله المستثمرون منه.
class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final PeriodExpensesTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final onInvestors = totals.investorsTotal;
    final refunded = onInvestors.startsWith('-');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            'مصاريف الفترة',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${totals.expensesTotal.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            refunded
                ? 'رُدَّ إلى المستثمرين ${onInvestors.substring(1).grouped} د.ل'
                : 'منها على المستثمرين ${onInvestors.grouped} د.ل',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
