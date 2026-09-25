import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صفوفٌ في بطاقةٍ واحدة، كقائمة الملف الشخصي في المرجع: أيقونةٌ في دائرة، واسمٌ، وسهمٌ إلى حيث
/// يذهب الصف. تستعملها «حسابي» و«الإعدادات».
///
/// **بطاقةٌ واحدة لا بطاقةٌ لكل صف.** الصفوف خياراتٌ من قائمةٍ واحدة، وبطاقةٌ لكلٍّ منها تجعل
/// ثلاثة خياراتٍ تبدو ثلاثة أشياء. والبطاقة هي [AppCard] نفسها، فلونها وحدّها وزواياها هي ما في
/// بقية التطبيق.
///
/// **ولا سطر شرحٍ تحت الاسم.** المرجع يضع جملةً رمادية تحت كل صف، وهذا التطبيق نزع مثلها من كل
/// مكانٍ ظهرت فيه: الاسم يحمل المعنى، وما يُرسم بجانبه قيمةٌ ([MenuRow.value]) لا شرح.
class MenuCard extends StatelessWidget {
  const MenuCard({required this.rows, super.key});

  final List<MenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // الصفوف تمتدّ إلى حافتَي البطاقة لتصل موجة اللمس إليهما، والفراغ فوقها وتحتها وحده.
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// صفٌّ واحد في [MenuCard]، وشكله يقول ما يفعله قبل أن يُلمس:
///
/// * له [onTap]: يذهب إلى مكان، فله سهم.
/// * [onTap] فارغ: لم يُفتح بعد. باهتٌ، بلا سهمٍ ولا حبر، ولا يستجيب، و[badge] يقول لماذا.
/// * [isDestructive]: يُنهي شيئاً، كتسجيل الخروج. بلون الخطأ، وبلا سهم لأنه ليس مكاناً.
/// * [isBusy]: يعمل الآن. الدائرة تدور مكان الأيقونة، والصف لا يأخذ لمسةً ثانية **ولا يبهت** —
///   المشغول ليس معطّلاً، والصف الذي يشحب في منتصف الطلب يبدو كأنه تعطّل.
class MenuRow extends StatelessWidget {
  const MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.badge,
    this.isDestructive = false,
    this.isBusy = false,
    super.key,
  });

  final IconData icon;
  final String label;

  /// فارغٌ يعني «غير متاحٍ بعد»، لا «مشغول» — للانشغال [isBusy].
  final VoidCallback? onTap;

  /// ما عليه الصف الآن، مرسومٌ قبل السهم: «داكن» بجانب «مظهر التطبيق». كثيرٌ ممن يفتحون صفاً
  /// يفتحونه ليعرفوا جوابه لا ليغيّروه، والقيمة الظاهرة توفّر عليهم تلك الفتحة.
  final String? value;

  /// شارةٌ صغيرة مكان السهم، مثل «قريباً» على صفٍّ لم يُفتح بعد.
  final String? badge;

  final bool isDestructive;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEnabled = onTap != null;
    final tint = isDestructive ? scheme.error : scheme.primary;

    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: [
          _Glyph(icon: icon, tint: tint, isBusy: isBusy),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDestructive ? scheme.error : scheme.onSurface,
              ),
            ),
          ),
          if (value case final value?) ...[
            SizedBox(width: 8.w),
            Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (badge case final badge?) ...[
            SizedBox(width: 8.w),
            _Badge(badge),
          ] else if (isEnabled && !isDestructive) ...[
            SizedBox(width: 8.w),
            // `forward` يتّجه يساراً في العربية، إلى حيث يمضي القارئ.
            Icon(AppIcons.forward, size: 18.sp, color: scheme.onSurfaceVariant),
          ],
        ],
      ),
    );

    // بلا `InkWell` أصلاً لا `InkWell` بلا فعل: ما لا يُلمس لا يرسم حبراً يَعِد بشيء.
    if (!isEnabled) {
      return Semantics(
        button: true,
        enabled: false,
        child: Opacity(opacity: 0.5, child: row),
      );
    }

    return InkWell(onTap: isBusy ? null : onTap, child: row);
  }
}

/// الدائرة التي يحملها كل صفٍّ على حافته الأولى، بلون الصف الخفيف والأيقونة بلونه الكامل.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon, required this.tint, required this.isBusy});

  final IconData icon;
  final Color tint;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: isBusy
          ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: tint),
            )
          : Icon(icon, size: 21.sp, color: tint),
    );
  }
}

/// «قريباً» — الشكل نفسه الذي تضعه الرئيسية على «متجر الكروت».
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
