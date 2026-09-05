import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/investors/models/deal_order.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_orders_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/deal_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «طلبيات الصفقة» — every order that sold this deal's goods, and what each one earned it.
///
/// The list is the record: the link between an order and a deal is the FIFO draw ledger, and the
/// money on each row is arithmetic over figures that were frozen when the order was. Nothing here
/// is stored, so nothing here can disagree with what was paid.
class DealOrdersPage extends StatelessWidget {
  const DealOrdersPage({required this.dealId, this.dealCode, super.key});

  final int dealId;

  /// Shown in the title when the screen was opened from the deal itself.
  final String? dealCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DealOrdersCubit>(
      create: (_) => sl<DealOrdersCubit>()..open(dealId),
      child: Builder(
        builder: (context) {
          final cubit = context.read<DealOrdersCubit>();

          return Scaffold(
            appBar: AppBar(
              title: Text(dealCode == null ? 'طلبيات الصفقة' : 'طلبيات $dealCode'),
            ),
            body: BlocBuilder<DealOrdersCubit, PagedState<DealOrder>>(
              builder: (context, state) => PagedListView<DealOrder>(
                state: state,
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                emptyMessage: 'لم تُبَع بضاعة هذه الصفقة في أي طلبية بعد',
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                skeletonHeight: 116.h,
                // The row is a door to the order itself. Nothing comes back through it: what
                // this list shows is arithmetic over the draw ledger, and the order's own
                // screen cannot change that.
                itemBuilder: (context, order, index) => DealOrderCard(
                  key: ValueKey(order.orderId),
                  order: order,
                  onTap: () => context.push(Routes.order(order.orderId)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
