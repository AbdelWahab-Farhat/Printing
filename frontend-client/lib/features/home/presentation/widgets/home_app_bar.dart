import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:dayaa_client/features/orders/presentation/views/cart_button.dart';
import 'package:dayaa_client/features/wallet/presentation/views/wallet_balance_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// الشريط العلوي الذي تلبسه الأقسام الأربعة: اسم المتجر في الوسط، والدعم والسلة في طرفه الأيمن،
/// ورصيد المحفظة في الأيسر، كشريط تطبيق بريمولا.
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
/// **رصيد المحفظة في أقصى اليسار، والدعم انتقل إلى أقصى اليمين** (طلب المستخدم، 2026-10-16).
/// كان الدعم في الطرف الأيسر والسلة بجانبه؛ ولمّا أخذ الرصيد الطرف، صارت ثلاثتها أعرض من نصف
/// الشريط فدفعت الاسم عن الوسط كلما امتلأت السلة. اختار المستخدم نقل الدعم إلى الطرف الفارغ على
/// أن يُزاح الاسم.
///
/// **السلة انتقلت إلى جانب الدعم، وكلٌّ منهما في دائرة** (طلب المستخدم، 2026-10-20: «اقلب يمين
/// وخليها واضحة بإنها ايقونة هي وتذاكر بداخل سيركل افتار»). الدائرة بالبرتقالي الخفيف نفسه الذي
/// تلبسه حبّة الرصيد ودوائر الأدوات في الرئيسية، فتُقرأ الثلاثة أزراراً من عائلةٍ واحدة. والرصيد
/// بقي وحده في الطرف الأيسر.
///
/// والثلاثة تُدفع (`push`) ولا يُنتقل إليها (`go`): كلٌّ منها مكانٌ يُذهب إليه ويُرجع منه إلى القسم
/// الذي كان فيه العميل، ولا تبويب لأيٍّ منها.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// قطر الدائرتين، والفراغ بينهما.
  static double get _circle => 40.w;
  static double get _gap => 8.w;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final circle = IconButton.styleFrom(
      backgroundColor: scheme.primary.withValues(alpha: 0.12),
      foregroundColor: scheme.primary,
      shape: const CircleBorder(),
      fixedSize: Size.square(_circle),
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      iconSize: 22.sp,
      // الدائرة هي الزرّ كلّه: هامش اللمس الخفيّ حولها كان سيجعل كلّاً منها ٤٨ عرضاً في الصف.
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      // هامش الصفحة، ثم الدعم في الطرف، ثم السلة في داخله. وحافة الدائرة الخارجية على حافة
      // بطاقات الصفحة تحتها، كحبّة الرصيد في الطرف الآخر.
      leadingWidth: 16.w + _circle + _gap + _circle,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(start: 16.w),
        child: Row(
          children: [
            // الأيقونة نفسها التي كانت على مربع «الدعم»، وعليها ما لم يُقرأ من ردود المتجر.
            IconButton(
              icon: BadgedIcon(icon: AppIcons.comments, badge: CustomerBadge.support),
              tooltip: 'الدعم',
              style: circle,
              onPressed: () => context.push(Routes.support),
            ),
            SizedBox(width: _gap),
            CartButton(style: circle),
          ],
        ),
      ),
      title: const _Wordmark(),
      actions: [
        // حافة الحبّة على حافة بطاقات الصفحة تحتها.
        Padding(
          padding: EdgeInsetsDirectional.only(end: 16.w),
          child: const Center(child: WalletBalanceChip()),
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
