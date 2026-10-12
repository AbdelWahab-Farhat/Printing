import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_expenses_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_periods_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_expense_card.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «مصاريف الصندوق» — كلُّ مصاريفه، وبجانب كلٍّ فترتُه، وفلترٌ بالفترة.
///
/// طلبُ المالك 2026-10-12: «المصاريف خليني اقدر اخش عليها من هنا مباشرة، وتعرض لي كل مصاريف
/// وبجانبها الفترة الخاصة بها واقدر افلتر حسب الفترة». كانت لا تُرى إلا فترةً فترة، من تبويبٍ في
/// شاشة كلٍّ منها.
///
/// **فوق القائمة رقمُها في بطاقة اللوحة نفسِها** ([FundTotalCard]) كسائر ما يُفتح منها، وتحته
/// الفترات شرائحَ بنقطة لون حالتها. والبطاقةُ تُفتح على فترتها، على تبويب «المصاريف» — هناك نصيبُ
/// كلِّ مستثمرٍ وزرُّ العكس.
class FundExpensesPage extends StatelessWidget {
  const FundExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FundExpensesCubit(getExpenses: sl())..load()),
        BlocProvider(create: (_) => InvestmentPeriodsCubit(getPeriods: sl())..load()),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('مصاريف الصندوق')),
        body: BlocBuilder<FundExpensesCubit, PagedState<FundExpense>>(
          builder: (context, state) {
            final cubit = context.read<FundExpensesCubit>();

            return PagedListView<FundExpense>(
              state: state,
              header: const _Header(),
              emptyMessage: cubit.periodId == null
                  ? 'لا مصاريف على الصندوق'
                  : 'لا مصاريف على الصندوق في هذه الفترة',
              onLoadMore: cubit.loadMore,
              onRefresh: cubit.refresh,
              skeletonHeight: 120.h,
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              itemBuilder: (context, expense, index) => FundExpenseCard(
                key: ValueKey(expense.id),
                expense: expense,
                onTap: switch ((expense.purchaseOrder, expense.period)) {
                  // **مصروفٌ على البضاعة يُفتح على أمر شرائه** — طلبُ المالك 2026-10-12. فترتُه قد
                  // لا تحمل منه شيئاً (كلُّه على الرفّ)، فشاشتُها لا تذكره.
                  (final order?, _) when sl<Session>().can(AppPermission.viewPurchaseOrders) =>
                    () => context.push(Routes.purchaseOrder(order.id)),
                  (_, final period?) => () => context.push(
                    Routes.investmentPeriodExpenses(period.id),
                    extra: period.code,
                  ),
                  _ => null,
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// المجموعُ وشرائحُ الفترات — يمرّان مع القائمة، فلا يأخذان من الشاشة ما يأخذه رأسٌ ثابت.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<FundExpensesCubit>();
    final periods = switch (context.watch<InvestmentPeriodsCubit>().state) {
      InvestmentPeriodsLoaded(:final periods) => periods,
      _ => const <FundPeriod>[],
    };

    return ColoredBox(
      color: context.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FundTotalCard(label: _totalLabel(cubit.periodId, periods), amount: cubit.total),
            SizedBox(height: 12.h),
            // يلتفّ ولا يُمرَّر — كشرائح «المصاريف» في المالية: شريحةٌ خارج الحافة فلترٌ لا يجده أحد.
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                FilterOptionChip(
                  key: const ValueKey('expenses-period-all'),
                  label: 'الكل',
                  isSelected: cubit.periodId == null,
                  onTap: () => unawaited(cubit.showPeriod(null)),
                ),
                for (final period in periods)
                  FilterOptionChip(
                    key: ValueKey('expenses-period-${period.id}'),
                    label: period.code,
                    dot: PeriodStatusTone.of(context.colorScheme, period.status).dot,
                    isSelected: cubit.periodId == period.id,
                    onTap: () => unawaited(cubit.showPeriod(period.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _totalLabel(int? periodId, List<FundPeriod> periods) {
    if (periodId == null) return 'كل المصاريف';

    final code = periods.where((period) => period.id == periodId).firstOrNull?.code;

    return code == null ? 'مصاريف الفترة' : 'مصاريف الفترة $code';
  }
}
