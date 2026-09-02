import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/filtered_purchase_orders_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/purchase_order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The purchase orders behind one number.
///
/// **Opened from a supplier's screen**, and it exists so that tap can be honest: the row carries
/// its own title and its own filter, and this screen shows exactly what was counted. The tab
/// cannot answer «الجارية لهذا المورد» — its chips take one status and no vendor at all.
///
/// No filter control on it: the question was settled by the tap. See
/// VENDOR-PURCHASE-ORDERS-SECTION.md.
class FilteredPurchaseOrdersPage extends StatelessWidget {
  const FilteredPurchaseOrdersPage({required this.filter, super.key});

  final PurchaseOrdersFilter filter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FilteredPurchaseOrdersCubit>(
      create: (_) => sl<FilteredPurchaseOrdersCubit>(param1: filter)..load(),
      child: _FilteredPurchaseOrdersView(title: filter.title),
    );
  }
}

class _FilteredPurchaseOrdersView extends StatelessWidget {
  const _FilteredPurchaseOrdersView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FilteredPurchaseOrdersCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<FilteredPurchaseOrdersCubit, FilteredPurchaseOrdersState>(
        builder: (context, state) => PagedListView<PurchaseOrder>(
          state: state,
          // Named after what was asked for: «لا توجد أوامر شراء» on a screen titled «الجارية»
          // leaves the reader wondering whether the filter or the shop is empty.
          emptyMessage: 'لا توجد أوامر شراء في «$title»',
          onLoadMore: cubit.loadMore,
          onRefresh: cubit.refresh,
          skeletonHeight: 96.h,
          itemBuilder: (context, order, index) => PurchaseOrderCard(
            key: ValueKey(order.id),
            order: order,
            onTap: () async {
              // The detail screen hands the order back when it changed one, so the row redraws
              // itself with no request — and leaves this screen when the change took it out of
              // the question the screen was opened to ask.
              final changed = await context.push<PurchaseOrder>(
                Routes.purchaseOrder(order.id),
                extra: order,
              );

              if (changed != null) cubit.replace(changed);
            },
          ),
        ),
      ),
    );
  }
}
