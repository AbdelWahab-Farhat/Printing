import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    this.banner = false,
    this.showIcon = false,
    super.key,
  });

  final OrderStatus status;

  /// The server's Arabic — rendered as-is.
  final String label;

  /// The list card's size, as opposed to the header's.
  final bool compact;

  /// Whether the status's own glyph leads the word.
  ///
  /// Off by default, because on a list of cards the chips stack up and a column of little
  /// glyphs is noise. On by the one chip standing alone — the order's header — where the shape
  /// is read before the word is, which is the whole reason [iconFor] exists. [banner] draws it
  /// too, and does not need this.
  final bool showIcon;

  /// A band across the whole top of a card rather than a chip in its corner.
  ///
  /// **The state is what the card is scanned for**, so on the orders list it is given the width
  /// it deserves — the reference card wears its state this way — and the label centres in it.
  /// Ignored where the chip shrink-wraps beside other things.
  final bool banner;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (background, foreground) = toneColour(scheme, status.tone);
    final text = (compact ? context.textTheme.labelSmall : context.textTheme.labelLarge)?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: banner ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.w : 12.w,
        vertical: banner
            ? 10.h
            : compact
            ? 4.h
            : 6.h,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          banner
              ? 12.r
              : compact
              ? 8.r
              : 10.r,
        ),
      ),
      child: banner
          // The glyph and the word, centred together — the state is the one thing this band is
          // for, and an icon pinned to the corner of a full-width strip reads as decoration.
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text,
                  ),
                ),
                SizedBox(width: 8.w),
                // At the end of the band, after the word — the side an Arabic line finishes on,
                // the way the reference card wears its own badge.
                Icon(iconFor(status), size: 20.sp, color: foreground),
              ],
            )
          : showIcon
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconFor(status), size: compact ? 14.sp : 17.sp, color: foreground),
                SizedBox(width: 6.w),
                Text(label, style: text),
              ],
            )
          : Text(label, style: text),
    );
  }

  /// A glyph per status, so a state is read before its word is.
  ///
  /// Public and static for the same reason [toneColour] is: the bar on the detail screen, the
  /// card in the list and the transition rows all draw from one legend rather than each
  /// inventing its own.
  ///
  /// **وواحدةٌ لكل حالة، لا عائلة لكل مجموعة.** جُمعت الحالات أول الأمر كما تُجمع الألوان —
  /// سهمٌ واحد للرواجع الثلاثة، وصحٌّ واحد لـ«جاهزة» و«تم الاستلام» — فكان الشكل يقول «من أي
  /// نوع هذه» ثم يترك القارئ يقرأ الكلمة ليعرف أيّها. اللون يقول النوع؛ والأيقونة تقول الحالة
  /// بعينها، وإلا فلا داعي لها.
  static IconData iconFor(OrderStatus status) => switch (status) {
    OrderStatus.taken => AppIcons.statusNew,
    // **The warehouse's glyph, not the press's.** The goods have been found, counted and
    // weighed, and the shelf has dropped; drawing it with a printer would put the order at a
    // machine nobody has started yet.
    OrderStatus.readyToPrint => AppIcons.warehouse,
    OrderStatus.designing => AppIcons.designs,
    // The press itself, where «قيد الطباعة» actually is — not the bag it will become.
    OrderStatus.printing => AppIcons.printedProduct,
    // Done in the workshop: an outlined tick. Its pair is `delivered`'s filled one — finished
    // *here* against finished *there*.
    OrderStatus.ready => AppIcons.activate,
    OrderStatus.shortage => AppIcons.error,
    OrderStatus.officePickup => AppIcons.officePickup,
    OrderStatus.outForDelivery => AppIcons.outForDelivery,
    OrderStatus.delivered => AppIcons.ordersReceived,
    OrderStatus.settled => AppIcons.settled,
    // Three returns, three glyphs: on the road, at the carrier, back on our counter. The word
    // that tells them apart is the longest on the card, and the one nobody reads twice.
    OrderStatus.returnedCourier => AppIcons.returnedCourier,
    OrderStatus.returnedCarrier => AppIcons.returnedCarrier,
    OrderStatus.returnedOffice => AppIcons.returnedOffice,
    OrderStatus.resend => AppIcons.resend,
    // Struck out, not paused: nothing is coming back to life here.
    OrderStatus.cancelled => AppIcons.ordersCancelled,
    // Nothing is claimed about a status this build has never heard of. The label arrived with
    // it and says what it is.
    OrderStatus.unknown => AppIcons.unknownStatus,
  };

  /// The same tone, washed down for a row that *names* a status rather than being in it.
  ///
  /// صفحة «تغيير الحالة» تعرض الوجهات كلها في قائمة واحدة، وكانت كلها رمادية حتى تُختار — أي
  /// أن اللون الذي يعرفه الموظف من البطاقة ومن الشريط يختفي في المكان الوحيد الذي يقرّر فيه.
  /// الغسل يبقي الهوية ويترك الملء الكامل علامةً للمختار وحده.
  static Color tintFor(ColorScheme scheme, OrderStatusTone tone) => Color.alphaBlend(
    toneColour(scheme, tone).$1.withValues(alpha: 0.3),
    scheme.surfaceContainerLowest,
  );

  /// Nine tones out of the scheme's own roles.
  ///
  /// Public and static so the status filter's dots read from the same table: a legend the list
  /// and the filter each derived separately is a legend that drifts.
  ///
  /// `error` is spent on the two that genuinely need to stop someone — a shortage and a return.
  /// A cancelled order is *finished*, not alarming, so it reads as muted rather than red: making
  /// every unhappy ending shout leaves nothing louder for the ones that need attention today.
  static (Color, Color) toneColour(ColorScheme scheme, OrderStatusTone tone) => switch (tone) {
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
