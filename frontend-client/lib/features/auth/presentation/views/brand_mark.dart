import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شعار «FlyerX» مكتوباً، أعلى الترويسة الكحلية في شاشتي الدخول وإنشاء الحساب.
///
/// **خطٌّ لا صورة، عن قصد.** `assets/images/logo.png` أيقونة التطبيق — حرف X وحده على كحلي —
/// والتصميم يكتب الاسم كاملاً بخطّ التطبيق: «Flyer» بلون العنوان فوق الترويسة، و«X» ببرتقالي
/// العلامة كما في الشعار المطبوع. والاسم لاتينيّ في تطبيقٍ من اليمين، فاتجاهه مثبّت.
///
/// يقف عند حافة القراءة كالعنوان تحته، لا في الوسط — كما رسمه التصميم.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Flyer', style: TextStyle(color: scheme.onHeader)),
          TextSpan(text: 'X', style: TextStyle(color: scheme.primary)),
        ],
      ),
      style: context.textTheme.displaySmall?.copyWith(
        fontSize: 38.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      textDirection: TextDirection.ltr,
    );
  }
}
