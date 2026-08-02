import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// Where an order is, as one glance.
///
/// **The words come from the server and the colour from [OrderStatus.tone].** That split is why
/// a status this build has never seen still renders correctly: the label arrived with it, and
/// the tone falls back to neutral rather than the whole list failing to parse.
///
/// Colours are pulled from the scheme, never written as hex. The theme is generated and gets
/// replaced wholesale; a `Color(0xff…)` here survives that replacement and quietly stops
/// matching everything around it.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    required this.status,
    required this.label,
    this.compact = false,
    super.key,
  });

  final OrderStatus status;

  /// The server's Arabic — rendered as-is.
  final String label;

  /// The list card's size, as opposed to the header's.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = _colours(scheme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 12.w,
        vertical: compact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 8.r : 10.r),
      ),
      child: Text(
        label,
        style: (compact ? context.textTheme.labelSmall : context.textTheme.labelLarge)?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Nine tones out of the scheme's own roles.
  ///
  /// `error` is spent on the two that genuinely need to stop someone — a shortage and a return.
  /// A cancelled order is *finished*, not alarming, so it reads as muted rather than red: making
  /// every unhappy ending shout leaves nothing louder for the ones that need attention today.
  (Color, Color) _colours(ColorScheme scheme) => switch (status.tone) {
    OrderStatusTone.fresh => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    OrderStatusTone.working => (scheme.primaryContainer, scheme.onPrimaryContainer),
    OrderStatusTone.ready => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    OrderStatusTone.attention => (scheme.errorContainer, scheme.onErrorContainer),
    OrderStatusTone.moving => (scheme.primaryContainer, scheme.onPrimaryContainer),
    OrderStatusTone.done => (
      scheme.tertiary.withValues(alpha: 0.16),
      scheme.tertiary,
    ),
    OrderStatusTone.returned => (scheme.errorContainer, scheme.onErrorContainer),
    OrderStatusTone.cancelled || OrderStatusTone.neutral => (
      scheme.surfaceContainerHighest,
      scheme.onSurfaceVariant,
    ),
  };
}
