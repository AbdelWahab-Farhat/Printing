import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// كلمةٌ تُنقر بدل زرٍّ كامل: «إنشاء حساب جديد» تحت بطاقة الدخول، و«نسيتها؟» على سطر عنوان
/// كلمة المرور.
///
/// **ليست `AppButton` رابعاً.** الزرّ صندوقٌ بعرض الشاشة لإجراءٍ تقوم الشاشة لأجله؛ هذا طريقٌ
/// جانبيّ يُكتب داخل سطرٍ من الكلام، فيأخذ حجم الكلام الذي حوله ولونَ العلامة ووزناً أثقل منه.
/// وليس `TextButton` مباشرةً للسبب الذي من أجله وُجد `AppButton`: شاشتان تكتب كلٌّ منهما رابطها
/// بنفسها تنتهيان بحشوتين ولونين.
///
/// **الحجم من السياق:** [style] إن مُرِّر، وإلا نصّ الموضع الذي وُضع فيه — فيقف في سطرٍ بجانب
/// «ليس لديك حساب؟» بحجمها نفسه.
///
/// **الضغط لون لا حركة:** ظلٌّ خفيف خلف الكلمة ما دام الإصبع عليها، ولا موجة — فلا شيء يتحرك
/// لمن أوقف الحركة في إعدادات هاتفه.
class AppTextLink extends StatelessWidget {
  const AppTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
  });

  final String label;
  final VoidCallback onPressed;

  /// الحجم والخط. اللون والوزن يقرّرهما الرابط نفسه.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ink = context.colorScheme.primary;
    final base = style ?? DefaultTextStyle.of(context).style;

    return Semantics(
      link: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6.r),
        splashFactory: NoSplash.splashFactory,
        highlightColor: ink.withValues(alpha: 0.1),
        child: Text(
          label,
          style: base.copyWith(color: ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
