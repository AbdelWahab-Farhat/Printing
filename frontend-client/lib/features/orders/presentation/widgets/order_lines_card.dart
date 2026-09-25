import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بنود الطلبية المفتوحة، بنداً في صف تفصلها شعرة.
class OrderLinesCard extends StatelessWidget {
  const OrderLinesCard({required this.lines, super.key});

  final List<OrderLine> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.raised(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: Column(
        children: [
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) Divider(height: 1, thickness: 1, color: scheme.surfaceContainerHigh),
            _LineRow(line: line),
          ],
        ],
      ),
    );
  }
}

/// بندٌ واحد: صورة منتجه، واسمه، ومقاسه وكميته بوحدتها — ومجموعه وسعر الواحد منه في آخر السطر.
///
/// **كان «1.72 × 100 د.ل» يُقرأ مئة دينار**: العملة لصقت بالكمية، والكمية بلا وحدة. الآن
/// «100 قطعة» تحت الاسم، و«1.72 للقطعة» تحت المجموع — كلٌّ في مكانٍ لا يُخلط فيه بالآخر.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = line.pricingUnitLabel;
    final quiet = context.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5.sp,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: scheme.surfaceContainerHigh),
            ),
            child: ProductThumbnail(image: line.productImageUrl),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    if (line.variantLabel case final size?) ...[
                      _SizeChip(size),
                      SizedBox(width: 8.w),
                    ],
                    Flexible(
                      child: Text(
                        unit == null
                            ? line.quantity.asQuantity
                            : '${line.quantity.asQuantity} $unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: quiet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (line.lineTotal case final total?)
                Text.rich(
                  TextSpan(
                    text: total.asMoney,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: ' د.ل',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // **البند باقٍ وإن لم يُسعَّر**: طلبه العميل ومن حقه أن يراه، والسعر يقال إنه آتٍ.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 110.w),
                  child: Text(
                    awaitingQuoteLabel,
                    textAlign: TextAlign.end,
                    style: quiet?.copyWith(fontSize: 12.5.sp),
                  ),
                ),
              if (line.unitPrice case final price?) ...[
                SizedBox(height: 3.h),
                Text(
                  unit == null ? price.asMoney : '${price.asMoney} لل$unit',
                  style: quiet?.copyWith(fontSize: 12.5.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// المقاس في شارةٍ صغيرة، من اليسار كما يُكتب على الكيس: «25*35» لا «35*25».
class _SizeChip extends StatelessWidget {
  const _SizeChip(this.size);

  final String size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: scheme.surfaceContainerHigh),
      ),
      child: Text(
        size,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        style: context.textTheme.labelMedium?.copyWith(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
