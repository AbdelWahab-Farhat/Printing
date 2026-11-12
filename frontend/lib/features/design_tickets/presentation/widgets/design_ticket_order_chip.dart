import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تصميم طلبية #1234» — a design ticket opened from an order and linked to it
/// (PRINT-COLORS.md §10). The kind is read off the ticket having an order, so there is no column
/// behind it. Drawn on the ticket list, the ticket and the form.
class DesignTicketOrderChip extends StatelessWidget {
  const DesignTicketOrderChip({required this.orderCode, this.onTap, super.key});

  final String orderCode;

  /// Opens the order, where the reader may.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.orders, size: 14.r, color: scheme.onSecondaryContainer),
          SizedBox(width: 4.w),
          Text(
            'تصميم طلبية #$orderCode',
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return onTap == null
        ? chip
        : InkWell(borderRadius: BorderRadius.circular(20.r), onTap: onTap, child: chip);
  }
}
