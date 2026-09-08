import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «هذه الطلبية مستعجلة» — سؤالٌ بجوابين، فمفتاحٌ لا شريحتان.
///
/// **واحدٌ لشاشتين.** يُسأل عند أخذ الطلبية وعند تعديلها، وهما نفس السؤال بنفس الكلمة ونفس
/// اللون؛ ونسختان منه تختلفان يوم يُعاد صوغ إحداهما.
///
/// **الصفّ كلّه يُضغط لا المفتاح وحده.** المفتاح على حافة الشاشة وحده هدفٌ صغير بجانب سطرٍ عريض
/// فارغ، و`SwitchListTile` تجعل الكلمة والمفتاح ضغطةً واحدة كما تفعل كل قائمة إعداداتٍ يعرفها
/// صاحب الهاتف.
///
/// **ولا سطر شرحٍ تحته.** العنوان يقول ما يفعله، والخادم هو من يقول متى يُرفض.
///
/// وملفوفٌ بـ`Material` شفّافة عن قصد: `ListTile` ترسم لمستها على أقرب `Material` فوقها، وكلا
/// القسمين اللذين يحملانه صندوقٌ ملوّن — فبغيرها تُرسم اللمسة تحت الصندوق ولا تُرى، وتُطلق
/// Flutter تحذيرها بذلك.
class OrderUrgentSwitch extends StatelessWidget {
  const OrderUrgentSwitch({required this.value, required this.onChanged, super.key});

  final bool value;

  /// Null when the flag may not be moved — a closed order, or a reader without the grant.
  /// `SwitchListTile` greys itself out on a null, which is the whole of the refusal: the
  /// sentence beside it says why, and the server says it again if anything gets past both.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEditable = onChanged != null;

    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        // الأحمر نفسه الذي تلبسه الشارة على البطاقة، حتى لا يتعلّم القارئ لوناً ثانياً لمعنى
        // واحد.
        activeTrackColor: scheme.error,
        title: Row(
          children: [
            Icon(
              AppIcons.urgent,
              size: 18.sp,
              // ورماديّةٌ ما دامت مطفأة: أيقونةٌ حمراء فوق مفتاحٍ لم يُضغط تقول إنّ الطلبية
              // مستعجلة أصلاً. وتبقى حمراء في طلبيةٍ مقفلةٍ كانت مستعجلة: الوسم واقعٌ يُقرأ حتى
              // حين لا يُغيَّر.
              color: value ? scheme.error : scheme.outline,
            ),
            SizedBox(width: 8.w),
            Text(
              'طلبية مستعجلة',
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                // الكلمة تخفت مع المفتاح، فلا يُقرأ الصفّ حيّاً وهو مقفل.
                color: isEditable ? null : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
