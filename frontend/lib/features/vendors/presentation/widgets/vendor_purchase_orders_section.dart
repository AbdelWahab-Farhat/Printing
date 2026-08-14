import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/counted_entry_row.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_orders_filter.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_purchase_order_counts_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إدارة أوامر الشراء» — four ways into one supplier's purchase orders.
///
/// **The only way to a supplier's orders that does not go through reading names off a list.**
/// The purchase-orders tab filters by status and by nothing else on screen; answering «أين
/// طلبيتنا من هذا المورد؟» meant scrolling it and reading the vendor line on every card.
///
/// Each row builds its own [PurchaseOrdersFilter] and hands it up. The statuses come from
/// [PurchaseOrderStatus.inProgress], `.fulfilled` and `.cancellations` — the same groups the
/// numbers beside them were added up from — so a row cannot open something that disagrees with
/// its own count. See VENDOR-PURCHASE-ORDERS-SECTION.md.
class VendorPurchaseOrdersSection extends StatelessWidget {
  const VendorPurchaseOrdersSection({
    required this.vendorId,
    required this.vendorName,
    required this.state,
    required this.onOpen,
    super.key,
  });

  final int vendorId;

  /// Travels into the title of the screen each row opens: that screen is handed an id, not a
  /// supplier, so this is its only way to say whose orders it is showing.
  final String vendorName;

  /// The four numbers, or the reason there are none. **Never blocks a tap.**
  final VendorPurchaseOrderCountsState state;

  final ValueChanged<PurchaseOrdersFilter> onOpen;

  @override
  Widget build(BuildContext context) {
    final loaded = state is VendorPurchaseOrderCountsLoaded
        ? state as VendorPurchaseOrderCountsLoaded
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إدارة أوامر الشراء',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        CountedEntryRow(
          icon: AppIcons.purchaseOrders,
          tone: CountedEntryTone.primary,
          title: 'كل أوامر الشراء',
          subtitle: 'عرض جميع الأوامر',
          count: loaded?.total,
          // No statuses at all: «كل» means every one of them, the written-off included. A total
          // that quietly dropped the cancellations would disagree with the number above it.
          onTap: () => onOpen(
            PurchaseOrdersFilter(
              title: 'كل أوامر الشراء · $vendorName',
              vendorId: vendorId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CountedEntryRow(
          icon: AppIcons.ordersInProgress,
          tone: CountedEntryTone.tertiary,
          title: 'أوامر الشراء الجارية',
          subtitle: 'ما لم يصل بعد',
          count: loaded?.inProgress,
          onTap: () => onOpen(
            PurchaseOrdersFilter(
              title: 'الجارية · $vendorName',
              statuses: PurchaseOrderStatus.inProgress
                  .map((status) => status.wire)
                  .toList(growable: false),
              vendorId: vendorId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CountedEntryRow(
          icon: AppIcons.ordersReceived,
          tone: CountedEntryTone.secondary,
          title: 'أوامر الشراء المكتملة',
          subtitle: 'وصلت بالكامل',
          count: loaded?.fulfilled,
          onTap: () => onOpen(
            PurchaseOrdersFilter(
              title: 'المكتملة · $vendorName',
              statuses: PurchaseOrderStatus.fulfilled
                  .map((status) => status.wire)
                  .toList(growable: false),
              vendorId: vendorId,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        CountedEntryRow(
          icon: AppIcons.ordersCancelled,
          tone: CountedEntryTone.muted,
          title: 'أوامر الشراء الملغاة',
          subtitle: 'ما كُفَّ عنه',
          count: loaded?.cancelled,
          onTap: () => onOpen(
            PurchaseOrdersFilter(
              title: 'الملغاة · $vendorName',
              statuses: PurchaseOrderStatus.cancellations
                  .map((status) => status.wire)
                  .toList(growable: false),
              vendorId: vendorId,
            ),
          ),
        ),
      ],
    );
  }
}
