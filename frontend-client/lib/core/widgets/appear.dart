import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Fades a card in and lifts it into place the first time it is built.
///
/// The whole of the app's "liveliness" budget is spent here, on purpose. A screen full of cards
/// that simply *appear* reads as a screenshot; the same cards arriving over a fifth of a second,
/// each a little after the one before it, read as a screen that is doing something. It is the
/// cheapest motion there is — no controller, no state, no rebuild after it settles.
///
/// **The stagger is faked, and deliberately so.** A real delay per card needs a controller and a
/// timer each; giving each card a slightly longer *duration* instead produces the same "one
/// after another" reading for one `TweenAnimationBuilder`. [index] is clamped, because the
/// eleventh card arriving a second late is not a stagger, it is a stall.
///
/// **It never runs twice.** `TweenAnimationBuilder` animates when its tween changes, and this
/// one's never does — a rebuild from a state change leaves the card exactly where it is rather
/// than fading it in again.
///
/// Honours "reduce motion": with it on, the child is returned as it is, in one frame.
class Appear extends StatelessWidget {
  const Appear({required this.child, this.index = 0, super.key});

  final Widget child;

  /// Position in the list this card belongs to. Later cards take slightly longer to arrive.
  final int index;

  /// Beyond this, extra delay stops reading as sequence and starts reading as lag.
  static const int _maxStaggered = 8;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final step = index.clamp(0, _maxStaggered);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + step * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        // Translation only — never a scale. A card that grows into place drags the layout
        // around it and makes the eye re-find everything below.
        child: Transform.translate(offset: Offset(0, (1 - value) * 18.h), child: child),
      ),
      child: child,
    );
  }
}
