import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The design's card, in one place.
///
/// **The app inherited two card idioms and only one of them is this app's.** The staff app draws
/// `surfaceContainerHighest` at radius 14 with no border; the design draws `#16304A` at radius
/// 20 with a `#24425F` hairline. Six screens were ported wholesale and kept the first, so
/// «طلباتي» and «تصاميمي» sat a shade lighter and a corner sharper than the home screen next to
/// them — a difference nobody can name but everybody sees.
///
/// `cardTheme` in `theme.dart` already carries the right shape. This widget exists because the
/// screens do not use `Card`: they need a tap target, and a `Card` wrapping an `InkWell` clips
/// the ripple at the wrong radius. So the shape is read back off the theme rather than written
/// again here — change `cardTheme` and every card in the app follows.
///
/// Three tones, and each is a thing the design does rather than a palette entry:
///
/// * [AppCard] — the ordinary card.
/// * [AppCard.accent] — the orange hairline the design puts on the one row that wants you:
///   the order awaiting your design, the ticket with an unread reply, the print you picked.
/// * [AppCard.sunken] — `#132A43` on a `#2A4A6B` border, which the design uses for the things
///   that are *told* rather than *done*: the brand card, the support hours, «ارفع شعارك مرة
///   واحدة». One step back from the surface, not one step forward.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    super.key,
  }) : _tone = _CardTone.plain;

  const AppCard.accent({
    required this.child,
    this.padding,
    this.onTap,
    super.key,
  }) : _tone = _CardTone.accent;

  const AppCard.sunken({
    required this.child,
    this.padding,
    this.onTap,
    super.key,
  }) : _tone = _CardTone.sunken;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final _CardTone _tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // **Read off `cardTheme`, not written here.** The radius is a decision `theme.dart` already
    // made; a second copy of `20.r` in this file is a second thing to remember when it moves.
    final shape = Theme.of(context).cardTheme.shape;
    final radius = shape is RoundedRectangleBorder
        ? shape.borderRadius
        : BorderRadius.circular(20.r);

    final (background, border) = switch (_tone) {
      _CardTone.plain => (scheme.surfaceContainer, scheme.outlineVariant),
      _CardTone.accent => (scheme.surfaceContainer, scheme.primary),
      _CardTone.sunken => (scheme.surfaceContainerLow, scheme.outline.withValues(alpha: 0.45)),
    };

    final body = Padding(
      padding: padding ?? EdgeInsets.all(14.w),
      child: child,
    );

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      // A card with nothing to tap gets no `InkWell` at all, rather than one with a null
      // callback: an ink response that never responds still eats the gesture.
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

enum _CardTone { plain, accent, sunken }
