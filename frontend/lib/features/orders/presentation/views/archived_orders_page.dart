import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/archived_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_filter_button.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_sort_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أرشيف الطلبيات — the deleted orders, and only those.
///
/// **This is [OrdersPage] with a different source, deliberately and almost literally.** The same
/// search box asking the same three questions, the same sort button, the same filter sheet with
/// its own counts, the same [OrderCard], the same patching on the way back from a detail screen.
/// What differs is one Cubit and one app bar.
///
/// **It is not [FilteredOrdersPage], and §٨ settles that.** That screen answers a question fixed
/// before it opens, carried in an `OrdersFilter` — six fields, no `isUrgent`, no `cityId`, no
/// search, and an `initialSort` that is a derived getter. Somebody who narrowed الطلبيات to
/// «الجاهزة المستعجلة غير المدفوعة» and then went looking for a deleted one cannot ask the same
/// question there at all. So the archive keeps the screen rather than the question.
///
/// **A screen and not a tab**: it is reached from the drawer, it is where somebody goes to check
/// what was removed, and the bottom bar must not claim they are still on a tab they left. That
/// is also why it owns a `Scaffold` with a real app bar, where [OrdersPage] is a body under the
/// shell's.
///
/// **No status moves appear on these rows, and nothing here suppresses them.** A trashed order
/// arrives with no `available_transitions`, so the shared card simply draws none — see §٦, where
/// dropping that key is called correctness rather than economy. Deleting and restoring live on
/// the order's own screen, behind their own grants.
class ArchivedOrdersPage extends StatelessWidget {
  const ArchivedOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArchivedOrdersCubit>(
      create: (_) => sl<ArchivedOrdersCubit>()..load(),
      child: const _ArchivedOrdersView(),
    );
  }
}

class _ArchivedOrdersView extends StatelessWidget {
  const _ArchivedOrdersView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArchivedOrdersCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('أرشيف الطلبيات')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                // The same box as الطلبيات, hint and all: the archive is searched by the same
                // three things, and a second wording for one list would read as a second rule.
                Expanded(
                  child: SearchField(
                    hint: 'رقم الطلبية · كود العميل · رقم الهاتف',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 10.w),
                // Rebuilt with the list for the reason الطلبيات gives: what the sheet says is
                // ticked and what is on screen cannot disagree.
                BlocBuilder<ArchivedOrdersCubit, OrdersState>(
                  builder: (context, state) => Row(
                    children: [
                      OrderSortButton(sort: cubit.sort, onToggled: cubit.showSort),
                      SizedBox(width: 6.w),
                      // The very same widget, fed the archive's own counts — which are counted
                      // over the archive. Two rows of chips describing two different sets is
                      // §٦'s worst failure, and it is avoided by there being one source here.
                      OrderFilterButton(
                        selected: cubit.status,
                        selectedPayments: cubit.paymentStatuses,
                        selectedUrgency: cubit.isUrgent,
                        counts: cubit.counts,
                        onApplied: (status, payments, isUrgent) => cubit.showFilters(
                          status: status,
                          paymentStatuses: payments,
                          isUrgent: isUrgent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ArchivedOrdersCubit, OrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                emptyMessage: 'لا توجد طلبيات محذوفة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // The card's measured height, the same number الطلبيات uses — it is the same
                // card, so a different skeleton would jump when the rows arrived.
                skeletonHeight: 380.h,
                itemBuilder: (context, order, index) => OrderCard(
                  key: ValueKey(order.id),
                  order: order,
                  onTap: () async {
                    // The detail screen hands the order back whatever it did to it, exactly as
                    // it does for الطلبيات — and a restored one stops belonging here, so the row
                    // leaves this list with no request. See [ArchivedOrdersCubit.belongs].
                    final moved = await context.pushForResult<Order>(Routes.order(order.id));
                    if (moved != null) cubit.replace(moved);
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
