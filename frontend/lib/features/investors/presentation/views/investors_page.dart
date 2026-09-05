import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_card.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// المستثمرون — the people whose money finances the stock, on a screen of their own.
///
/// **Kept for the deep links**, though the tab under «الجهات» is where somebody normally arrives.
class InvestorsPage extends StatelessWidget {
  const InvestorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvestorsCubit>(
      create: (_) => sl<InvestorsCubit>()..load(),
      child: const _InvestorsView(),
    );
  }
}

class _InvestorsView extends StatelessWidget {
  const _InvestorsView();

  @override
  Widget build(BuildContext context) {
    final canManage = sl<Session>().can(AppPermission.manageInvestors);

    return Scaffold(
      appBar: AppBar(title: const Text('المستثمرون')),
      // A ternary yielding null rather than a gate widget: a `PermissionGate` here would still
      // occupy the slot and shift the bottom inset for everybody who cannot see the button.
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'investors-add',
              onPressed: () => addInvestor(context),
              icon: Icon(AppIcons.add),
              label: const Text('مستثمر جديد'),
            )
          : null,
      body: const InvestorsBody(),
    );
  }
}

/// Adds an investor and reloads the list behind it.
///
/// Top-level so the «إضافة» dial on [PartiesPage] can call it. A reload rather than a patch,
/// unlike the other two registers: the create endpoint answers with the investor alone, and a
/// row inserted without his balances would draw a person worth nothing.
Future<void> addInvestor(BuildContext context) async {
  final cubit = context.read<InvestorsCubit>();

  final created = await showInvestorFormSheet(context: context);

  if (created == true) await cubit.refresh();
}

/// The investors list itself — search box and rows, and nothing around them.
///
/// **A body, not a screen.** It is one tab of «الجهات» as well as the whole of [InvestorsPage],
/// so the bar and the button belong to whichever of the two is hosting it.
class InvestorsBody extends StatelessWidget {
  const InvestorsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvestorsCubit>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: SearchField(
            hint: 'ابحث بالاسم أو الرمز أو الهاتف',
            onChanged: cubit.search,
          ),
        ),
        Expanded(
          child: BlocBuilder<InvestorsCubit, PagedState<Investor>>(
            builder: (context, state) => PagedListView<Investor>(
              state: state,
              emptyMessage: 'لا يوجد مستثمرون بعد',
              onRefresh: cubit.refresh,
              onLoadMore: cubit.loadMore,
              skeletonHeight: 216.h,
              itemBuilder: (context, investor, index) => InvestorCard(
                key: ValueKey(investor.id),
                investor: investor,
                onTap: () => context.push(Routes.investor(investor.id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
