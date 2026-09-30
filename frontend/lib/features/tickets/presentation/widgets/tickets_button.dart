import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «التذاكر»، ثالثةَ الأيقونات في الشريط بعد الجرس والأدوات: تذاكر التصميم وتذاكر العملاء معاً.
///
/// **كانت زرَّ تذاكر التصميم وحدها**، وتذاكرُ الدعم صفّاً في الدرج تحت عنوان «الدعم». طلب المستخدم
/// أن تنتقل تذاكر الدعم إلى خانة تذاكر التصميم باسمٍ عامّ (2026-09-25)، فصار الزرّ بابَ
/// [TicketsPage] وتبويبيها. وسببُ خروج التصميم من الدرج أصلاً يصدق على الدعم أيضاً: ما يُفتح كل
/// صباح لا يُطلب بثلاث ضغطات.
///
/// **وبصلاحيّتيهما**، بخلاف [ToolsMenuButton] الواقف إلى جانبه: أيٌّ من
/// [AppPermission.viewDesignTickets] و[AppPermission.viewSupportTickets] يُظهره، ومسارُه في
/// [AppRouter] يردّ مَن لا يملك أيّاً منهما إلى الرئيسية — فأيقونةٌ بلا حاجزٍ هنا تَعِد بشاشةٍ
/// تُغلق في وجه صاحبها. حجبٌ لا تعطيل، كصفوف الدرج تماماً.
///
/// **والأيقونةُ فقاعتا كلام** ([AppIcons.comments])، لا ريشة التصميم التي كان يلبسها: الاسمُ
/// صار عامّاً، والتذكرتان كلتاهما محادثة — مع المصمّم، ومع العميل. وهي نفسُ أيقونة صفّ الدعم
/// الذي كان في الدرج.
///
/// والصلاحية تُقرأ داخل [ValueListenableBuilder] على [Session.revision] لأنها تتبدّل والشجرة
/// قائمة: سحبُ الرئيسية للتحديث يعيد قراءة `/auth/me`، وكذلك التعافي من 403.
class TicketsButton extends StatelessWidget {
  const TicketsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return ValueListenableBuilder<int>(
      valueListenable: session.revision,
      builder: (context, _, _) {
        final mayRead =
            session.can(AppPermission.viewDesignTickets) ||
            session.can(AppPermission.viewSupportTickets);

        if (!mayRead) return const SizedBox.shrink();

        return IconButton(
          tooltip: 'التذاكر',
          // `push` لا `go`: الشاشة التي كان عليها تبقى خلفها، فالرجوع يعيده إلى عمله.
          onPressed: () => context.push(Routes.tickets),
          icon: Icon(AppIcons.comments),
        );
      },
    );
  }
}
