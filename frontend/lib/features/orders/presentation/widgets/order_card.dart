import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/presentation/widgets/order_status_chip.dart';

/// One order in the list.
///
/// Four facts, chosen because they are the four a person scanning a work queue asks for: which
/// order, where it is, whose it is and what it is worth. Everything else — the lines, the
/// artwork, the timeline — is a tap away, and putting any of it here would make the card a
/// paragraph to read instead of a row to scan.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    // Plain digits, said as-is on the phone.
                    '#${order.code}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  OrderStatusChip(
                    status: order.status,
                    label: order.statusLabel,
                    compact: true,
                  ),
                  const Spacer(),
                  Text(
                    // Money as the server sent it — never re-formatted through a double.
                    order.grandTotal,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _Line(
                icon: AppIcons.person,
                text: order.customer?.name ?? 'عميل #${order.customerId}',
              ),
              SizedBox(height: 6.h),
              _Line(
                // A pin for a delivery, a shopfront for a collection: the difference decides
                // whether anybody has to drive anywhere, so it is worth a glyph of its own.
                icon: order.isOfficePickup ? AppIcons.warehouse : AppIcons.mapPin,
                text: order.isOfficePickup ? order.cityName : order.destination,
              ),
              if (order.itemsCount != null) ...[
                SizedBox(height: 6.h),
                _Line(
                  icon: AppIcons.products,
                  text: '${order.itemsCount} من المنتجات',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
