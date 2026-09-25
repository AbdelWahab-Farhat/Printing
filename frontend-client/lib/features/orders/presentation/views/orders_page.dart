import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_card.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/stage_filter_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «طلباتي».
///
/// **The workshop's nineteen statuses arrive as eight stages**, and the collapsing happens on
/// the server — see `CustomerOrderStage`. Nothing on this screen translates a status: the
/// label and the hint line both travel with the value, so a stage added to the business appears
/// without an app release.
///
/// The one thing decided here is the **colour** of the pill, because a colour is not a
/// translation — and [stageTone] is total over [OrderStage] with `unknown` falling to the
/// neutral fill, so a stage this build has never heard of gets a pill rather than nothing.
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
      appBar: AppBar(title: const Text('طلباتي')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              // الحالات خلف حقلٍ واحد يفتح ورقةً سفلية — انظر [StageFilterField] لماذا لا شرائح
              // ولا قائمة منسدلة.
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) => StageFilterField(
                  selected: cubit.filter,
                  onChanged: cubit.narrowTo,
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) => PagedListView<CustomerOrder>(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  // القائمة الفارغة تقول أيّ سؤالٍ سُئل: «لم تطلب شيئاً بعد» تحت شريحة «جاهزة»
                  // تُخبر عميلاً له تسع طلبيات أنه لا يملك شيئاً.
                  emptyMessage: cubit.filter == OrdersFilter.all
                      ? 'لم تطلب شيئاً بعد'
                      : 'لا طلبيات «${cubit.filter.label}»',
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemBuilder: (context, order, index) => Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: OrderCard(order: order),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
