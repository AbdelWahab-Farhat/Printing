import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «هل تريد تسجيل الخروج؟» في ورقةٍ من الأسفل، قريبةٍ من الإبهام الذي لمس الصف في آخر القائمة.
///
/// **تسأل ولا تفعل.** تجيب بـ `true` حين يؤكّد العميل، وبـ `false` لكل ما عدا ذلك: «إلغاء»،
/// والستارة، وزر الرجوع. من يناديها يسأل سؤالاً واحداً، هل خرج أم لا. والشاشة التي فتحتها هي التي
/// تُنهي الجلسة وترسم انشغالها، فالورقة تُغلق فوراً ولا تنتظر الخادم.
///
/// **سؤالٌ بلا سطر شرحٍ تحته.** الحوار القديم كان يقول «ستحتاج إلى رقم هاتفك وكلمة المرور للدخول
/// مرة أخرى»، وهذا يعرفه كل من سجّل دخوله مرة.
Future<bool> showSignOutSheet(BuildContext context) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    // الحافة العليا مستديرة كبقية أوراق التطبيق، فالورقة المربّعة تحت بطاقاتٍ مستديرة تبدو من
    // تطبيقٍ آخر.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) => const _SignOutSheet(),
  );

  return confirmed ?? false;
}

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SafeArea(
      // مؤشّر الشاشة الرئيسية في آيفون يجلس حيث يجلس الزر الأخير.
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.logout, size: 28.sp, color: scheme.error),
            ),
            SizedBox(height: 16.h),
            Text(
              'هل تريد تسجيل الخروج؟',
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 24.h),
            // جنباً إلى جنب لا فوق بعضهما، و«تسجيل الخروج» أوّلاً في القراءة. وبلا وهج: في ورقةٍ
            // بهذا الضيق يسيل الوهج على «إلغاء» بجانبه.
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'تسجيل الخروج',
                    lifted: false,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: AppButton.outlined(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
