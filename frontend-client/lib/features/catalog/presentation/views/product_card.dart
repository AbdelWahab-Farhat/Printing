import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// بطاقة منتجٍ واحد: صورته، واسمه، ومدى مقاساته، وأدنى سعرٍ له. تستعملها شبكة «المنتجات» وصفّ
/// «منتجاتنا» على الرئيسية.
///
/// **بطاقةٌ واحدة للمكانين**، لأن منتجاً يبدو على الرئيسية غيره في الكتالوج يُقرأ منتجين. تملأ
/// البطاقة ما تُعطاه: الشبكة تقرّر مقاسها بخاناتها، والرئيسية بعرضٍ وارتفاعٍ ثابتين.
///
/// تُفتح بـ`push`: المنتج مكانٌ يُذهب إليه ويُرجع منه، فوق الشريط السفلي.
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final image = product.primaryImageUrl;
    final from = product.lowestUnitPrice;

    // **`shape` وحده، لا `shape` و`borderRadius` معاً.** Material يرفض الاثنين، و`shape` هو الذي
    // يحمل شعرة الحدّ التي يرسمها التصميم أيضاً.
    return Material(
      color: scheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.product(product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductThumbnail(image: image),
                  // «٤ مقاسات» فوق الصورة، حيث لا تكلّف البطاقة سطراً.
                  if (product.variantCount > 1)
                    PositionedDirectional(
                      top: 8.h,
                      start: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        child: Text(
                          '${product.variantCount} مقاسات',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // **مدى المقاسات حين يكون للمنتج مدى.** «٢٥×٣٥ … ٤٥×٦٠ سم» يجيب عن السؤال
                  // الذي تتركه شبكة الصور مفتوحاً، ولا يكلّف طلباً: المقاسات في جواب القائمة أصلاً.
                  if (product.sizeRange case final range?) ...[
                    SizedBox(height: 2.h),
                    Text(
                      range.bidiSafe,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  // **«اطلب عرض سعر» جوابٌ مقرَّر**، لا استنتاجٌ من قائمة شرائح فارغة: الخادم
                  // يرسل `has_listed_prices`، وأوضاع التسعير خلفها لا يتعلّمها هذا التطبيق.
                  Text(
                    product.hasListedPrices && from != null
                        ? 'من ${from.asMoney} د.ل'
                        : 'اطلب عرض سعر',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
