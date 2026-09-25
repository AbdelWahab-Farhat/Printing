import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بندٌ في قائمة الرسالة.
@immutable
class MessageMenuAction {
  const MessageMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool isDestructive;
}

/// الضغطة المطوّلة على رسالة، كما في تيليغرام: **الرسالة تبقى في مكانها واضحةً فوق محادثةٍ
/// مضبّبةٍ معتمة، وقائمةٌ صغيرة تطفو بجانبها** — تحتها إن اتّسع المكان، وإلا فوقها.
///
/// [bubbleContext] سياقُ الفقاعة نفسها، ومنه يُقرأ مكانها على الشاشة. و[preview] الفقاعة مرسومةً
/// وحدها — `MessageBubble(detached: true)` — تُوضع فوق الضباب في المستطيل نفسه تماماً، فلا تتحرّك.
///
/// **الحركة شفافيةٌ وإزاحةٌ صغيرة وحدهما** (RULES §7): الضباب يظهر بالتلاشي، والقائمة تنزلق
/// بضع نقاط. ومع «تقليل الحركة» تظهر كلها دفعةً بلا Ticker.
Future<void> showMessageMenu(
  BuildContext bubbleContext, {
  required Widget preview,
  required List<MessageMenuAction> actions,
  required bool alignsToEnd,
}) async {
  if (actions.isEmpty) return;

  final box = bubbleContext.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return;

  final anchor = box.localToGlobal(Offset.zero) & box.size;
  final instant = MediaQuery.disableAnimationsOf(bubbleContext);

  // لمسةٌ خفيفة تقول «أُمسكت»، ولا يُنتظر جوابها: القائمة لا تتأخّر عن الإصبع.
  unawaited(HapticFeedback.selectionClick());

  final chosen = await Navigator.of(bubbleContext).push<MessageMenuAction>(
    PageRouteBuilder<MessageMenuAction>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      transitionDuration: instant ? Duration.zero : const Duration(milliseconds: 180),
      reverseTransitionDuration: instant ? Duration.zero : const Duration(milliseconds: 140),
      pageBuilder: (context, animation, _) => _MessageMenu(
        anchor: anchor,
        preview: preview,
        actions: actions,
        alignsToEnd: alignsToEnd,
        animation: animation,
      ),
    ),
  );

  chosen?.onSelected();
}

class _MessageMenu extends StatelessWidget {
  const _MessageMenu({
    required this.anchor,
    required this.preview,
    required this.actions,
    required this.alignsToEnd,
    required this.animation,
  });

  final Rect anchor;
  final Widget preview;
  final List<MessageMenuAction> actions;
  final bool alignsToEnd;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final gap = 8.h;
    final rowHeight = 48.h;
    final menuWidth = 214.w;
    final menuHeight = rowHeight * actions.length + 12.h;

    // تحت الفقاعة إن اتّسع المكان، وإلا فوقها — ولا تخرج عن الشاشة في الحالتين.
    final fitsBelow = anchor.bottom + gap + menuHeight < screen.height - padding.bottom - 12.h;
    final top = fitsBelow
        ? anchor.bottom + gap
        : math.max(padding.top + 12.h, anchor.top - gap - menuHeight);

    // على حافة الفقاعة من جهة صاحبها: رسائلي في نهاية السطر، ورسائل الدعم في بدايته.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final onLeft = alignsToEnd == rtl;
    final left = (onLeft ? anchor.left : anchor.right - menuWidth)
        .clamp(12.w, math.max(12.w, screen.width - menuWidth - 12.w))
        .toDouble();

    final slide = Tween<Offset>(
      begin: Offset(0, fitsBelow ? -0.04 : 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: FadeTransition(
              opacity: animation,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.28)),
              ),
            ),
          ),
        ),
        Positioned.fromRect(rect: anchor, child: IgnorePointer(child: preview)),
        Positioned(
          left: left,
          top: top,
          width: menuWidth,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: Material(
                color: scheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in actions)
                        _MenuRow(
                          action: action,
                          height: rowHeight,
                          onTap: () => Navigator.of(context).pop(action),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action, required this.height, required this.onTap});

  final MessageMenuAction action;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = action.isDestructive ? scheme.error : scheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action.label,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(action.icon, size: 22.sp, color: action.isDestructive ? ink : scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
