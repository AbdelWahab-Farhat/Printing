import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الأدوات، بجانب الجرس بدل أن تكون عنواناً في الدرج.
///
/// **لماذا خرجت من الدرج.** الدرج خريطةُ النظام: كل عنوانٍ فيه يفتح على شاشاتٍ تُقرأ منها
/// بيانات. والأدوات وحدها لا تقرأ من الخادم ولا تكتب فيه — يفتحها الموظف وهو يجهّز طلبية ليخرج
/// بشيءٍ في يده ثم يعود إلى ما كان فيه. وشيءٌ يُفتح بهذا التواتر لا يُطلب بثلاث ضغطات: الدرج،
/// ثم العنوان، ثم الصفّ. هنا هي ضغطتان من أي تبويبة، والشاشة التي كان عليها لا تزال خلفها.
///
/// **قائمةٌ لا شاشة.** لا صفحة على `/tools` ولم تكن — انظر [Routes.qrTool]. فالزرّ يفتح ما كان
/// العنوان يفتحه: صفَّي الأداتين، لا صفحةً وسطى تُفتح لتُفتح منها صفحة.
///
/// **وبلا صلاحية على أيّ صفّ**: لا بيانات خلف هاتين الشاشتين، فحجبُ مولّد رمز QR عن موظف هو
/// منعُه من أداةِ حاسبة.
///
/// ملفُّه الخاص كـ[NotificationBell] الذي يقف بجانبه: الشريط يبنيه [RootPage] من شِقٍّ يحتاج
/// [StatefulNavigationShell] ليُبنى أصلاً، وهذا لا يحتاجه — فهو هنا يُختبر تحت موجِّهٍ عارٍ.
class ToolsMenuButton extends StatelessWidget {
  const ToolsMenuButton({this.canQuotePrices = false, super.key});

  /// Whether the reader holds `products.view`, decided by the shell from the session.
  ///
  /// The price calculator is the one tool with records behind it — the catalogue's prices — so
  /// it is the one row that is not for everybody. Passed in rather than read here, so the menu
  /// is still built under a bare router in its test.
  final bool canQuotePrices;

  /// The price calculator first: of the three it is the one opened with a customer waiting.
  static const _priceCalculator = (
    icon: _calculatorIcon,
    label: 'حاسبة الأسعار',
    route: Routes.priceCalculator,
  );

  /// الأداتان، بنفس ترتيبهما حين كانتا صفّين تحت العنوان.
  static const List<({IconData Function() icon, String label, String route})> _tools = [
    (icon: _qrIcon, label: 'إنشاء QR', route: Routes.qrTool),
    (icon: _bagIcon, label: 'معاينة التصميم', route: Routes.bagPreview),
  ];

  /// دوالٌ لا قيم، لأن [AppIcons] يختار الغلاف حسب المنصّة وقت التشغيل والقائمة أعلاه `const`.
  static IconData _calculatorIcon() => AppIcons.priceCalculator;

  static IconData _qrIcon() => AppIcons.qrCode;

  static IconData _bagIcon() => AppIcons.bagPreview;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return PopupMenuButton<void>(
      tooltip: 'الأدوات',
      icon: Icon(AppIcons.tools),
      // تحت الزرّ، فلا تهبط الورقة على عنوان الشاشة.
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (context) => [
        for (final tool in [if (canQuotePrices) _priceCalculator, ..._tools])
          PopupMenuItem<void>(
            // `onTap` يُنفَّذ بعد انغلاق القائمة، وهو المطلوب: لا تبقى الورقة مفتوحةً خلف
            // الشاشة التي فتحتها.
            onTap: () => context.push(tool.route),
            child: Row(
              children: [
                Icon(tool.icon(), size: 19.sp, color: scheme.onSurface),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    tool.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
