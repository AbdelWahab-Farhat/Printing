import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/warehouses/models/warehouse.dart';

/// One place stock sits: what it is called, what kind it is, and how much of the catalogue is
/// on its shelves.
///
/// The count is «٤٢ صنفاً», not a number of pieces — a warehouse holding six sizes of one bag
/// is a small warehouse however many thousands of bags that is. It is also what decides whether
/// deleting will be refused, so the row shows it rather than leaving that to a 422.
class WarehouseCard extends StatelessWidget {
  const WarehouseCard({required this.warehouse, this.onTap, super.key});

  final Warehouse warehouse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                height: 38.w,
                width: 38.w,
                decoration: BoxDecoration(
                  // The main warehouse is where stock arrives, and it is the one a storekeeper
                  // looks for first — the only row with the accent tint.
                  color: warehouse.type == WarehouseType.main
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  AppIcons.warehouse,
                  size: 20.sp,
                  color: warehouse.type == WarehouseType.main
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      warehouse.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      // The server's own Arabic for the kind, and the place if somebody wrote
                      // one — «مخزن التشغيل · ورشة الظهرة».
                      [warehouse.typeLabel, ?warehouse.location].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (warehouse.stocksCount case final count?) ...[
                SizedBox(width: 8.w),
                Text(
                  count == 0 ? 'فارغ' : '$count صنفاً',
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: count == 0 ? scheme.onSurfaceVariant : scheme.primary,
                  ),
                ),
              ],
              Icon(AppIcons.forward, size: 18.sp, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
