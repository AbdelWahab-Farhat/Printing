import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One figure about an investor's money, with the sentence that says what it means.
///
/// **One tile, both screens.** The investor's own screen and the staff screen behind it show the
/// same four pots, and two tiles drawn from two files is how the two come to disagree about what
/// «رصيد المحفظة» looks like — or, worse, about what it means.
///
/// The number is the biggest thing on it and carries its unit, because an amount without «د.ل»
/// beside it is a figure somebody has to guess at. It is drawn on the same card the rest of the
/// app uses — surface, rounded, outlined — except for the two louder forms:
///
///   * [emphasis] marks one of the figures the screen was opened for, on the pale primary fill,
///   * [InvestorMoneyTile.hero] is the single figure a screen is *about* — the teal card with the
///     artwork on it, which is the first thing read on the investor's screen.
///
/// An [icon] rides at the trailing edge of a plain tile, so a column of figures is scanned by
/// shape before any of the labels are read.
class InvestorMoneyTile extends StatelessWidget {
  const InvestorMoneyTile({
    required this.label,
    required this.amount,
    super.key,
    this.caption,
    this.emphasis = false,
    this.icon,
  }) : artwork = null;

  /// The one figure the screen exists to show: teal, gradient, with [artwork] on it.
  ///
  /// One per screen — a second card this loud makes neither of them the answer.
  const InvestorMoneyTile.hero({
    required this.label,
    required this.amount,
    required String this.artwork,
    super.key,
    this.caption,
  }) : emphasis = true,
       icon = null;

  final String label;

  /// A decimal string exactly as the server sent it — `'43500.00'`.
  final String amount;

  final String? caption;

  /// Whether this is one of the figures the screen is opened for.
  final bool emphasis;

  /// Drawn in a pale disc at the trailing edge. Plain tiles only.
  final IconData? icon;

  /// The asset painted on the hero card — `'assets/images/wallet.png'`.
  final String? artwork;

  @override
  Widget build(BuildContext context) {
    if (artwork case final artwork?) return _Hero(tile: this, artwork: artwork);

    final scheme = context.colorScheme;

    final onSurface = emphasis ? scheme.onPrimaryContainer : scheme.onSurface;
    final muted = emphasis ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: emphasis ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: emphasis
              ? scheme.primary.withValues(alpha: 0.25)
              : scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        // The same shadow every card in the app is lifted by — see `RegisterCard`, which paints
        // it under the fill rather than behind the whole rounded rectangle.
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              label: label,
              amount: amount,
              caption: caption,
              ink: onSurface,
              muted: muted,
            ),
          ),
          if (icon case final icon?) ...[
            SizedBox(width: 12.w),
            Container(
              height: 44.w,
              width: 44.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondaryContainer,
              ),
              child: Icon(icon, size: 20.sp, color: scheme.onSecondaryContainer),
            ),
          ],
        ],
      ),
    );
  }
}

/// The label, the number, and the sentence under it — the tile's whole content, whichever card
/// it is being drawn on.
class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amount,
    required this.ink,
    required this.muted,
    this.caption,
    this.big = false,
  });

  final String label;
  final String amount;
  final String? caption;
  final Color ink;
  final Color muted;

  /// Whether this is the hero's number, which is a size louder than the rest.
  final bool big;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount.startsWith('-');
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.textTheme.bodyMedium?.copyWith(color: muted)),
        SizedBox(height: 4.h),
        // Forced left-to-right inside the right-to-left tree: `43,500` laid out right-to-left
        // lands its separator on the wrong side of the digits, which is a different number
        // rather than a rendering glitch.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${amount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              maxLines: 1,
              style: (big ? context.textTheme.headlineMedium : context.textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    // A loss is red on a plain card; on the hero's teal there is no red that
                    // stays readable, so the sign in front of the number carries it.
                    color: isNegative && !big ? scheme.error : ink,
                  ),
            ),
          ),
        ),
        if (caption != null) ...[
          SizedBox(height: 4.h),
          Text(caption!, style: context.textTheme.bodyMedium?.copyWith(color: muted)),
        ],
      ],
    );
  }
}

/// The teal card: the figure a screen is about, with the artwork behind the numbers.
///
/// Built the way [EmployeeCard] is, and for the same two reasons: the shadow is on a decoration
/// *outside* the clip, because a shadow inside one is never drawn; and the gradient runs from a
/// lightened `primary` at the start corner to `primary` itself, so it is one hue in both
/// brightnesses instead of a light-theme teal that turns muddy in the dark one.
class _Hero extends StatelessWidget {
  const _Hero({required this.tile, required this.artwork});

  final InvestorMoneyTile tile;
  final String artwork;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final corner = BorderRadius.circular(24.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corner,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                Color.lerp(scheme.primary, scheme.onPrimary, 0.16)!,
                scheme.primary,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Figure(
                  label: tile.label,
                  amount: tile.amount,
                  caption: tile.caption,
                  ink: scheme.onPrimary,
                  muted: scheme.onPrimary.withValues(alpha: 0.85),
                  big: true,
                ),
              ),
              SizedBox(width: 12.w),
              // Excluded from semantics: it is the card's picture of itself, and «محفظة» read
              // out before «رصيد المحفظة» is the same word twice.
              ExcludeSemantics(
                child: Image.asset(artwork, height: 84.w, width: 84.w),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
