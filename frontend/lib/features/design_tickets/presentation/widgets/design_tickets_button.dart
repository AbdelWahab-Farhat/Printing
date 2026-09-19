import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// تذاكر التصميم، ثالثةَ الأيقونات في الشريط بعد الجرس والأدوات.
///
/// **لماذا خرجت من الدرج.** الصفّ كان تحت «المنتجات والخدمات»، وهو تصنيفٌ صادق: التصميم خدمةٌ
/// من خدمات الورشة. لكن التذاكر ليست شاشةً تُقرأ مرّةً في الأسبوع كبقيّة ما تحت ذاك العنوان —
/// المصمّم يفتحها كل صباح، والموظف يفتحها ليرى أين وصل ما طلبه، وكلاهما يعود منها إلى الشاشة
/// التي كان عليها. وما يُفتح بهذا التواتر لا يُطلب بثلاث ضغطات: الدرج، ثم العنوان، ثم الصفّ.
///
/// **وبصلاحيّتها**، بخلاف [ToolsMenuButton] الواقف إلى جانبها: خلف هذه الأيقونة بيانات، ومسارها
/// في [AppRouter] يردّ من لا يملك [AppPermission.viewDesignTickets] إلى الرئيسية — فأيقونةٌ بلا
/// حاجزٍ هنا تَعِد بشاشةٍ تُغلق في وجه صاحبها. حجبٌ لا تعطيل، كصفوف الدرج تماماً: الحاجز هو
/// المسار، وهذا أدبُه.
///
/// والصلاحية تُقرأ داخل [ValueListenableBuilder] على [Session.revision] لأنها تتبدّل والشجرة
/// قائمة: سحبُ الرئيسية للتحديث يعيد قراءة `/auth/me`، وكذلك التعافي من 403.
///
/// ملفُّه الخاص كـ[NotificationBell] و[ToolsMenuButton] اللذين يقف بجانبهما: الشريط يبنيه
/// [RootPage] من شِقٍّ يحتاج [StatefulNavigationShell] ليُبنى أصلاً، وهذا لا يحتاجه — فهو هنا
/// يُختبر تحت موجِّهٍ عارٍ.
class DesignTicketsButton extends StatelessWidget {
  const DesignTicketsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return ValueListenableBuilder<int>(
      valueListenable: session.revision,
      builder: (context, _, _) {
        if (!session.can(AppPermission.viewDesignTickets)) return const SizedBox.shrink();

        return IconButton(
          tooltip: 'تذاكر التصميم',
          // `push` لا `go`: الشاشة التي كان عليها تبقى خلفها، فالرجوع يعيده إلى عمله.
          onPressed: () => context.push(Routes.designTickets),
          // نفس ريشة الصفّ الذي كان في الدرج، ليعرفها من كان يفتحه من هناك.
          icon: Icon(AppIcons.designs),
        );
      },
    );
  }
}
