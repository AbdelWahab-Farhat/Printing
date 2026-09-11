import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/home/models/home_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «بانتظار رسالة الجاهزية» — الطلبيات المصنوعة التي لم يُبلَّغ أصحابها بعد.
///
/// **صندوقٌ واحدٌ عريض، لا بطاقةٌ في لوحة**، وهذا هو الفرق بينه وبين ما فوقه: لوحة الحالات
/// ولوحة الدفع تقسمان الطلبيات كلّها على محاورها، وهذا طابورُ عملٍ يخصّ شخصاً واحداً — يفتحه
/// صباحاً، ويمشي عليه سطراً سطراً، ويُفرغه. بطاقةٌ بحجم البطاقات بين أربع عشرة بطاقةً أخرى تجعله
/// شيئاً يُمرَّ عليه بالعين لا شيئاً يُعمَل به.
///
/// **ولونه ثالثٌ لا يلبسه شيءٌ آخر على هذه الشاشة.** الأخضر يعني «انتهى» والأحمر يعني «دَين»،
/// وكلاهما محجوز؛ و`tertiaryContainer` هو اللون الذي تقرؤه العين على أنّه معلومةٌ تنتظر عملاً.
///
/// **ولا يُرسَم إطلاقاً لمن لا يملك `orders.ready_message`** — الخادم يحذف المفتاح أصلاً، فلا
/// يبقى للشاشة ما ترسمه. من لا يعنيه هذا الطابور لا يرى مكانه فارغاً.
class ReadyMessageBox extends StatelessWidget {
  const ReadyMessageBox({required this.queue, this.onOpen, super.key});

  final ReadyMessageQueue queue;

  /// Opens the orders behind the number. Null leaves the box readable and inert.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **صندوقٌ يعدّ صفراً يبقى مرسوماً ولا يُفتح** — كبطاقات الدفع فوقه. «لا شيء ينتظر» جوابٌ
    // يُقرأ مرّةً كل صباح، وفتحُ شاشةٍ فارغة ضغطةٌ لا تعلّم القارئ ما لم يره.
    final waiting = queue.count > 0;

    return Material(
      color: waiting ? scheme.tertiaryContainer : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: waiting ? onOpen : null,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: waiting
                  ? scheme.tertiary.withValues(alpha: 0.35)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.readyMessage,
                size: 24.sp,
                color: waiting ? scheme.onTertiaryContainer : scheme.outline,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  // كلمة الخادم نفسها: هذا التطبيق لا يحمل جدول أسماء، وعنوان الشاشة التي يفتحها
                  // الصندوق لا يأتي إلا من الصندوق الذي فتحها.
                  queue.label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: waiting ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                queue.count.grouped,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: waiting ? scheme.onTertiaryContainer : scheme.onSurface,
                ),
              ),
              if (waiting && onOpen != null) ...[
                SizedBox(width: 4.w),
                Icon(AppIcons.forward, size: 18.sp, color: scheme.onTertiaryContainer),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
