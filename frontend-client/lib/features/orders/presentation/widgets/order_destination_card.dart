import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إلى أين تذهب الطلبية: المدينة والمنطقة، ومن يستلمها ورقمه، وطريقة التسليم في شارة.
///
/// **لقطة الطلبية لا بحثٌ حيّ** — منطقةٌ غُيّر اسمها لا تعيد كتابة وجهة طلبيةٍ قديمة.
class OrderDestinationCard extends StatelessWidget {
  const OrderDestinationCard({required this.order, super.key});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final where = [?order.cityName, ?order.regionName, ?order.addressDetails].join(' — ');
    final quiet = context.textTheme.bodyMedium?.copyWith(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    );

    return AppCard.raised(
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(AppIcons.mapPin, size: 22.sp, color: scheme.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // طلبيةٌ بلا مدينة — استلامٌ من المكتب — تُسمّى بطريقة تسليمها.
                  where.isEmpty ? (order.fulfilmentTypeLabel ?? '—') : where,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                // **الاسم فارغٌ لطلبية العميل نفسه**، فلا يُكتب اسمه له.
                if (order.recipientName case final name?) Text(name, style: quiet),
                if (order.recipientPhone case final phone?)
                  // رقمٌ ليبي يُقرأ من اليسار حتى في سطرٍ من اليمين.
                  Text(phone, textDirection: TextDirection.ltr, style: quiet),
              ],
            ),
          ),
          if (order.fulfilmentTypeLabel case final label? when where.isNotEmpty) ...[
            SizedBox(width: 8.w),
            Container(
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
