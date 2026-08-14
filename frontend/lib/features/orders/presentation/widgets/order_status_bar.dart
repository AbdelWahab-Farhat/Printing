import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Where the order is — the answer the detail screen is opened for, given the width to say it.
///
/// The same colour and the same glyph the rest of the app uses for that status, taken from
/// [OrderStatusChip]'s own legend rather than a second one written here: one status, one look,
/// wherever it is drawn.
///
/// **The words are still the server's.** `status_label` arrives with the order and is rendered
/// as-is, so a status this build has never heard of reads correctly in a neutral colour instead
/// of leaving a hole — see [OrderStatus.unknown].
class OrderStatusBar extends StatelessWidget {
  const OrderStatusBar({required this.status, required this.label, super.key});

  final OrderStatus status;

  /// The server's Arabic — rendered as-is.
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = OrderStatusChip.toneColour(context.colorScheme, status.tone);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(OrderStatusChip.iconFor(status), size: 24.sp, color: foreground),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
