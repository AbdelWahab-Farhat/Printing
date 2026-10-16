import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_entry_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «المعاملات المالية» — حركات محافظ العملاء كلهم في صفحة، الأحدث أولاً، يُبحث فيها باسم العميل أو
/// هاتفه أو رمزه، وتُقصر على نوع. Docs/payments/CUSTOMER-WALLET.md.
///
/// **للقراءة**: اللمسةُ تفتح محفظة العميل، وهناك يُشحن ويُعدَّل ويُعكس — في سياق رصيده.
class WalletTransactionsPage extends StatelessWidget {
  const WalletTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletEntriesCubit>()..load(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletEntriesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('المعاملات المالية')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: SearchField(hint: 'ابحث باسم العميل أو هاتفه أو رمزه', onChanged: cubit.search),
          ),
          BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
            builder: (context, _) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: Row(
                children: [
                  for (final filter in WalletEntryFilter.values) ...[
                    if (filter != WalletEntryFilter.values.first) SizedBox(width: 8.w),
                    FilterOptionChip(
                      label: filter.label,
                      isSelected: cubit.filter == filter,
                      onTap: () => unawaited(cubit.narrowTo(filter)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
              builder: (context, state) {
                final items = state is PagedLoaded<CustomerWalletEntry>
                    ? state.page.items
                    : const <CustomerWalletEntry>[];

                return PagedListView<CustomerWalletEntry>(
                  state: state,
                  emptyMessage: 'لا معاملات',
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  skeletonHeight: 96.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  // The hairline of the investor's statement, whose rows these are drawn like.
                  separatorBuilder: (context, index) => const FundHairline(),
                  itemBuilder: (context, entry, index) {
                    final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
                    final row = CustomerWalletEntryRow(
                      key: ValueKey(entry.id),
                      entry: entry,
                      showCustomer: true,
                      onTap: () => _openWallet(context, entry),
                    );

                    if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DayHeader(at: at, first: index == 0),
                          row,
                        ],
                      );
                    }

                    return row;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// محفظة العميل — وحين يتحرّك فيها مال يُعاد هذا السجل، فالسطر الجديد مكانه أعلاه.
  Future<void> _openWallet(BuildContext context, CustomerWalletEntry entry) async {
    final cubit = context.read<WalletEntriesCubit>();
    final moved = await context.push<bool>(
      Routes.customerWallet(entry.customerId),
      extra: entry.customerName,
    );

    if (moved == true) await cubit.refresh();
  }
}
