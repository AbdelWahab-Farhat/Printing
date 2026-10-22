import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// «التذاكر»، ثالثةَ الأيقونات في الشريط بعد الجرس والأدوات: تذاكر التصميم وتذاكر العملاء وتذاكر
/// الموظفين معاً.
///
/// **كانت زرَّ تذاكر التصميم وحدها**، وتذاكرُ الدعم صفّاً في الدرج تحت عنوان «الدعم». طلب المستخدم
/// أن تنتقل تذاكر الدعم إلى خانة تذاكر التصميم باسمٍ عامّ (2026-09-25)، فصار الزرّ بابَ
/// [TicketsPage] وتبويباتها. وسببُ خروج التصميم من الدرج أصلاً يصدق على الدعم أيضاً: ما يُفتح كل
/// صباح لا يُطلب بثلاث ضغطات.
///
/// **ولكل موظف منذ التذاكر الداخلية** (INTERNAL-TICKETS-DESIGN §٦). كان يظهر بإحدى صلاحيتَي
/// التصميم والدعم وحدهما؛ تبويبُ «الموظفين» بلا صلاحية، فالصفحةُ خلفه لا تُغلق في وجه أحد، ومسارُها
/// في [AppRouter] لم يعد يردّ أحداً إلى الرئيسية.
///
/// **والأيقونةُ فقاعتا كلام** ([AppIcons.comments])، لا ريشة التصميم التي كان يلبسها: الاسمُ
/// صار عامّاً، والتذاكرُ كلّها محادثة — مع المصمّم، ومع العميل، ومع الزميل.
class TicketsButton extends StatelessWidget {
  const TicketsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'التذاكر',
      // `push` لا `go`: الشاشة التي كان عليها تبقى خلفها، فالرجوع يعيده إلى عمله.
      onPressed: () => context.push(Routes.tickets),
      icon: Icon(AppIcons.comments),
    );
  }
}
