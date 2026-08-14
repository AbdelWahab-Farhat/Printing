import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One purchase order, as a row in a list.
///
/// Lifted out of the purchase-orders tab when a second screen needed it: a supplier's own screen
/// opens the same orders through a filter, and two cards drawing the same record differently is
/// the kind of difference nobody sees until they are side by side.
class PurchaseOrderCard extends StatelessWidget {
  const PurchaseOrderCard({
    required this.order,
    required this.onTap,
    super.key,
  });

  final PurchaseOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **No outer margin of its own.** `PagedListView` already insets the list by 16.w and puts
    // 12.h between rows; a card that padded itself as well sat at 32.w on a screen where every
    // other list sits at 16.w — visibly narrower, beside pages it is meant to match.
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
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
                  Icon(
                    AppIcons.warehouse,
                    size: 16.sp,
                    color: scheme.onSurfaceVariant,
                  ),
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
      PurchaseOrderStatus.completed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PurchaseOrderStatus.cancelled => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
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
