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
  const SummaryTiles({
    required this.summary,
    this.onAllOrders,
    this.onCustomers,
    this.onDay,
    this.onMonth,
    super.key,
  });

  final HomeSummary summary;

  /// What each number opens. Null leaves that one inert — a tile with nowhere honest to go is
  /// better flat than tappable.
  final VoidCallback? onAllOrders;
  final VoidCallback? onCustomers;
  final VoidCallback? onDay;
  final VoidCallback? onMonth;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile(
        label: 'الطلبات الكلية',
        value: summary.totalOrders,
        icon: AppIcons.orders,
        onTap: onAllOrders,
      ),
      _Tile(
        label: 'عدد العملاء',
        value: summary.customersCount,
        icon: AppIcons.customers,
        onTap: onCustomers,
      ),
      // A day or a month with nothing in it opens a screen that says so, which is a tap that
      // teaches the reader nothing they cannot already see.
      _Tile(
        label: 'الطلبات اليومية',
        value: summary.dailyOrders,
        icon: AppIcons.today,
        onTap: summary.dailyOrders == 0 ? null : onDay,
      ),
      _Tile(
        label: 'الطلبات الشهرية',
        value: summary.monthlyOrders,
        icon: AppIcons.month,
        onTap: summary.monthlyOrders == 0 ? null : onMonth,
      ),
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
  const _Tile({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);

    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
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

    if (onTap == null) return tile;

    // Over the tile rather than under it, for the reason the status cards give: the tile paints
    // its own surface, and a Material beneath would draw a second one behind it.
    return Stack(
      children: [
        tile,
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(borderRadius: radius, onTap: onTap),
          ),
        ),
      ],
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
