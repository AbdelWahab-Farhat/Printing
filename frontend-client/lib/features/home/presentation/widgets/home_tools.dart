import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الأداتان على الرئيسية، بخفّة (طلب المستخدم، 2026-09-25): «رمز QR» و«معاينة على الكيس» في صفٍّ
/// واحد من بطاقتين صغيرتين.
///
/// **بلا عنوان قسمٍ ولا «عرض الكل».** اسمان يقولان ما هما، وعنوانٌ فوقهما يجعل الصفّ قسماً ثالثاً
/// يزاحم الطلبيات على الانتباه. والبطاقة بارتفاع سطرٍ واحد: أيقونةٌ صغيرة واسم، لا مربّعٌ كبير.
///
/// **فوق الطلبيات لا تحتها.** الطلبيات لا حدّ لعددها، فما تحتها يُدفع إلى الأسفل مع كل طلبيةٍ
/// جديدة.
///
/// وهما ما زالتا صفّين في «حسابي»: هذا طريقٌ أقصر إليهما، لا مكانهما الوحيد. وكلتاهما تُدفع
/// (`push`) فوق الـ shell ويُرجع منها، كما من «حسابي».
class HomeTools extends StatelessWidget {
  const HomeTools({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      // بترتيبهما في «حسابي»: «رمز QR» أولاً، أي يميناً.
      child: Row(
        children: [
          Expanded(
            child: _ToolTile(
              icon: AppIcons.qrCode,
              label: 'رمز QR',
              onTap: () => context.push(Routes.qrTool),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _ToolTile(
              icon: AppIcons.bagPreview,
              label: 'معاينة على الكيس',
              onTap: () => context.push(Routes.bagPreview),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة أداةٍ واحدة: الدائرة الملوّنة التي تحملها صفوف «حسابي» (`MenuRow`) أصغرَ، والاسم بجانبها.
///
/// **بلا سهم.** السهم في صفوف «حسابي» يقول إن الصف مكانٌ يُذهب إليه من قائمة، والبطاقة نفسها تقول
/// ذلك هنا.
///
/// **الاسم بمقاس الثيم، والبطاقة تفسح له.** «معاينة على الكيس» بـ`bodyMedium` العريض — خطّ ملخّص
/// الطلبية تحتها — يأخذ ١١٥ بكسلاً بـCairo، ومقاسات الثيم لا تصغر مع الشاشة كما تصغر `.w`. فالدائرة
/// والهوامش هنا أضيق منها في `MenuRow`، ليتّسع الاسم كاملاً على هاتفٍ بعرض ٣٦٠ (يبقى له ١١٨).
/// والنقاط الثلاث (`ellipsis`) لما هو أضيق من ذلك، أو لخطٍّ كبّره صاحب الهاتف.
class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17.sp, color: scheme.primary),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
