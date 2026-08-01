import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/appear.dart';
import 'package:printing/features/home/models/home_summary.dart';

/// The four numbers that describe the business at a glance.
///
/// Two by two rather than a row of four: at four across, the digits shrink to where 9651 and
/// 9,651 are the same smudge, and these numbers exist to be read from arm's length.
class SummaryTiles extends StatelessWidget {
  const SummaryTiles({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile(label: 'الطلبات الكلية', value: summary.totalOrders, icon: AppIcons.orders),
      _Tile(label: 'عدد العملاء', value: summary.customersCount, icon: AppIcons.customers),
      _Tile(label: 'الطلبات اليومية', value: summary.dailyOrders, icon: AppIcons.today),
      _Tile(label: 'الطلبات الشهرية', value: summary.monthlyOrders, icon: AppIcons.month),
    ];

    return GridView.count(
      // Inside a scrolling column: it lays out at its natural height and lets the page scroll.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.55,
      children: [
        for (final (index, tile) in tiles.indexed) Appear(index: index, child: tile),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: scheme.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Text(
            // Grouped: 9651 is read as a shape, 9,651 as a number.
            value.grouped,
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

extension GroupedDigits on int {
  /// `9651` → `9,651`. Written here rather than pulled from `intl`, which would arrive with a
  /// locale that renders these in Arabic-Indic digits — the shop reads Latin ones.
  String get grouped {
    final digits = abs().toString();
    final buffer = StringBuffer(isNegative ? '-' : '');

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}
