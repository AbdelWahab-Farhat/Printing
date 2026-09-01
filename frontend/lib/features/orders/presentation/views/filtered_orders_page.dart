import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/orders_filter.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/filtered_orders_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The orders behind one number.
///
/// **Opened by tapping a card on the home screen**, and it exists so that tap can be honest: the
/// card carries its own title and its own filter, and this screen shows exactly what was
/// counted. A card for a date range — «طلبات اليوم» — has no status at all to hand the orders
/// tab, so the tab could not answer it without growing a second axis nobody asked for.
///
/// No filter control on it: the question was settled by the tap. What it keeps is the search,
/// because narrowing a long answer by a customer's name is a reasonable second thought.
class FilteredOrdersPage extends StatelessWidget {
  const FilteredOrdersPage({required this.filter, super.key});

  final OrdersFilter filter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FilteredOrdersCubit>(
      create: (_) => sl<FilteredOrdersCubit>(param1: filter)..load(),
      child: _FilteredOrdersView(title: filter.title),
    );
  }
}

class _FilteredOrdersView extends StatelessWidget {
  const _FilteredOrdersView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FilteredOrdersCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'رقم الطلبية · كود العميل · رقم الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<FilteredOrdersCubit, FilteredOrdersState>(
              builder: (context, state) => PagedListView<Order>(
                state: state,
                // Named after what was asked for: «لا توجد طلبيات» on a screen titled «نواقص»
                // leaves the reader wondering whether the filter or the shop is empty.
                emptyMessage: 'لا توجد طلبيات في «$title»',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 380.h,
                itemBuilder: (context, order, index) => OrderCard(
                  key: ValueKey(order.id),
                  order: order,
                  onTap: () async {
                    // The detail screen hands back the order if it moved it, so the row updates
                    // without a round trip — and leaves this screen when the move took it out
                    // of the answer.
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
