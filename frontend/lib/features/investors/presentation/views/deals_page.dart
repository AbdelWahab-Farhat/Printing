import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deals_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/deal_card.dart';
import 'package:dayaa/features/investors/presentation/widgets/deal_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// صفقات المستثمرين — one financed purchase of stock apiece.
class InvestorDealsPage extends StatelessWidget {
  const InvestorDealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DealsCubit>(
      create: (_) => sl<DealsCubit>()..load(),
      child: const _DealsView(),
    );
  }
}

class _DealsView extends StatefulWidget {
  const _DealsView();

  @override
  State<_DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<_DealsView> {
  String? _status;

  static const _statuses = <(String?, String)>[
    (null, 'الكل'),
    ('draft', 'مسودة'),
    ('open', 'مفتوحة'),
    ('closed', 'مغلقة'),
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DealsCubit>();
    final canManage = sl<Session>().can(AppPermission.manageInvestors);

    return Scaffold(
      appBar: AppBar(title: const Text('صفقات المستثمرين')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'deals-add',
              onPressed: () async {
                final created = await showDealFormSheet(context: context);
                if (created == true) await cubit.refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('صفقة جديدة'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(hint: 'ابحث بالاسم أو الرمز', onChanged: cubit.search),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (value, label) in _statuses)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterOptionChip(
                      label: label,
                      isSelected: _status == value,
                      onTap: () {
                        setState(() => _status = value);
                        cubit.filter(status: value);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DealsCubit, PagedState<InvestorDeal>>(
              builder: (context, state) => PagedListView<InvestorDeal>(
                state: state,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                emptyMessage: 'لا توجد صفقات',
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                itemBuilder: (context, deal, index) => DealCard(
                  deal: deal,
                  onTap: () => context.push(Routes.investorDeal(deal.id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
