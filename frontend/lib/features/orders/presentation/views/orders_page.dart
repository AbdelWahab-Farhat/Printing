import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الطلبيات — the work queue.
///
/// A body, not a screen: the app bar and the tabs belong to the shell above it.
///
/// **No "new order" button yet, and that is a stated gap rather than an oversight.** Taking an
/// order is a form with a customer, a destination, and a priced line per product — its own
/// slice, recorded in BACKLOG.md. What is here is what makes the workflow usable: seeing the
/// queues and moving orders through them.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>(
      create: (_) => sl<OrdersCubit>()..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();

    return Scaffold(
      // Transparent: the shell above owns the real Scaffold.
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                // One box, three questions. What was typed decides which one it is, and that
                // decision is the server's — duplicating the rule here would give the hint and
                // the results two chances to disagree. The hint's job is to say the box accepts
                // all three, not to classify.
                Expanded(
                  child: SearchField(
                    hint: 'رقم الطلبية · كود العميل · رقم الهاتف',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 10.w),
                // Rebuilt with the list, so the status ticked inside the sheet and what is on
                // screen cannot disagree.
                BlocBuilder<OrdersCubit, OrdersState>(
                  builder: (context, state) => OrderFilterButton(
                    selected: cubit.status,
                    selectedPayments: cubit.paymentStatuses,
                    counts: cubit.counts,
                    onApplied: (status, payments) =>
                        cubit.showFilters(status: status, paymentStatuses: payments),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                emptyMessage: 'لا توجد طلبيات في هذه القائمة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // The measured height of a card: a status chip, a rule and two rows of three
                // labelled facts.
                skeletonHeight: 172.h,
                itemBuilder: (context, order, index) => OrderCard(
                  key: ValueKey(order.id),
                  order: order,
                  onTap: () async {
                    // The detail screen hands back the order if it moved it, so the row updates
                    // without a round trip — and drops out of the list when it no longer belongs
                    // to the queue on screen.
                    final moved = await context.push<Order>(Routes.order(order.id));
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
