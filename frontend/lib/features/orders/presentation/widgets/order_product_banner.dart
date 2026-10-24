import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رأس بنود المنتج الواحد: ما يُطبع كبيراً، واسم المنتج وكم قطعةً منه على شريطٍ مضبَّب فوقه.
///
/// **لمن يقف عند المطبعة.** كانت الصورة مربّعاً بحجم إصبع في كل بند، والاسم يتكرّر على كل
/// مقاس. الآن التصميم يأخذ عرض البطاقة، ويُفتح على الشاشة كلّها بلمسة، والاسم والعدد مرةً واحدة
/// فوقه — والمقاسات تحته سطراً سطراً.
///
/// **الاسم كاملاً، يلتفّ ولا يُقصّ.** «أكياس يد خارجية - مطبوعه» بجانب العدد لا يسعها سطرٌ على
/// هاتفٍ صغير، ونصف اسمٍ بثلاث نقاط هو ما لا يُطبع عليه.
///
/// **الشريط داكنٌ في الوضعين**، لأنه فوق صورةٍ لا يُعرف لونها: نصٌّ أبيض على ضبابٍ داكن يُقرأ
/// فوق كيسٍ أسود وفوق كيسٍ أبيض.
///
/// **بلا صورةٍ لا مربّعَ رمادياً فارغاً**: الشريط وحده على لون اللوحة، يسمّي المنتج ويعدّ قطعه.
class OrderProductBanner extends StatelessWidget {
  const OrderProductBanner({
    required this.name,
    this.code,
    this.count,
    this.imageUrl,
    this.onOpenImage,
    super.key,
  });

  /// ليصل الاختبار إلى زرّ التكبير لا إلى أيقونةٍ قد تُستبدل.
  static const Key enlargeKey = Key('order-product-banner-enlarge');

  /// الاسم كما حُفظ يوم أُخذت الطلبية، لا كما هو في الكتالوج اليوم.
  final String name;

  /// «P2» — ما يقوله زميلٌ لزميل، فيسبق الاسم بلون المنتجات.
  final String? code;

  /// «450 قطعة»، أو null حين لا يُجمع — انظر `OrderProductGroup.count`.
  final String? count;

  /// التصميم، أو صورة المنتج حين لا تصميم، أو null.
  final String? imageUrl;

  final VoidCallback? onOpenImage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = imageUrl;

    if (url == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: _Label(
          code: code,
          name: name,
          count: count,
          textColor: scheme.onSurface,
          codeColor: scheme.primary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => ColoredBox(color: scheme.surfaceContainerHigh),
              errorWidget: (context, url, error) => ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Center(child: Icon(AppIcons.error, color: scheme.onSurfaceVariant)),
              ),
            ),
            // الصورة كلّها بابٌ إلى العارض، والزرّ في الزاوية يقول ذلك لمن لا يعرفه.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onOpenImage),
              ),
            ),
            PositionedDirectional(
              top: 8.h,
              end: 8.w,
              child: IconButton(
                key: enlargeKey,
                tooltip: 'تكبير الصورة',
                onPressed: onOpenImage,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(AppIcons.enlarge, size: 18.sp),
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  // ضبابٌ خفيف: يكفي ليُقرأ النص، ويُبقي ما تحته معروفاً.
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                      child: _Label(
                        code: code,
                        name: name,
                        count: count,
                        textColor: Colors.white,
                        codeColor: scheme.primaryFixed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الرمز والاسم في بداية السطر، والعدد في نهايته.
class _Label extends StatelessWidget {
  const _Label({
    required this.code,
    required this.name,
    required this.count,
    required this.textColor,
    required this.codeColor,
  });

  final String? code;
  final String name;
  final String? count;
  final Color textColor;
  final Color codeColor;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.titleMedium?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w700,
    );

    return Row(
      children: [
        Expanded(
          // نصٌّ واحد لا اثنان: الاسم الطويل يلتفّ تحت الرمز كما تلتفّ الجملة، بدل عمودين.
          child: Text.rich(
            TextSpan(
              children: [
                if (code case final code?) ...[
                  TextSpan(
                    text: code,
                    style: TextStyle(color: codeColor, fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' '),
                ],
                TextSpan(text: name),
              ],
            ),
            style: style,
          ),
        ),
        if (count case final count?) ...[
          SizedBox(width: 12.w),
          // بلا `textDirection`: «450 قطعة» رقمٌ *و*كلمة، وقلبه يضع الوحدة في غير مكانها.
          Text(count, style: style?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ],
    );
  }
}
