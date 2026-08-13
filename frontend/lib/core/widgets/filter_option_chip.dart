import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';

/// One option on a filter sheet: a word, optionally how many rows stand behind it, and whether
/// it is picked.
///
/// **One widget for every axis, and [isTicked] is the difference.** Some options replace the one
/// before them — a status, a sort — and some add to the set — a payment state. With the sections
/// laid out identically, the leading glyph is what says which: a box is the shape that means
/// «هذه تُجمع», a dot doubles as the list's own colour legend, and nothing at all is for an
/// option that is neither.
///
/// **The box is drawn empty rather than left out, and that is not decoration.** Material's own
/// filter chip slides its tick in on selection, which widens the chip — and in a `Wrap` a chip
/// that widens pushes its neighbours onto the next line. Ticking «مدفوعة بالكامل» moved «غير
/// مدفوعة» out from under the thumb that was about to tap it. Holding the width in both states
/// costs a line and buys a row that never moves while it is being used.
///
/// [count] is optional because not every filter has a number to put beside it: the orders sheet
/// knows how many orders stand in each status, and no equivalent is worth a request for «بدون
/// طلبات». Where there is one, zero is shown and muted rather than hidden — the reason a chip
/// reading zero is on a sheet at all is to be asked about, and the reason it is dimmed is that
/// it is usually not the one being looked for.
///
/// Colours come from the scheme, never from a design's hex values — the theme is generated and
/// gets replaced wholesale, and a literal here would survive that and quietly stop matching
/// everything around it.
class FilterOptionChip extends StatelessWidget {
  const FilterOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
    this.dot,
    this.isTicked = false,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// How many rows this option would leave on screen. Omitted where there is no such number.
  final int? count;

  /// The option's own colour, drawn as a dot ahead of the word — a status's, so the sheet and
  /// the list agree without the reader learning two legends.
  final Color? dot;

  /// Whether picking this one adds to a set rather than replacing a choice.
  final bool isTicked;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final foreground = isSelected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: isSelected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(999.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: isSelected ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTicked) ...[
                Icon(
                  isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 16.sp,
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
                SizedBox(width: 6.w),
              ] else if (dot != null) ...[
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                SizedBox(width: 7.w),
              ],
              Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              if (count case final count?) ...[
                SizedBox(width: 7.w),
                Text(
                  count.grouped,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground.withValues(alpha: count == 0 ? 0.4 : 0.72),
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

/// The caption above one axis of a filter sheet — «حالة الطلبية», «الترتيب».
class FilterSectionTitle extends StatelessWidget {
  const FilterSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
