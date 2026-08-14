import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which of the theme's container pairs a tile or a pill is painted in.
///
/// A name per *meaning*, not per colour: the screen says "this row is a branch", and which pair
/// answers is settled here — so restyling the delivery map is one file, and no screen holds a
/// `Color(0xff…)` that the next palette leaves behind.
enum PlaceTone {
  /// Somewhere we drive to. The map's default, and the accent the eye should learn.
  delivery,

  /// A counter with our name over it, that the customer walks into.
  pickup,

  /// Costs nothing. Distinct from [delivery] on purpose: "مجاني" and "15.00 د.ل" are answers to
  /// the same question, and painting them alike hides the one that is worth noticing.
  free,

  /// A fact with no weight — a zone code, or a price nobody has agreed yet.
  muted;

  Color background(ColorScheme scheme) => switch (this) {
    PlaceTone.delivery => scheme.primaryContainer,
    PlaceTone.pickup => scheme.tertiaryContainer,
    PlaceTone.free => scheme.secondaryContainer,
    PlaceTone.muted => scheme.surfaceContainerHigh,
  };

  Color foreground(ColorScheme scheme) => switch (this) {
    PlaceTone.delivery => scheme.onPrimaryContainer,
    PlaceTone.pickup => scheme.onTertiaryContainer,
    PlaceTone.free => scheme.onSecondaryContainer,
    PlaceTone.muted => scheme.onSurfaceVariant,
  };
}

/// One row of the delivery map: a tinted glyph, a name, a line about it, and a pill.
///
/// The shape comes from design **2b** — a tinted square at the reading edge, the name and its
/// detail stacked beside it, and the answer the row exists to give held in a pill at the far
/// end, always at the same height. That last part is the whole point: the eye runs down the
/// pills alone and reads eleven prices without reading eleven names.
///
/// **What the design had and this does not:** the two counting tabs above the list
/// (`مكاتب الاستلام · ٢` / `مدن التوصيل · ٧`). They filtered a list of nine rows, which is a
/// control that costs a tap to save a scroll. The tinted glyph already separates the two kinds
/// at a glance, so the distinction survived and the chrome around it did not.
///
/// **What it has and the design did not:** a chevron, and only when [onTap] is given. In 2b the
/// row was a choice and the trailing mark was a tick; here it opens a screen, and a row that
/// leads somewhere has to say so before it is tapped.
///
/// Used for both a city and a region, because they are the same row twice — a name, a
/// qualifier, and one short fact — and drawing them from one widget is what keeps them aligned
/// when either changes.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    required this.title,
    required this.icon,
    required this.iconTone,
    this.subtitle,
    this.badge,
    this.badgeTone = PlaceTone.muted,
    this.onTap,
    super.key,
  });

  final String title;

  /// The line under the name. Omitted rather than blank when there is nothing to say.
  final String? subtitle;

  final IconData icon;
  final PlaceTone iconTone;

  /// The pill at the far end — a price, or a zone code. Omitted when the row has neither.
  final String? badge;
  final PlaceTone badgeTone;

  /// Given only when this row leads somewhere.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(16.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            // The design left this transparent and leaned on a mint page behind white cards.
            // Our surfaces sit closer together than that, so the edge is drawn rather than
            // implied — same 1.5, so the card's geometry is unchanged.
            border: Border.all(
              width: 1.5,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              _IconTile(icon: icon, tone: iconTone),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                SizedBox(width: 8.w),
                _Badge(label: badge!, tone: badgeTone),
              ],
              if (onTap != null) ...[
                SizedBox(width: 4.w),
                Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The tinted square that says what kind of place this is before the name is read.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.tone});

  final IconData icon;
  final PlaceTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final side = 36.w;

    return Container(
      height: side,
      width: side,
      decoration: BoxDecoration(
        color: tone.background(scheme),
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Icon(icon, size: 18.sp, color: tone.foreground(scheme)),
    );
  }
}

/// The one short fact, at the far end of every row and at the same height on all of them.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final PlaceTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: tone.background(scheme),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        label,
        // A price and a zone code are Latin runs inside an Arabic layout. Left to inherit, the
        // currency after "15.00" lands on the wrong side of the number.
        textDirection: TextDirection.rtl,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: tone.foreground(scheme),
        ),
      ),
    );
  }
}
