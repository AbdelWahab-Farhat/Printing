import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_orders_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/purchase_order_card.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/purchase_order_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// أوامر الشراء — what we have asked suppliers for, and how much of it has turned up.
class PurchaseOrdersPage extends StatelessWidget {
  const PurchaseOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PurchaseOrdersCubit>(
      create: (_) => sl<PurchaseOrdersCubit>()..load(),
      child: const _PurchaseOrdersView(),
    );
  }
}

class _PurchaseOrdersView extends StatelessWidget {
  const _PurchaseOrdersView();

  Future<void> _open(BuildContext context, PurchaseOrder order) async {
    final cubit = context.read<PurchaseOrdersCubit>();

    final changed = await context.push<bool>(
      Routes.purchaseOrder(order.id),
      extra: order,
    );

    if (changed ?? false) await cubit.refresh();
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<PurchaseOrdersCubit>();

    final saved = await context.push<bool>(Routes.purchaseOrderForm);

    if (saved ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PurchaseOrdersCubit>();
    final mayManage = sl<Session>().can(AppPermission.managePurchaseOrders);

    return Scaffold(
      appBar: AppBar(title: const Text('أوامر الشراء')),
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              heroTag: 'fab-purchase-orders',
              onPressed: () => _add(context),
              icon: Icon(AppIcons.add),
              label: const Text('أمر شراء'),
            )
          : null,
      body: Column(
        children: [
          // The same band every list in this app opens with: a box to type in, and the states
          // behind the round button beside it. They narrow together — see `PurchaseOrdersCubit`.
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    hint: 'ابحث بالمورد أو المخزن أو رقم الأمر',
                    onChanged: cubit.search,
                  ),
                ),
                SizedBox(width: 8.w),
                BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
                  // Rebuilt from the cubit rather than from a field on this widget, so the
                  // button's filled state and the list it describes cannot disagree.
                  builder: (context, _) => PurchaseOrderFilterButton(
                    selected: cubit.status,
                    onApplied: cubit.showStatus,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
              builder: (context, state) => PagedListView<PurchaseOrder>(
                state: state,
                // «لم يُنشأ أمر شراء بعد» about a *narrowed* list would say the file is empty
                // when it is the question that came back empty. The status is named where it is
                // the only thing narrowing, because «لا توجد أوامر في «ملغى»» is a more useful
                // sentence than the general one.
                emptyMessage: switch ((cubit.currentSearch, cubit.status)) {
                  (final search?, _) when search.isNotEmpty =>
                    'لا توجد أوامر تطابق «$search»',
                  (_, final status?) => 'لا توجد أوامر في «${status.label}»',
                  _ => 'لم يُنشأ أمر شراء بعد',
                },
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 96.h,
                itemBuilder: (context, order, index) => PurchaseOrderCard(
                  key: ValueKey(order.id),
                  order: order,
                  onTap: () => _open(context, order),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
