import 'dart:math' as math;

import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// السلة الفارغة: كيسٌ مفتوحٌ لا شيء فيه، وسطران يقولان ذلك، وزرٌّ إلى «المنتجات».
///
/// **بدل السطر الأحمر «لا توجد منتجات في هذه الطلبية.»** (طلب المستخدم، 2026-09-25). سلةٌ فارغة
/// حالةٌ عادية لا خطأ، فلا لونَ خطأٍ فيها، والكيس لأن الأكياس ما يبيعه هذا المتجر.
///
/// **تأخذ مساحة الخطوة كلّها** ولا تُوضع صفّاً في قائمة: تتوسّطها عمودياً، وتتمرّر على شاشةٍ قصيرة
/// بدل أن تفيض.
///
/// **الزرّ `go` لا `push`:** السلة تُفتح فوق الـ shell، ومن تركها ليتصفّح لا يعود إليها بزرّ
/// الرجوع — يعود إليها من شريط «المنتجات» حين يضع فيها شيئاً.
class EmptyBasket extends StatelessWidget {
  const EmptyBasket({super.key});

  /// الرسم، بألوانٍ بديلة يستبدلها [_ThemeColors].
  static const String illustration = 'assets/illustrations/empty_basket.svg';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final padding = EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? math.max(0, constraints.maxHeight - padding.vertical)
                : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                illustration,
                width: 190.w,
                height: 190.w,
                colorMapper: _ThemeColors.of(scheme),
                // زينةٌ لا معلومة: العنوان تحته يقول ما يقوله الرسم.
                excludeFromSemantics: true,
              ),
              SizedBox(height: 20.h),
              Text(
                'سلتك فارغة',
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8.h),
              Text(
                'اختر أكياسك من المنتجات، وستجدها هنا قبل أن ترسل الطلب.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 28.h),
              AppButton(
                label: 'تصفّح المنتجات',
                icon: AppIcons.products,
                onPressed: () => context.go(Routes.products),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ألوان الملف البديلة ← أدوار الثيم، فيتبع الرسمُ الوضعين الفاتح والداكن كما تتبعه الشاشة.
///
/// **ألوانٌ لا تُستعمل في رسمٍ حقيقي**، ليُعرف كلٌّ منها بعينه: الكيس `#FF0000` بلون العلامة،
/// وجانبه ومقبضاه `#990000` بطرفه الأعمق، وجوفه `#330000` أعمق منهما، والدائرة خلفه `#FF00FF`
/// والأرض تحته `#00FFFF` بلوني الحاويات، والنجوم `#0000FF`، ومربّع الطباعة `#FFFFFF`. وما سواها
/// يبقى كما هو.
///
/// **يُقارَن بقيمه** لأن `flutter_svg` يخزّن الرسم المقروء بمفتاحٍ فيه هذا الكائن: كائنٌ جديد
/// بالألوان نفسها يجد الرسم في الذاكرة، ووضعٌ آخر يقرأه من جديد.
@immutable
class _ThemeColors extends ColorMapper {
  const _ThemeColors({
    required this.bag,
    required this.side,
    required this.inside,
    required this.disc,
    required this.ground,
    required this.spark,
    required this.print,
  });

  factory _ThemeColors.of(ColorScheme scheme) => _ThemeColors(
    bag: scheme.primary,
    side: scheme.primaryDeep,
    // الجوف: الطرف الأعمق نحو الظلّ، ليُقرأ فتحةً لا غطاءً.
    inside: Color.lerp(scheme.primaryDeep, scheme.shadow, 0.4)!,
    disc: scheme.surfaceContainerHigh,
    ground: scheme.surfaceContainerHighest,
    spark: scheme.onSurfaceVariant,
    print: scheme.onPrimary,
  );

  final Color bag;
  final Color side;
  final Color inside;
  final Color disc;
  final Color ground;
  final Color spark;
  final Color print;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    return switch (color.toARGB32()) {
      0xFFFF0000 => bag,
      0xFF990000 => side,
      0xFF330000 => inside,
      0xFFFF00FF => disc,
      0xFF00FFFF => ground,
      0xFF0000FF => spark,
      0xFFFFFFFF => print,
      _ => color,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is _ThemeColors &&
      other.bag == bag &&
      other.side == side &&
      other.inside == inside &&
      other.disc == disc &&
      other.ground == ground &&
      other.spark == spark &&
      other.print == print;

  @override
  int get hashCode => Object.hash(bag, side, inside, disc, ground, spark, print);
}
