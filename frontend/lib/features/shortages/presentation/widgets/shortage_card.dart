import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/widgets/shortage_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One shortage, as a row in a list.
///
/// **المتبقي beside المطلوب, never one of them alone.** «٣٠ كجم» says nothing about whether
/// anybody has been out and bought any of it, and the whole question this list is scanned for is
/// «كم ما زال ناقصاً؟». The remainder is the bigger of the two and carries the unit, because it
/// is the figure somebody acts on.
///
/// **And the source is named.** «يدوي» or the order's own code — §٨ of the brief asks for
/// «معرفة مصدر النقص», and the code is the whole of it: it is what somebody says on the telephone
/// when a customer asks why their order has not moved.
class ShortageCard extends StatelessWidget {
  const ShortageCard({required this.shortage, required this.onTap, super.key});

  final Shortage shortage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **No outer margin of its own** — `PagedListView` already insets the list and spaces the
    // rows; a card that padded itself as well would sit visibly narrower than every other list.
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
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shortage.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ShortageStatusPill(shortage: shortage),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // The figure the row is read for, in the unit it is counted in.
                  Text(
                    'المتبقي ${shortage.withUnit(shortage.remainingQuantity)}',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      // Calm once nothing is owed: a list where every completed row still shouts
                      // is a list nobody reads the live rows out of.
                      color: shortage.isOutstanding ? scheme.error : scheme.paid,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'من ${shortage.withUnit(shortage.requiredQuantity)}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    shortage.isFromOrder ? AppIcons.orders : AppIcons.edit,
                    size: 16.sp,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    // The order's code is the fact; «يدوي» is what is said when there is none.
                    switch (shortage.orderCode) {
                      final code? => 'طلبية #$code',
                      null => 'يدوي',
                    },
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  // **«غير مُسنَد» is written, not left blank.** It is a queue a supervisor works
                  // from, and an empty space says «somebody has this» to a reader scanning fast.
                  Icon(AppIcons.customers, size: 16.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      shortage.assignee?.name ?? 'غير مُسنَد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
