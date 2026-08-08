import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/paged_list_view.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/purchase_orders/presentation/viewmodel/purchase_orders_cubit.dart';

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

    final changed = await context.push<bool>(Routes.purchaseOrder(order.id), extra: order);

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
          // **Chips, not a search box.** The list endpoint accepts a status, a vendor and a
          // warehouse — and nothing to type into. A search field that filtered nothing would be
          // worse than none.
          _StatusFilter(cubit: cubit),
          Expanded(
            child: BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
              builder: (context, state) => PagedListView<PurchaseOrder>(
                state: state,
                emptyMessage: cubit.status == null
                    ? 'لم يُنشأ أمر شراء بعد'
                    : 'لا توجد أوامر في «${cubit.status!.label}»',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 96.h,
                itemBuilder: (context, order, index) => _OrderCard(
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

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.cubit});

  final PurchaseOrdersCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseOrdersCubit, PurchaseOrdersState>(
      builder: (context, _) => SizedBox(
        height: 52.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          children: [
            _Chip(
              label: 'الكل',
              isSelected: cubit.status == null,
              onTap: () => cubit.showStatus(null),
            ),
            for (final status in PurchaseOrderStatus.choices) ...[
              SizedBox(width: 8.w),
              _Chip(
                label: status.label,
                isSelected: cubit.status == status,
                onTap: () => cubit.showStatus(status),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap, super.key});

  final PurchaseOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.vendorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusPill(order: order),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(AppIcons.warehouse, size: 16.sp, color: scheme.onSurfaceVariant),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        order.warehouseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      // The order's own day, left to right like every other date in the app.
                      order.orderDate,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (order.items.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    '${order.items.length} بند'
                    '${order.hasReceipts ? ' · وصل بعضها' : ''}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.order});

  final PurchaseOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // Three families, not four: what is open, what is done, what was called off. A colour per
    // status is not a legend anybody learns.
    final (background, foreground) = switch (order.status) {
      PurchaseOrderStatus.completed => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      PurchaseOrderStatus.cancelled => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        // The server's own word for *this* order, so a status added later still reads right.
        order.statusLabel,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
