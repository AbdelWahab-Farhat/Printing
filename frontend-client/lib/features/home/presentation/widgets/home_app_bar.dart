import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// شريط الرئيسية العلوي: اسم المتجر في الوسط، والدعم و«حسابي» في طرفه، كشريط تطبيق بريمولا.
///
/// **بلا ترحيبٍ ولا رقم العميل ولا جرس** (طلب المستخدم، 2026-09-25). الرقم ما زال في «حسابي»
/// لمن يحتاج أن يقرأه في مكالمة. والجرس خرج من الرئيسية وحدها، وبقي في شرائط الأقسام الأخرى.
///
/// **`actions` تُرتَّب من الحافة الخلفية إلى الداخل**، والتطبيق من اليمين، فآخرها أقربها إلى
/// حافة الشاشة اليسرى: «حسابي» في الطرف، والدعم بجانبه.
///
/// والاثنان يُدفعان (`push`) ولا يُنتقل إليهما (`go`): كلاهما مكانٌ يُذهب إليه ويُرجع منه إلى
/// الرئيسية، ولا تبويب لأيٍّ منهما.
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
        // الأيقونة نفسها التي كانت على مربع «الدعم»، وعليها ما لم يُقرأ من ردود المتجر.
        IconButton(
          icon: BadgedIcon(icon: AppIcons.comments, badge: CustomerBadge.support),
          tooltip: 'الدعم',
          onPressed: () => context.push(Routes.support),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(end: 4.w),
          child: IconButton(
            icon: Icon(AppIcons.person),
            tooltip: 'حسابي',
            onPressed: () => context.push(Routes.profile),
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
