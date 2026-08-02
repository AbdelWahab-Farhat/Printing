import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order.dart';

/// The artwork conversation, version by version.
///
/// Newest first — the version under discussion is the one staff need, and it is the one the
/// server puts first.
///
/// A rejected version keeps the sentence it was turned down for. That is the reason versions are
/// rows in the first place: «لم يعجبه التصميم» is only useful if it says what about it.
class OrderDesignsSection extends StatelessWidget {
  const OrderDesignsSection({required this.designs, super.key});

  final List<OrderDesign> designs;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        for (final design in designs)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: design.isApproved ? scheme.tertiary : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'نسخة ${design.version}',
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      design.statusLabel,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: design.isApproved
                            ? scheme.tertiary
                            : design.isRejected
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (design.rejectionReason case final reason?) ...[
                  SizedBox(height: 6.h),
                  Text(
                    reason,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (design.notes case final notes?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    notes,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
