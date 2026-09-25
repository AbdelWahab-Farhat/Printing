import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// هيئة الحقل المشتركة بين `AppTextField` و`AppDropdown`: الصندوق، وألوان حالاته، ونصّه.
///
/// **مكتوبةٌ هنا مرةً واحدة لأن الحقلين يجلسان في النموذج نفسه.** كان كلٌّ منهما يكتب
/// `InputDecoration` كاملاً بنفسه، والتعليق في كليهما يَعِد بأنهما متطابقان — وعدٌ لا يحرسه شيء،
/// وفرقُ نصف نقطةٍ في نصف القطر أو درجةٍ في لون الحدّ يُقرأ نموذجين.
///
/// **الهيئة من تصميم شاشة الدخول («حقول معنونة»):** صندوقٌ بلون الحاوية الهادئ وحدٍّ رفيع،
/// يصير أبيض بحدٍّ بلون العلامة ما دام المؤشر فيه. والعنوان خارجه، فوقه — انظر [LabelledField].
abstract final class FieldFrame {
  /// نصف قطر الصندوق: ١٤ نقطة في التصميم المرسوم على عرض ٣٩٠.
  static double get radius => 15.r;

  /// لون الأيقونة والحدّ معاً في الحالات الثلاث — ساكن، مُركَّز، خطأ — فلا يختلفان أبداً.
  static Color accent(
    ColorScheme scheme, {
    required bool isEnabled,
    required bool isFocused,
    required bool hasError,
  }) {
    if (!isEnabled) return scheme.onSurfaceVariant.withValues(alpha: 0.45);
    if (hasError) return scheme.error;
    if (isFocused) return scheme.primary;

    return scheme.onSurfaceVariant.withValues(alpha: 0.7);
  }

  /// ما يُكتب في الحقل، بحجم التصميم.
  static TextStyle? textStyle(BuildContext context, {bool isEnabled = true}) {
    final scheme = context.colorScheme;

    return context.textTheme.bodyLarge?.copyWith(
      fontSize: 17.5.sp,
      color: isEnabled ? scheme.onSurface : scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
  }

  /// الصندوق نفسه. [prefix] و[suffix] يُبنيان عند المستدعي لأن كلاً منهما يعرف أيقونته.
  static InputDecoration decoration(
    BuildContext context, {
    required bool isEnabled,
    required bool isFocused,
    String? hint,
    TextDirection? hintDirection,
    String? helperText,
    String? errorText,
    Widget? prefix,
    Widget? suffix,
  }) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final corners = BorderRadius.circular(radius);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: corners,
      borderSide: BorderSide(color: color, width: width),
    );

    // خانةٌ ثابتة على الجانبين، فيبدأ النص من الموضع نفسه في كل حقل، حمل أيقونةً أم لم يحمل.
    final slot = BoxConstraints(minWidth: 52.w, minHeight: 48.w);

    return InputDecoration(
      hintText: hint,
      // المثال المكتوب في الحقل عيّنةٌ مما يُكتب فيه، والعيّنة اللاتينية تُقرأ من اليسار حتى هنا.
      hintTextDirection: hintDirection,
      helperText: helperText,
      errorText: errorText,
      // العدّاد تحت حقلٍ يحدّه المنسّق أصلاً ضجيج.
      counterText: '',
      filled: true,
      fillColor: !isEnabled
          ? scheme.surfaceContainerHigh.withValues(alpha: 0.4)
          : isFocused
          ? scheme.surfaceContainerLowest
          : scheme.surfaceContainer,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
      hintStyle: textStyle(context)?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontWeight: FontWeight.w400,
      ),
      helperStyle: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.4),
      errorMaxLines: 2,
      prefixIcon: prefix,
      prefixIconConstraints: slot,
      suffixIcon: suffix,
      suffixIconConstraints: slot,
      border: border(scheme.outlineVariant, 1),
      enabledBorder: border(scheme.outlineVariant, 1),
      focusedBorder: border(scheme.primary, 1.5),
      errorBorder: border(scheme.error, 1),
      focusedErrorBorder: border(scheme.error, 1.5),
      disabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5), 1),
    );
  }
}

/// العنوان فوق الحقل، ومعه — إن وُجد — إجراءٌ صغير في طرف السطر الآخر.
///
/// **خارج الصندوق لا عائماً على حدّه.** العنوان العائم يختفي في الحدّ ما دام الحقل فارغاً ويصغر
/// حين يُكتب فيه؛ هذا ثابتٌ بحجمٍ واحد، فيُقرأ النموذج من أوله إلى آخره قبل أن يُلمس.
///
/// [action] يرث حجم العنوان — «نسيتها؟» بجانب «كلمة المرور» بالحجم نفسه — ويقف على خطّ
/// أساسه، لا على وسطه، فتستقرّ الكلمتان على سطرٍ واحد وإن اختلف وزناهما.
class LabelledField extends StatelessWidget {
  const LabelledField({
    super.key,
    required this.label,
    required this.field,
    this.action,
  });

  /// بلا عنوان يُرسم [field] وحده، ولا يُضاف فوقه شيء.
  final String? label;
  final Widget field;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) return field;

    final style = context.textTheme.titleSmall?.copyWith(
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
      color: context.colorScheme.onSurface,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DefaultTextStyle.merge(
          style: style,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(label)),
              ?action,
            ],
          ),
        ),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}
