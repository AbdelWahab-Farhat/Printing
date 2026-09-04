import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investors_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_card.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// المستثمرون — the people whose money finances the stock.
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
    final cubit = context.read<InvestorsCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInvestors);

    return Scaffold(
      appBar: AppBar(title: const Text('المستثمرون')),
      // A ternary yielding null rather than a gate widget: a `PermissionGate` here would still
      // occupy the slot and shift the bottom inset for everybody who cannot see the button.
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'investors-add',
              onPressed: () async {
                final created = await showInvestorFormSheet(context: context);
                if (created == true) await cubit.refresh();
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('مستثمر جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              hint: 'ابحث بالاسم أو الرمز أو الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<InvestorsCubit, PagedState<Investor>>(
              builder: (context, state) => PagedListView<Investor>(
                state: state,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                emptyMessage: 'لا يوجد مستثمرون بعد',
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                itemBuilder: (context, investor, index) => InvestorCard(
                  investor: investor,
                  onTap: () => context.push(Routes.investor(investor.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
