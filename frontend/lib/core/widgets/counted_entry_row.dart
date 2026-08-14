import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A way into a list, with how many things are in it.
///
/// The row «الطلبات الجارية · ٥ ›» — an icon tile, a label, what it opens, and a number. Written
/// once because two screens ask the same question of two different records: a customer's orders
/// and a supplier's purchase orders. Two copies of this row would drift the first time one of
/// them was adjusted, and the drift would be invisible — both screens would still look right,
/// side by side on nobody's phone.
///
/// See CUSTOMER-ORDERS-SECTION.md and VENDOR-PURCHASE-ORDERS-SECTION.md.
class CountedEntryRow extends StatelessWidget {
  const CountedEntryRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final CountedEntryTone tone;
  final String title;
  final String subtitle;

  /// Null while the counts are in flight or after they failed. **The row still opens.** Reaching
  /// the records must not depend on having counted them first, and «٠» in the place of a number
  /// nobody managed to read is the one thing here that would be a lie.
  final int? count;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    final (background, foreground) = switch (tone) {
      CountedEntryTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      CountedEntryTone.tertiary => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      CountedEntryTone.secondary => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      CountedEntryTone.muted => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 22.sp, color: foreground),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Absent rather than a placeholder while the number is unknown: a dash or a
              // spinner in a numeral's slot is read as a value.
              if (count case final total?) ...[
                SizedBox(width: 8.w),
                Text(
                  total.grouped,
                  // Digits read left-to-right even inside this RTL row.
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone == CountedEntryTone.muted
                        ? scheme.onSurfaceVariant
                        : scheme.primary,
                  ),
                ),
              ],
              SizedBox(width: 4.w),
              Icon(AppIcons.forward, size: 20.sp, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Which of the scheme's container pairs the icon tile is drawn from.
///
/// Families rather than tints of one, so the rows are told apart by shape *and* colour at a
/// glance — and drawn from the scheme rather than from constants, so both themes get them right
/// without this file knowing which one it is in.
enum CountedEntryTone {
  primary,
  tertiary,
  secondary,

  /// For a row about what was called off. Deliberately **not** the error colour: a cancellation
  /// is a decision somebody made, not a fault the screen is reporting, and red here would put an
  /// alarm under a number that is often perfectly healthy.
  muted,
}
