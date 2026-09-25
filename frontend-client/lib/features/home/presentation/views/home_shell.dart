import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

/// الشريط الذي تعيش خلفه الأقسام الثلاثة.
///
/// **الأقسام تبقى في الشجرة وإن لم تُعرض**، فيحتفظ كلٌّ منها بموضع تمريره وبالـ Cubit الخاص به:
/// العميل الذي ينزل إلى منتصف الكتالوج ثم يلقي نظرةً على طلبية يعود فيجده حيث تركه. الحاوية
/// التي تحفظها وتنقل بينها بالتلاشي هي `FadeThroughBranches`، يبنيها الموجّه لا هذا الملف.
///
/// **ثلاثة أماكن، أيقوناتٍ بلا كلمات** (طلب المستخدم، 2026-09-25): الرئيسية، والمنتجات،
/// وطلباتي. «حسابي» في شريط الرئيسية العلوي، و«تصاميمي» والأدوات صفوفٌ في «حسابي». و«الخدمات»
/// كانت تبويباً رابعاً ثم نُزعت في اليوم نفسه، لأن صفوفها كلها في «حسابي». والكلمات لم تختفِ
/// تماماً: كل أيقونةٍ تحمل اسمها لقارئ الشاشة.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: shell.currentIndex,
        // `initialLocation` على القسم المعروض أصلاً: لمس التبويب الذي أنت فيه يعيده إلى أول
        // شاشاته، كما يفعل كل تطبيق وكما يجرّب الناس.
        onSelect: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// أماكن الشريط بترتيب القراءة، والأول أقربها إلى اليمين.
///
/// **بترتيب فروع الـ shell في `AppRouter` نفسه**: موضع المكان في هذه القائمة هو رقم فرعه.
List<({IconData icon, String label})> get _tabs => [
  (icon: AppIcons.home, label: 'الرئيسية'),
  (icon: AppIcons.products, label: 'المنتجات'),
  (icon: AppIcons.orders, label: 'طلباتي'),
];

/// أيقونة مكانٍ في الشريط، باسمها وبأنها المعروضة لقارئ الشاشة.
///
/// لونها يتبدّل في الإطار نفسه لا بالتدريج: التدرّج يحمله ظهور الخلفية خلفها.
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.label, required this.isCurrent});

  final IconData icon;
  final String label;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      label: label,
      selected: isCurrent,
      child: ExcludeSemantics(
        child: Icon(
          icon,
          size: 24.sp,
          color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// كبسولةٌ عائمة فوق حافة الشاشة، كشريط تطبيق بريمولا.
///
/// **`google_nav_bar` بلا نصٍّ على أي زر.** النصّ فيها يفتح الزرّ عرضاً، وقواعد الحركة لا تسمح
/// بعنصرٍ يتغيّر مقاسه (RULES §7). وبلا نصٍّ يبقى التبدّل لونين: خلفية الأيقونة النشطة تظهر
/// بالتلاشي، ولون الأيقونة يتبدّل. ومع «تقليل الحركة» المدة صفر، فلا يعمل أي Ticker.
///
/// **والظل ثابت**: قيمةٌ واحدة لا تتحرك، كظل `AppButton`.
class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.10),
                blurRadius: 24.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: GNav(
              selectedIndex: currentIndex,
              onTabChange: onSelect,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              duration: still ? Duration.zero : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              tabBackgroundColor: scheme.primary.withValues(alpha: 0.12),
              rippleColor: scheme.primary.withValues(alpha: 0.08),
              hoverColor: scheme.primary.withValues(alpha: 0.04),
              tabs: [
                for (final (index, tab) in _tabs.indexed)
                  GButton(
                    icon: tab.icon,
                    // **الأيقونة تُسلَّم جاهزة، لأن `GNav` يُسقط اسمها.** يعيد بناء كل زرٍّ من
                    // خصائصه وينسى `semanticLabel` بينها، فيصل الزر إلى قارئ الشاشة بلا اسم —
                    // وشريطٌ بلا كلمات هو بالضبط الشريط الذي لا يُعرف فيه زرٌّ إلا باسمه. أما
                    // `leading` فيمرّره كما هو.
                    leading: _TabIcon(
                      icon: tab.icon,
                      label: tab.label,
                      isCurrent: index == currentIndex,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
