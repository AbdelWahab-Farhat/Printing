import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// التصميم نفسه لا رمزٌ عنه: الصورة حين تكون صورة، وأيقونة الملف حين يكون PDF.
///
/// **يملأ ما يُعطى من مساحة** — بطاقة المكتبة تعطيه نصفها، وصفّ منتقي التصاميم مربّعاً صغيراً — فالمقاس
/// على من يضعه، والأيقونة تُعطى حجمها معه.
///
/// عامٌّ لأن التصميم يُرى في غير «تصاميمي»: نسختان من شعارٍ واحد «الشعار الأزرق» و«الشعار الأزرق —
/// نسخة معدّلة»، ولا يُفرَّق بينهما بالاسم وحده حين تُختاران لطلبية.
class DesignThumbnail extends StatelessWidget {
  const DesignThumbnail({required this.design, this.glyphSize = 30, super.key});

  final CustomerDesign design;

  /// حجم أيقونة الملف حين لا صورة تُرسم.
  final double glyphSize;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = design.fileUrl;

    final placeholder = Center(
      child: Icon(
        design.kind.isImage ? AppIcons.photos : AppIcons.pdf,
        size: glyphSize.sp,
        color: scheme.onSurfaceVariant,
      ),
    );

    // ملف PDF لا مصغّرةَ له تُرسم، ورابط الصورة **موقَّعٌ ومنتهي الصلاحية** — يُصكّ مع كل طلب،
    // فلا يُخزَّن بين الجلسات عمداً.
    if (!design.kind.isImage || url == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => const SizedBox.shrink(),
      errorWidget: (context, _, _) => placeholder,
    );
  }
}
