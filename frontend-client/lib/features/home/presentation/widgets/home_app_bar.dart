import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الشريط العلوي الذي تلبسه الأقسام الأربعة: اسم المتجر في الوسط، والدعم في طرفه، كشريط تطبيق
/// بريمولا.
///
/// **و«حسابي» ليست هنا** (طلب المستخدم، 2026-09-25: «حط بروفايل تحت»): كانت أيقونةً في الطرف
/// بجانب الدعم، ونزلت إلى الشريط السفلي تبويباً رابعاً.
///
/// **واحدٌ على الـ shell، لا نسخةٌ في كل قسم** (طلب المستخدم، 2026-09-25). كان لكل قسمٍ شريطه:
/// الاسم في الرئيسية، و«المنتجات» والسلة في الكتالوج، و«طلباتي» وحدها في الطلبيات، فيتبدّل أعلى
/// الشاشة مع كل لمسةٍ في أسفلها. `HomeShell` يضعه فوق الأقسام، فيبقى ساكناً والقسم تحته يتلاشى.
///
/// **بلا ترحيبٍ ولا رقم العميل ولا جرس** (طلب المستخدم، 2026-09-25). الرقم ما زال في «حسابي»
/// لمن يحتاج أن يقرأه في مكالمة. والجرس أُزيل من التطبيق كله: لا خادم للإشعارات بعد.
///
/// **`actions` تُرتَّب من الداخل إلى الحافة**، والتطبيق من اليمين، فآخرها أقربها إلى حافة الشاشة
/// اليسرى: الدعم في الطرف، والسلة بجانبه.
///
/// وكلاهما يُدفع (`push`) ولا يُنتقل إليه (`go`): كلٌّ منهما مكانٌ يُذهب إليه ويُرجع منه إلى القسم
/// الذي كان فيه العميل، ولا تبويب لأيٍّ منهما.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const _Wordmark(),
      actions: [
        // **السلة في الداخل لا في الطرف.** لا تُرسم وهي فارغة، فلو كانت في الطرف لدفعت الدعم
        // إلى الداخل كلّما امتلأت. هنا تظهر بجانبه ولا يتحرّك شيء.
        const CartButton(),
        // الأيقونة نفسها التي كانت على مربع «الدعم»، وعليها ما لم يُقرأ من ردود المتجر.
        Padding(
          padding: EdgeInsetsDirectional.only(end: 4.w),
          child: IconButton(
            icon: BadgedIcon(icon: AppIcons.comments, badge: CustomerBadge.support),
            tooltip: 'الدعم',
            onPressed: () => context.push(Routes.support),
          ),
        ),
      ],
    );
  }
}

/// «FlyerX» مكتوباً كما يكتب شريط بريمولا اسمه: «Flyer» بلون العنوان، و«X» ببرتقالي العلامة كما
/// في الشعار المطبوع.
///
/// **ليس `BrandMark`**: ذاك بمقاس ترويسة شاشة الدخول وبلون ترويستها الكحلية، وهذا بمقاس شريطٍ
/// ولون سطحه. والاسم لاتينيٌّ في تطبيقٍ من اليمين، فاتجاهه مثبّت.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Flyer', style: TextStyle(color: scheme.onSurface)),
          TextSpan(text: 'X', style: TextStyle(color: scheme.primary)),
        ],
      ),
      style: context.textTheme.titleLarge?.copyWith(
        fontSize: 26.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      textDirection: TextDirection.ltr,
    );
  }
}
