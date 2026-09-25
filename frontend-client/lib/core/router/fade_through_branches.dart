import 'package:flutter/material.dart';

/// الحاوية التي تعرض أقسام الشريط السفلي: القسم الجديد يظهر بتلاشٍ بدل الظهور الفوري.
///
/// **بديل `IndexedStack` الذي يبنيه `StatefulShellRoute.indexedStack`، وبضماناته نفسها.** الأقسام
/// كلها تبقى في الشجرة، فيحتفظ كل قسم بموضع تمريره وبالـ Cubit الخاص به. والقسم المخفي لا يستقبل
/// لمساً ولا تركيزاً، ولا تعمل حركاته. الذي تغيّر هو الانتقال وحده.
///
/// **تلاشٍ متتابع (fade through)، لا متقاطع.** القديم يخرج في أول ٣٠٪ من المدة، ثم يدخل الجديد في
/// الباقي، فلا تظهر صفحتان مختلفتان فوق بعضهما في لحظة واحدة. هذه أرقام نمط fade through في
/// Material ومنحنياته، من دون التكبير الذي فيه، لأن قواعد الحركة لا تسمح إلا بالإزاحة والشفافية.
///
/// مع «تقليل الحركة» يعود الانتقال فورياً كما كان، ولا يعمل أي Ticker.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({required this.currentIndex, required this.children, super.key});

  /// القسم المعروض، أي `StatefulNavigationShell.currentIndex`.
  final int currentIndex;

  /// ما يسلّمه go_router: Navigator لكل قسم، بترتيب الأقسام في الشريط.
  final List<Widget> children;

  /// المدة كلها: خروج القديم ثم دخول الجديد.
  static const Duration duration = Duration(milliseconds: 300);

  static const Curve _fadeOut = Interval(0, 0.3, curve: Easing.legacyAccelerate);

  static const Curve _fadeIn = Interval(0.3, 1, curve: Easing.legacyDecelerate);

  @override
  Widget build(BuildContext context) {
    // تُصفَّر المدة ولا تُبنى شجرة أخرى: تغيير شكل الشجرة حين يتغيّر الإعداد يعيد بناء أقسام يجب
    // أن تبقى كما هي. والمدة الصفرية لا تشغّل Ticker أصلاً، بل تُسنَد القيمة في الإطار نفسه.
    final fade = MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          _branch(children[i], isCurrent: i == currentIndex, fade: fade),
      ],
    );
  }

  Widget _branch(Widget navigator, {required bool isCurrent, required Duration fade}) {
    // الشفافية فوق TickerMode عمداً: لو كانت تحته لأوقف TickerMode الحركةَ التي تُخرج القسم القديم.
    return AnimatedOpacity(
      opacity: isCurrent ? 1 : 0,
      duration: fade,
      curve: isCurrent ? _fadeIn : _fadeOut,
      child: IgnorePointer(
        // كل الأقسام بحجم الشاشة، والقسم المخفي قد يكون فوق الحالي في الكومة فيأخذ لمسه.
        ignoring: !isCurrent,
        child: ExcludeFocus(
          // كما في IndexedStack: مغادرة القسم تُسقط التركيز منه، فتُغلق لوحة المفاتيح.
          excluding: !isCurrent,
          child: TickerMode(enabled: isCurrent, child: navigator),
        ),
      ),
    );
  }
}
