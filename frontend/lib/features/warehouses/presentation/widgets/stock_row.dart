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
///
/// **Tapping opens this shelf's own history**, which is the second question and the one the
/// balance cannot answer: 100 is a fact, «وصل 500 وخرج 400» is what a storekeeper does anything
/// with. The alert level moved to a button of its own — the row leads somewhere now, and one
/// tap cannot mean two things.
class StockRow extends StatelessWidget {
  const StockRow({
    required this.stock,
    this.onTap,
    this.onEditThreshold,
    super.key,
  });

  final WarehouseStock stock;

  /// Opens this shelf's own history — where the number came from, and who took the rest.
  final VoidCallback? onTap;

  /// Opens the alert-level sheet. Null for somebody who may only read, and then the button is
  /// absent rather than greyed: a control that only ever refuses is a control to leave out.
  final VoidCallback? onEditThreshold;

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
                    Row(
                      children: [
                        // The code leads, in the accent it wears on the catalogue card: «P7» is
                        // what a storekeeper is told on the phone and what they search for.
                        if (stock.variant?.productCode case final code?) ...[
                          Text(
                            code,
                            textDirection: TextDirection.ltr,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6.w),
                        ],
                        Flexible(
                          child: Text(
                            stock.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
              // The alert level gets its own button, because the row itself now leads somewhere:
              // one tap cannot both open a history and edit a number.
              if (onEditThreshold != null)
                IconButton(
                  tooltip: 'حد التنبيه',
                  onPressed: onEditThreshold,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(AppIcons.edit, size: 18.sp, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
