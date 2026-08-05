import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';

/// One shelf: a size, how much of it is here, and whether that is too little.
///
/// **The quantity is the loudest thing on the row**, because it is the only question this
/// screen is opened to answer. `is_low_stock` comes from the server — a threshold nobody set
/// means no alert, which is not the same as a threshold of zero — and turns the number, not the
/// whole row, so a low shelf reads as *low* rather than as broken.
class StockRow extends StatelessWidget {
  const StockRow({required this.stock, this.onTap, super.key});

  final WarehouseStock stock;

  /// Opens the alert-level sheet. Null for somebody who may only read.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(14.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stock.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        if (stock.isLowStock) ...[
                          Icon(AppIcons.error, size: 13.sp, color: scheme.error),
                          SizedBox(width: 4.w),
                        ],
                        Text(
                          switch (stock.thresholdLabel) {
                            final level? => 'حد التنبيه $level',
                            // Said, not left blank: a shelf with no alert will never ask to be
                            // refilled, and that is a decision somebody can take here.
                            _ => 'بلا حد تنبيه',
                          },
                          style: context.textTheme.labelSmall?.copyWith(
                            color: stock.isLowStock ? scheme.error : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                stock.quantityLabel,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: stock.isLowStock ? scheme.error : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
