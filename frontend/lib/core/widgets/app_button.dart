import 'dart:math' as math;
import 'dart:ui' show PathMetric, lerpDouble;

import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How much weight the button carries on the screen it sits on.
///
/// One primary action per screen. Everything else is [tonal] or [outlined] — a screen with two
/// filled buttons has told the user nothing about which one it expects.
enum AppButtonVariant {
  /// The one action the screen exists for: sign in, place the order, save.
  primary,

  /// A supporting action that is still an action — "add a shop", "pick from the map".
  tonal,

  /// The way out: cancel, back, dismiss.
  outlined,
}

/// Every button a screen puts in front of the user.
///
/// It replaces the per-screen `FilledButton` + `styleFrom` block, which is how two screens end
/// up with different corner radii and — the part that actually costs something — different
/// behaviour while a request is in flight.
///
/// The exception is [showCustomDialog], which keeps Material's own buttons: `AlertDialog.actions`
/// lays them out itself, and a dialog's confirm button neither fills a row nor waits on a
/// request, so none of what this widget adds would ever be seen there.
///
/// ## The animation, and the rule it obeys
///
/// **The button never changes size.** Not its layout size, not its apparent size. Every animated
/// value in this file is a translation or an alpha; there is no `Transform.scale`, no animated
/// width, radius or shadow, and nothing is painted outside the shape. A button that grows or
/// shrinks drags the layout around it and makes the eye re-find it on every tap.
///
/// So the box is frozen and everything happens **inside** it:
///
///   * **press** — the legend (icon and label together) sinks 2 logical pixels and dims to 86%,
///     then rides an `elasticOut` back out, overshooting about half a pixel. It is a keycap
///     going down under a thumb. Deliberately quiet: it reads under a finger and does not read
///     in a screenshot,
///   * **busy** — the legend dims to 55% and stays exactly where it is, while a lit thread runs
///     around the inside of the button's own rim. Nothing is swapped out, so there is no
///     cross-fade, no reflow of the Arabic label, and no second widget to make room for,
///   * **reduced motion** — no ticker runs in any state. The press is absent rather than fast,
///     and the busy rim arrives complete and motionless in a single frame.
///
/// None of that is specific to submitting a form. The same two gestures read correctly on a
/// primary "sign in", a tonal "add a shop" and an outlined "cancel", which is why they are the
/// button's character rather than one screen's flourish.
///
/// **What it costs:** while busy, one compositing layer and a re-raster of the button at 60fps,
/// plus two short-lived `Path` allocations per frame at the seam of the running arc. The rim is
/// measured once per rebuild and cached — see [AppButtonThreadPainter], and do not "simplify"
/// that cache away.
///
/// **What it does not decide:** what the tap does, or when it is busy. Both come from the Cubit
/// through the caller.
///
/// ```dart
/// AppButton(
///   label: 'تسجيل الدخول',
///   isLoading: state.isSubmitting,   // not `onPressed: null`
///   onPressed: _submit,
/// )
/// ```
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.expands = true,
    this.variant = AppButtonVariant.primary,
  });

  /// A supporting action. Filled, but in the quiet container colour.
  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.expands = true,
  }) : variant = AppButtonVariant.tonal;

  /// The way out of a screen. A border and nothing behind it.
  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height,
    this.expands = true,
  }) : variant = AppButtonVariant.outlined;

  final String label;

  /// `null` means genuinely unavailable — a form that cannot be submitted at all. For "busy
  /// right now" pass [isLoading] instead and leave this alone: a button that greys out mid
  /// request looks like it broke.
  final VoidCallback? onPressed;

  final bool isLoading;
  final IconData? icon;

  /// Defaults to 54 logical pixels at the reference design size.
  final double? height;

  /// Whether the button takes the whole width it is given.
  ///
  /// **True by default, and that is the rule rather than a convenience.** A button that
  /// shrink-wraps its label is a target the size of the words in it — «إنشاء الطلبية» came out
  /// as a small pill floating in the middle of a phone, with the whole width beneath the form
  /// doing nothing. The action a screen exists for should be as wide as the screen allows, and
  /// the margins around it belong to the screen, not to the button.
  ///
  /// Set it false only where the button genuinely must measure itself against its own label —
  /// and note that a button inside a `Row` should be wrapped in `Expanded` instead, which is
  /// what every one of them in this app already does.
  final bool expands;

  final AppButtonVariant variant;

  /// The button's outer box — the thing whose rectangle must be identical in every state.
  @visibleForTesting
  static const Key surfaceKey = Key('app_button_surface');

  /// The translated layer around the icon and the label, so a test can read what a press did.
  @visibleForTesting
  static const Key contentKey = Key('app_button_content');

  /// The running rim. Absent from the tree entirely unless the button is busy.
  @visibleForTesting
  static const Key threadKey = Key('app_button_thread');

  @override
  State<AppButton> createState() => _AppButtonState();
}

/// The fill, the ink and the border for one variant in one state.
typedef _Palette = ({Color fill, Color onFill, BorderSide side, Color? shadow});

class _AppButtonState extends State<AppButton> with TickerProviderStateMixin {
  /// How far the legend sinks under a press, in logical pixels at the reference size.
  static const double _sink = 2;

  /// Held down. Runs to 1 on contact and back to 0 on release — and briefly *below* 0 on the
  /// way out, which is the overshoot. That is why the lower bound is negative: an
  /// `AnimationController` clamps to its bounds, so a spring with nowhere to go is a spring
  /// that does not spring.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    lowerBound: -0.4,
    upperBound: 1,
    // Stated, and it has to be: a controller given a lower bound starts *at* it, so leaving
    // this out rests every button half a pixel above where it belongs.
    value: 0,
  );

  /// Busy. Fades the rim in and the legend down; also the rim's own opacity, so the thread grows
  /// out of nothing and retracts into nothing instead of blinking.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 200),
    value: widget.isLoading ? 1 : 0,
  );

  /// One trip of the thread around the rim. Linear and repeating: a lap with an eased edge
  /// stutters at the seam.
  late final AnimationController _lap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // Typed as the concrete class, not `Animation<double>`: it owns a listener on its parent and
  // has to be disposed.
  late final CurvedAnimation _revealCurve = CurvedAnimation(
    parent: _reveal,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not only for `isLoading`: the accessibility setting can be turned on while this button is
    // on screen, and a ticker already running has to be stopped.
    _sync();
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) _sync();
  }

  @override
  void dispose() {
    _revealCurve.dispose();
    _lap.dispose();
    _reveal.dispose();
    _press.dispose();
    super.dispose();
  }

  bool get _hasMotion => !MediaQuery.disableAnimationsOf(context);

  /// Brings the three controllers in line with what the widget is being asked to show.
  void _sync() {
    if (!_hasMotion) {
      _press
        ..stop()
        ..value = 0;
      _lap
        ..stop()
        ..value = 0;
      // Assigned, not animated: with motion off the busy state has to be true in the very next
      // frame, so the tree settles and there is nothing left running to wait for.
      _reveal
        ..stop()
        ..value = widget.isLoading ? 1 : 0;

      return;
    }

    if (widget.isLoading) {
      _reveal.forward();
      if (!_lap.isAnimating) _lap.repeat();
    } else {
      _reveal.reverse();
      _lap
        ..stop()
        ..value = 0;
    }
  }

  void _onHighlightChanged(bool isPressed) {
    if (!_hasMotion) return;

    // The curve lives on the call rather than on a `CurvedAnimation`, and that is the whole
    // trick: `animateTo` interpolates *towards* the target, so an overshooting curve overshoots
    // in the direction of travel. As a `reverseCurve` the same curve would push the legend
    // deeper into the button instead of springing it out.
    if (isPressed) {
      _press.animateTo(1, duration: const Duration(milliseconds: 90), curve: Curves.easeOutCubic);
    } else {
      _press.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMotion = _hasMotion;
    final isDisabled = widget.onPressed == null;
    final canTap = !isDisabled && !widget.isLoading;

    final height = widget.height ?? 54.h;
    // A constant, and it stays a constant. The corner radius is the first thing an animation
    // reaches for and the first thing that makes a button change shape.
    final radius = BorderRadius.circular(16.r);
    final palette = _paletteFor(context.colorScheme, isDisabled: isDisabled);

    return Semantics(
      button: true,
      enabled: canTap,
      // While the legend is dimmed the button would otherwise announce itself as if idle.
      label: widget.isLoading ? '${widget.label} — جارٍ التنفيذ' : null,
      child: SizedBox(
        key: AppButton.surfaceKey,
        // As wide as it is allowed to be, unless the caller says otherwise. A `Column` hands
        // its children *loose* constraints, so a button that did not ask for the width shrank
        // to fit its label — which is why this is `double.infinity` and not simply nothing.
        width: widget.expands ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          // Static. A shadow is painted *outside* the shape, so animating it is animating the
          // button's apparent extent — exactly what must not happen here.
          decoration: BoxDecoration(borderRadius: radius, boxShadow: _shadow(palette)),
          child: Material(
            color: palette.fill,
            shape: RoundedRectangleBorder(borderRadius: radius, side: palette.side),
            clipBehavior: Clip.antiAlias,
            // Material's own 200ms lerp, kept on purpose: it is what fades the outlined border
            // down as the thread lights up, so there are never two bright edges at once.
            animationDuration: hasMotion ? const Duration(milliseconds: 200) : Duration.zero,
            child: InkWell(
              onTap: canTap ? widget.onPressed : null,
              onHighlightChanged: _onHighlightChanged,
              splashColor: palette.onFill.withValues(alpha: 0.12),
              highlightColor: palette.onFill.withValues(alpha: 0.06),
              // A splash is motion too. The highlight stays: a colour change is not motion.
              splashFactory: hasMotion ? null : NoSplash.splashFactory,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: _buildThread(palette, radius)),
                  // Not positioned, and the stack's fit is left loose: the legend is what the
                  // button measures itself against when nobody gave it a width.
                  _buildContent(palette, hasMotion),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The icon and the label — built once, then only ever re-coloured and moved.
  ///
  /// Neither carries a colour of its own; the colour arrives through [IconTheme] and
  /// [DefaultTextStyle]. A colour-only change to an inherited style is a repaint, never a
  /// re-layout, so the Arabic paragraph is not measured again sixty times a second.
  Widget _buildContent(_Palette palette, bool hasMotion) {
    return AnimatedBuilder(
      animation: Listenable.merge([_press, _reveal]),
      child: Padding(
        // The gutter, and it is structural rather than decorative: a button nobody gave a width
        // measures itself against this Row, so without it the shape is drawn on the writing —
        // the label touching both rims with nothing around it. Where a width *was* given the
        // legend is centred anyway and this changes nothing.
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20.sp),
              SizedBox(width: 8.w),
            ],
            // Flexible, because the label is the one part of this button whose width the app
            // does not control: a long Arabic string in a narrow box overflowed the Row and was
            // painted across the rim. It gives way to the gutter instead, and says so.
            Flexible(
              child: Text(widget.label, softWrap: false, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        final press = _press.value;
        final reveal = _revealCurve.value;

        // Clamped for the alpha only: the overshoot is allowed to move the legend past its
        // resting place, but "brighter than fully lit" is not a colour.
        final dim = (1 - 0.14 * press.clamp(0.0, 1.0)) * (1 - 0.45 * reveal);
        final color = palette.onFill.withValues(alpha: palette.onFill.a * dim);

        return Transform.translate(
          key: AppButton.contentKey,
          // Gated, not merely shortened: with motion off the press is absent, not quick.
          offset: Offset(0, hasMotion ? _sink.h * press : 0),
          child: IconTheme.merge(
            data: IconThemeData(color: color),
            child: DefaultTextStyle.merge(
              style: context.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
              child: child!,
            ),
          ),
        );
      },
    );
  }

  /// The running rim, or nothing at all.
  ///
  /// The subtree only exists while the button is busy, so an idle button pays for neither the
  /// painter nor the compositing layer. The [AnimatedBuilder] listens to [_reveal] alone, which
  /// is idle except during the 220ms fade — once the thread is up, the painter instance survives
  /// and keeps its measurement of the rim.
  Widget _buildThread(_Palette palette, BorderRadius radius) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        if (_revealCurve.value < 0.01) return const SizedBox.shrink();

        return RepaintBoundary(
          child: CustomPaint(
            key: AppButton.threadKey,
            painter: AppButtonThreadPainter(
              // Null is the accessibility setting, and the painter reads it as "draw the whole
              // rim and hold still" rather than freezing an arc somewhere along the edge, which
              // looks like a dropped frame rather than a state.
              lap: _hasMotion ? _lap : null,
              reveal: _revealCurve,
              // Follows the reading direction, so the thread never runs backwards in Arabic.
              clockwise: Directionality.of(context) == TextDirection.ltr,
              stroke: math.max(2.4.r, 2.5),
              radius: radius.topLeft.x,
              color: palette.onFill,
            ),
          ),
        );
      },
    );
  }

  /// Lifts the primary button off the page. One value, never animated.
  List<BoxShadow>? _shadow(_Palette palette) {
    final color = palette.shadow;
    if (color == null) return null;

    return [
      BoxShadow(
        color: color.withValues(alpha: 0.26),
        blurRadius: 16.r,
        offset: Offset(0, 8.h),
      ),
    ];
  }

  _Palette _paletteFor(ColorScheme scheme, {required bool isDisabled}) {
    final isOutlined = widget.variant == AppButtonVariant.outlined;

    if (isDisabled) {
      // One disabled look for all three variants: the Material 3 opacities. A disabled button
      // is not a quieter version of itself, it is a different thing.
      return (
        fill: isOutlined ? Colors.transparent : scheme.onSurface.withValues(alpha: 0.12),
        onFill: scheme.onSurface.withValues(alpha: 0.38),
        side: isOutlined
            ? BorderSide(color: scheme.onSurface.withValues(alpha: 0.12), width: 1.4)
            : BorderSide.none,
        shadow: null,
      );
    }

    return switch (widget.variant) {
      AppButtonVariant.primary => (
        fill: scheme.primary,
        onFill: scheme.onPrimary,
        side: BorderSide.none,
        // Only the primary is lifted. Give every button a shadow and none of them stands out.
        shadow: scheme.primary,
      ),
      AppButtonVariant.tonal => (
        fill: scheme.secondaryContainer,
        onFill: scheme.onSecondaryContainer,
        side: BorderSide.none,
        shadow: null,
      ),
      AppButtonVariant.outlined => (
        fill: Colors.transparent,
        onFill: scheme.primary,
        side: BorderSide(
          // Dimmed while busy so the running thread is the only bright edge, instead of a
          // second line sitting beside the resting border.
          color: widget.isLoading
              ? scheme.outlineVariant.withValues(alpha: 0.45)
              : scheme.outlineVariant,
          width: 1.4,
        ),
        shadow: null,
      ),
    };
  }
}

/// Draws a lit arc travelling around the inside of the button's own rim.
///
/// Every stroke lands inside the button's shape — the path is the button's rounded rectangle
/// deflated by half the stroke — so nothing this painter does can make the button look bigger.
///
/// The rim is measured once per size and cached. Measuring a path is not free, and an earlier
/// draft that rebuilt the painter from an `AnimatedBuilder` re-measured it on every frame. That
/// is why this takes [repaint] and is constructed outside the animation: **do not replace the
/// cache with a per-frame rebuild.**
@visibleForTesting
class AppButtonThreadPainter extends CustomPainter {
  AppButtonThreadPainter({
    required this.lap,
    required this.reveal,
    required this.clockwise,
    required this.stroke,
    required this.radius,
    required this.color,
  }) : super(repaint: Listenable.merge([lap, reveal]));

  /// Where the head of the arc is, 0 to 1 around the rim. `null` means the OS asked for no
  /// animation, and then the rim is drawn whole and still.
  final Animation<double>? lap;

  /// How present the thread is. Scales both its length and its opacity, so it grows out of a
  /// point and retracts into one.
  final Animation<double> reveal;

  final bool clockwise;
  final double stroke;
  final double radius;
  final Color color;

  /// The measured rim, and the path it belongs to. The path is held only to keep it alive for
  /// as long as the metric that reads it.
  Path? _path;
  PathMetric? _metric;
  Size? _measuredFor;

  /// How much of the rim the arc covers at full reveal.
  static const double _arcFraction = 0.28;

  @override
  void paint(Canvas canvas, Size size) {
    final presence = reveal.value;
    if (presence < 0.01 || size.isEmpty) return;

    final metric = _rim(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final clock = lap;
    if (clock == null) {
      canvas.drawPath(
        _path!,
        paint..color = color.withValues(alpha: color.a * 0.9 * presence),
      );

      return;
    }

    final length = metric.length;
    // Dart's `%` returns a non-negative result for a positive divisor, so the anticlockwise
    // case needs no special handling.
    final head = ((clockwise ? clock.value : -clock.value) * length) % length;
    final tail = head + _arcFraction * presence * length;

    final arc = Path()..addPath(metric.extractPath(head, math.min(tail, length)), Offset.zero);
    // Past the end of the rim the arc wraps to the start; without this it disappears at the seam.
    if (tail > length) arc.addPath(metric.extractPath(0, tail - length), Offset.zero);

    // One breath per lap, so a long wait does not read as a fixed loop.
    final breath = lerpDouble(0.75, 1, (math.sin(clock.value * 2 * math.pi) + 1) / 2)!;
    canvas.drawPath(
      arc,
      paint..color = color.withValues(alpha: color.a * 0.9 * presence * breath),
    );
  }

  PathMetric _rim(Size size) {
    if (_measuredFor == size && _metric != null) return _metric!;

    // Half the stroke plus a hair, so the line sits wholly inside Material's antialiased clip
    // and is not shaved along the outer edge.
    final inset = stroke / 2 + 0.5;
    final rect = Offset(inset, inset) &
        Size(size.width - inset * 2, size.height - inset * 2);
    final corner = math.max(
      0.0,
      math.min(radius - inset, math.min(rect.width, rect.height) / 2),
    );

    _path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(corner)));
    _metric = _path!.computeMetrics().first;
    _measuredFor = size;

    return _metric!;
  }

  @override
  bool shouldRepaint(covariant AppButtonThreadPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.clockwise != clockwise ||
      oldDelegate.stroke != stroke ||
      oldDelegate.radius != radius ||
      oldDelegate.lap != lap;
}
