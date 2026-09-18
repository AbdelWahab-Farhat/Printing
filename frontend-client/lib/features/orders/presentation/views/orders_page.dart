import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/orders_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(
        title: const Text('طلباتي'),
        actions: const [NotificationsButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              // The design's four, and each one is a question the API already answers:
              // «الكل» is no filter, «قيد التنفيذ» is `open=1`, and the other two are `stage=`.
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) => SizedBox(
                  height: 44.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: OrdersFilter.values.length,
                    separatorBuilder: (context, index) => SizedBox(width: 8.w),
                    itemBuilder: (context, index) {
                      final filter = OrdersFilter.values[index];

                      return Center(
                        child: FilterOptionChip(
                          label: filter.label,
                          isSelected: cubit.filter == filter,
                          onTap: () => cubit.narrowTo(filter),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Expanded(
              child: BlocBuilder<OrdersCubit, OrdersState>(
                builder: (context, state) => PagedListView<CustomerOrder>(
                  state: state,
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  // The empty list says which question was asked. «لم تطلب شيئاً بعد» under a
                  // «جاهزة» chip would tell a customer with nine orders that they have none.
                  emptyMessage: switch (cubit.filter) {
                    OrdersFilter.all => 'لم تطلب شيئاً بعد',
                    OrdersFilter.open => 'لا توجد طلبيات قيد التنفيذ',
                    OrdersFilter.ready => 'لا توجد طلبيات جاهزة',
                    OrdersFilter.done => 'لم تستلم أي طلبية بعد',
                  },
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                  itemBuilder: (context, order, index) => _OrderCard(order: order),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#${order.code}',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (order.placedAt case final placedAt?) ...[
              SizedBox(width: 8.w),
              Text(
                placedAt.relativeDayLabel,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const Spacer(),
            StagePill(label: order.stageLabel, stage: order.stage),
          ],
        ),

        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // «كيس شحن فلاير ٣٠×٤٠ و٢ أخرى» — built by the server, so the list draws
                  // without opening every order to write itself a subtitle.
                  Text(
                    order.summary?.bidiSafe ?? 'طلبية',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order.itemsCount case final count? when count > 1) ...[
                    SizedBox(height: 3.h),
                    Text(
                      '$count منتجات',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10.w),
            // Smaller type for the phrase than for a figure: it is a sentence standing in for
            // a number, and at `titleSmall` weight it shouts over the order code.
            Text(
              order.total == null
                  ? awaitingQuoteLabel
                  : '${order.total!.asMoney} د.ل',
              style: order.total == null
                  ? context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    )
                  : context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
            ),
          ],
        ),

        // **The line under the divider, when the stage has one.** «تم الاستلام» and «ملغاة»
        // send none — the design draws no line under a finished order either, and a reassuring
        // sentence about something that is over is filler.
        if (order.stageHint case final hint?) ...[
          Divider(height: 22.h, color: scheme.outlineVariant),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );

    void open() => context.push(Routes.order(order.id));

    // The design gives the order that wants you an orange hairline. «بانتظار المراجعة» is the
    // one stage that is the customer's move to make — by waiting — and «قيد التصميم» the one
    // where they may be asked for something.
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: order.stage == OrderStage.underReview || order.stage == OrderStage.designing
          ? AppCard.accent(onTap: open, child: body)
          : AppCard(onTap: open, child: body),
    );
  }
}
