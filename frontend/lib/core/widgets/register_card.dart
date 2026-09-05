import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which register a row belongs to, as a colour.
///
/// **Material ships exactly three accents and this app now has exactly three registers**, so the
/// mapping is the obvious one and no new colour is invented. It is the only thing that differs
/// between the three cards: swiping between the tabs of «الجهات» should feel like the same list
/// answering a different question, not like three apps.
///
/// [muted] is not a fourth register — it is any of the three switched off, and it is grey for
/// the same reason the code goes grey on a stopped customer.
enum RegisterTone { customers, vendors, investors, muted }

/// One labelled fact in the band beneath the name.
@immutable
class RegisterField {
  const RegisterField({required this.label, required this.value, this.valueDirection});

  final String label;
  final String value;

  /// Forced to [TextDirection.ltr] for anything Latin — a phone number reads backwards inside
  /// this right-to-left card without it.
  final TextDirection? valueDirection;
}

/// One person in one of the three registers: a customer, a supplier, or an investor.
///
/// **One shape for all three, differing only in what it says and what colour it says it in.**
/// The three lists sit under one tab now, a swipe apart, and three different card designs read
/// as three different apps — the eye has to relearn where the name is on every swipe. This is
/// the shape the customers list already used and the business already reads a person in:
///
///   * **one line along the top saying *who*** — a tinted glyph, the name, and the code the row
///     is quoted by at the far left, so a column of codes runs down one edge to trace a finger
///     along. Being the last child of an RTL row is what puts it there, not an alignment, so it
///     cannot drift when the name grows,
///   * **beneath it a wide, quiet band of labelled fields** saying what you do about them. A
///     label over its value rather than a glyph beside it: an icon makes the reader learn what
///     it stands for, a heading does not.
///
/// Nothing is packed against anything else — the air is the layout, not decoration on top of it,
/// which is why the vertical gaps are large enough to look like mistakes and are not.
class RegisterCard extends StatelessWidget {
  const RegisterCard({
    required this.title,
    required this.code,
    required this.icon,
    required this.fields,
    super.key,
    this.tone = RegisterTone.customers,
    this.badge,
    this.onTap,
  });

  /// The name — what the row is found by, and the widest thing on it.
  final String title;

  /// «C8», «V3», «I7» — what the row is *quoted* by.
  final String code;

  final IconData icon;

  /// Two, side by side. Two is the shape rather than a limit somebody forgot to enforce: three
  /// columns on a phone leaves each one too narrow for «0912345678».
  final List<RegisterField> fields;

  final RegisterTone tone;

  /// «موقوف», «متوقف» — only when it is *not* the normal case. A badge on every row stops being
  /// read.
  final String? badge;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          // Deep at the bottom, shallow at the top: the strip is the card's own lid and sits
          // close under the edge, while the fields are given the room they need.
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 60.h),
          decoration: BoxDecoration(
            // Painted *here* rather than left to the Material below. A `BoxShadow` is drawn as
            // the whole rounded rectangle filled and blurred, so with no colour on this
            // decoration the shadow washes straight across the card's face and turns it grey.
            // `BoxDecoration` paints shadows first and the colour over them, which puts the
            // shadow back outside the edge where it belongs.
            color: scheme.surfaceContainerLowest,
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _IdentityStrip(
                title: title,
                code: code,
                icon: icon,
                tone: tone,
                badge: badge,
              ),
              SizedBox(height: 52.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in fields) Expanded(child: _Field(field: field)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The accent this register is drawn in, and the pale fill behind its glyph.
///
/// Straight out of `ColorScheme` — never a hex at the call site, because `theme.dart` is
/// generated and gets replaced wholesale.
({Color ink, Color fill}) _colours(ColorScheme scheme, RegisterTone tone) => switch (tone) {
  RegisterTone.customers => (ink: scheme.primary, fill: scheme.primaryContainer),
  RegisterTone.vendors => (ink: scheme.tertiary, fill: scheme.tertiaryContainer),
  RegisterTone.investors => (ink: scheme.secondary, fill: scheme.secondaryContainer),
  RegisterTone.muted => (ink: scheme.outline, fill: scheme.surfaceContainerHighest),
};

/// Who this row is about: the glyph, the name, and the code it is quoted by.
class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    required this.title,
    required this.code,
    required this.icon,
    required this.tone,
    this.badge,
  });

  final String title;
  final String code;
  final IconData icon;
  final RegisterTone tone;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final colours = _colours(scheme, tone);

    return Row(
      children: [
        // A tinted tile rather than a bare glyph: it is the one place the register's colour is
        // said, and on a list scrolled quickly it is what tells a supplier from a customer
        // before either name is read.
        Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: colours.fill,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: colours.ink),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Full-strength ink: the name is what the row is found by, and muted it reads as
            // switched off.
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (badge case final badge?) ...[SizedBox(width: 8.w), _Badge(label: badge)],
        SizedBox(width: 10.w),
        Text(
          '#',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.outline,
          ),
        ),
        SizedBox(width: 6.w),
        _Code(code: code, tone: tone),
      ],
    );
  }
}

/// The row's code — `C8`, `V12`, `I7` — at the far left of the strip.
class _Code extends StatelessWidget {
  const _Code({required this.code, required this.tone});

  final String code;
  final RegisterTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ConstrainedBox(
      // Codes are a letter plus the row id, so they grow: C9 today, C1284 in two years. Capped
      // and scaled down to fit rather than clipped — half a code is worse than a small one,
      // because «C12…» and «C128…» read as the same person. The cap is what stops a long one
      // from eating the name beside it.
      constraints: BoxConstraints(maxWidth: 110.w),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code,
          // A Latin letter and digits: they read left-to-right even inside this RTL card.
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            // The code keeps saying whether the row is switched off, which is the one thing
            // worth carrying from the old tinted square.
            color: tone == RegisterTone.muted ? scheme.outline : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A heading with its value under it, centred in its half of the row.
///
/// Centred because the pair is read as one block against the identical block beside it, and two
/// centred blocks are what makes the card's lower half look deliberate rather than left over.
class _Field extends StatelessWidget {
  const _Field({required this.field});

  final RegisterField field;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          field.value,
          textAlign: TextAlign.center,
          textDirection: field.valueDirection,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: context.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
