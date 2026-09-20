import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/presentation/viewmodel/investment_pools_cubit.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_card.dart';
import 'package:dayaa/features/investment_pools/presentation/widgets/pool_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صناديق الاستثمار — one continuous pool per material.
///
/// **No status filter, unlike the deals list.** A صفقة was open or closed and people needed to
/// choose; a صندوق never closes, so there is nothing here to narrow by and a control offering to
/// would be a control with one answer.
class InvestmentPoolsPage extends StatelessWidget {
  const InvestmentPoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvestmentPoolsCubit>(
      create: (_) => sl<InvestmentPoolsCubit>()..load(),
      child: const _PoolsView(),
    );
  }
}

class _PoolsView extends StatelessWidget {
  const _PoolsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvestmentPoolsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('صناديق الاستثمار')),
      // Behind `investors.manage`: opening a pool moves no money, but it decides where money will
      // go — and which shelf is spoken for, which no second pool can then claim.
      floatingActionButton: PermissionGate(
        permission: AppPermission.manageInvestors,
        child: FloatingActionButton.extended(
          // Every tab stays mounted in the shell, so two FABs share the default tag and assert on
          // every frame. `FloatingActionButtonHeroTest` enforces this rather than trusting memory.
          heroTag: 'fab-investment-pools',
          onPressed: () async {
            final opened = await showPoolFormSheet(context: context);
            if (opened != null) await cubit.refresh();
          },
          icon: const Icon(Icons.add),
          label: const Text('صندوق جديد'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث بالاسم أو الرمز',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<InvestmentPoolsCubit, PagedState<InvestmentPool>>(
              builder: (context, state) => PagedListView<InvestmentPool>(
                state: state,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                emptyMessage: 'لا توجد صناديق',
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                skeletonHeight: 92.h,
                itemBuilder: (context, pool, index) => PoolCard(
                  key: ValueKey(pool.id),
                  pool: pool,
                  // The pool screen hands the pool back when something changed its name or its
                  // shelves, and nothing when it was only read — so a list scrolled halfway down
                  // is not thrown back to the top to redraw one card.
                  onTap: () async {
                    final changed = await context.pushForResult<InvestmentPool>(
                      Routes.investmentPool(pool.id),
                    );
                    if (changed != null) cubit.replace(changed);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
