import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/core/widgets/search_field.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:printing/features/orders/presentation/widgets/order_card.dart';

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
            child: SearchField(
              hint: 'ابحث برقم الطلبية أو اسم العميل',
              onChanged: cubit.search,
            ),
          ),
          // Rebuilt with the list, so the selected chip and what is on screen cannot disagree.
          BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) =>
                _QueueBar(selected: cubit.queue, onSelected: cubit.showQueue),
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                emptyMessage: 'لا توجد طلبيات في هذه القائمة',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // The measured height of a card with a customer, a destination and a count.
                skeletonHeight: 132.h,
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

/// The queues staff actually think in.
///
/// Not one chip per status: «قيد التنفيذ» is two statuses and «رواجع» is three, and asking
/// somebody to tap each separately to see the work in the workshop would be making them do the
/// grouping the screen should have done. See [OrderQueue].
class _QueueBar extends StatelessWidget {
  const _QueueBar({required this.selected, required this.onSelected});

  final OrderQueue selected;
  final ValueChanged<OrderQueue> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: OrderQueue.values.length,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final queue = OrderQueue.values[index];
          final isSelected = queue == selected;

          return ChoiceChip(
            label: Text(queue.label),
            selected: isSelected,
            // Tapping the chip that is already on is not a way to clear it: «الكل» is, and it
            // is the first one in the row.
            onSelected: (_) => onSelected(queue),
            showCheckmark: false,
            backgroundColor: scheme.surfaceContainerLowest,
            selectedColor: scheme.primaryContainer,
            labelStyle: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            side: BorderSide(
              color: isSelected ? Colors.transparent : scheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          );
        },
      ),
    );
  }
}
