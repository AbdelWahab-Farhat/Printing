import 'dart:math' as math;

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who the order is for, where it is, where it is going, and the two records kept beside it —
/// as the screen's own header rather than as the first three cards of its list.
///
/// **A sliver, so it is the screen's own top and not an item in it.** The four facts here are
/// the ones every visit to this screen begins with: which order this is, whose it is, what state
/// it is in and where it goes. They were four separate cards, each with its own white plate and
/// its own margins, and the reader scrolled past them to reach the invoice. Pinned to the bar,
/// they cost the list nothing and the order's number stays legible all the way down.
///
/// **The gradient stays inside one colour role, and that is load-bearing rather than
/// decorative.** Every foreground on it — the title, the arrow, the name, the address, both
/// buttons — is `onPrimary`, which is only guaranteed to be readable against `primary`. A
/// gradient that crossed into `primaryContainer` would need a second foreground and the middle
/// of the run would be wrong for both.
///
/// **The status keeps the legend it wears everywhere else.** Same [OrderStatusChip] the list
/// card and the transition rows draw, on a plate of the app's own surface: two of the nine tones
/// are a wash rather than a solid fill, and a wash laid straight onto teal is not the colour it
/// was mixed to be.
///
/// It carries no doors of its own beyond the two buttons: the customer's file is opened from the
/// card below, which is also where their phone number is.
class OrderDetailHeader extends StatelessWidget {
  const OrderDetailHeader({
    required this.order,
    this.onOpenNotes,
    this.onOpenLog,
    this.onSendToCarrier,
    this.onResendShipment,
    this.onDeleteShipment,
    this.onUnlinkShipment,
    super.key,
  });

  /// Let tests reach the buttons without matching on Arabic that may be reworded.
  static const Key notesKey = Key('order-header-notes');
  static const Key logKey = Key('order-header-log');
  static const Key overflowKey = Key('order-header-overflow');
  static const Key sendToCarrierKey = Key('order-header-send-to-carrier');
  static const Key resendShipmentKey = Key('order-header-resend-shipment');
  static const Key deleteShipmentKey = Key('order-header-delete-shipment');
  static const Key unlinkShipmentKey = Key('order-header-unlink-shipment');

  final Order order;

  /// Null on an order nobody wrote anything on — an empty sheet is a wasted tap, and this app
  /// leaves such a button out rather than greying it.
  final VoidCallback? onOpenNotes;

  /// Null without `logs.view`, for the reason the customer card's chevron is: an affordance
  /// promising a screen that would answer 403 is worse than no affordance.
  final VoidCallback? onOpenLog;

  /// «إرسال للنورس» — null unless this particular order can actually go.
  ///
  /// **In the overflow rather than on the dial, and that is the request rather than the
  /// convention.** The dial is where this screen's acts live; a hand-over to the carrier is one,
  /// and it would sit there naturally. It is here because it was asked for here, and moving it is
  /// deleting this menu and adding one `AppAction`.
  ///
  /// **Null-to-hide, exactly as the two buttons above are**: the three conditions behind it —
  /// «جاهزة», a delivery rather than «استلام مكتب», and `carrier.manage` — are answered on the
  /// screen, and an order failing any of them gets no menu at all rather than a greyed line.
  final VoidCallback? onSendToCarrier;

  /// «إعادة الإرسال» — asks the carrier to try delivering the same parcel again.
  ///
  /// **Offered on a returned order, never on «جاهزة».** The two are opposite moments: sending is
  /// for goods that have not left, re-sending is for goods that came back — and the carrier can
  /// only repeat a journey whose parcel is still open at their end.
  final VoidCallback? onResendShipment;

  /// «حذف الشحنة من النورس» — deletes it at their end and frees the order.
  final VoidCallback? onDeleteShipment;

  /// «فكّ الربط» — for a parcel somebody deleted in *their* portal.
  ///
  /// **Offered beside the delete rather than instead of it**, because the app cannot tell the two
  /// situations apart: nothing in the order payload says whether a parcel still exists at Nawris,
  /// and the only way to find out is to ask them. The server answers either honestly — «لا توجد
  /// شحنة مفتوحة» when there is nothing to let go of.
  final VoidCallback? onUnlinkShipment;

  /// How tall the bar has to be to hold what is in it.
  ///
  /// **Measured off the text rather than fixed**, because every row here is a row of text: a
  /// phone set to large type gets a taller header instead of a button with its label clipped
  /// off, and a fixed `expandedHeight` is the one thing that cannot do that.
  ///
  /// The status bar is not counted — `SliverAppBar` adds the top inset to whatever this says.
  double _extent(BuildContext context) {
    final text = MediaQuery.textScalerOf(context);
    // The glyphs are sized in `.sp`, which follows the *screen*, while the words follow the
    // reader's own text setting. Either one can be the taller of a row, so both are asked.
    final glyph = 18.sp;

    // The customer and their state, the line saying where it goes, and the bar of sections.
    // Each is as tall as the tallest thing standing in it, and in two of the three that is a
    // glyph rather than a word — the chip's status mark and the sections' own.
    final chip = math.max(text.scale(20), 17.sp) + 12.h;
    final customer = math.max(math.max(text.scale(24), glyph), chip);
    final address = text.scale(20);
    // One more line of the same height, only on an order a vendor is making.
    final vendor = order.vendorName == null ? 0.0 : text.scale(20) + 4.h;
    final records = math.max(text.scale(22), glyph) + 22.h;

    return kToolbarHeight + 8.h + customer + 10.h + address + vendor + 12.h + records + 14.h;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SliverAppBar(
      pinned: true,
      // Deliberately not `floating`: the number of the order being read should not appear and
      // disappear with the direction of a thumb.
      expandedHeight: _extent(context),
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      // The bar paints its own ground; Material's scroll-under tint would lay a second, paler
      // teal over the top of the gradient as the list moves beneath it.
      surfaceTintColor: Colors.transparent,
      title: Text(
        'طلبية #${order.code}',
        style: context.textTheme.titleLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        _CarrierMenu(
          onSend: onSendToCarrier,
          onResend: onResendShipment,
          onDelete: onDeleteShipment,
          onUnlink: onUnlinkShipment,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // `background` rather than `title`, because this is a block of facts and not a heading:
        // it fades out as the bar collapses, leaving the order's number behind it.
        background: _Header(order: order, onOpenNotes: onOpenNotes, onOpenLog: onOpenLog),
      ),
    );
  }
}

/// The carrier's own actions, behind the three dots.
///
/// **Behind a menu rather than on the dial, and that is the request rather than the convention.**
/// The dial is where this screen's acts live and a hand-over would sit there naturally; these are
/// here because they were asked for here. Moving them is deleting this widget and adding three
/// `AppAction`s.
///
/// **Absent when it would open onto nothing.** A menu button with no items is a door into a wall,
/// so the button itself is only drawn once something is passed to it — the same null-to-hide rule
/// the note and log segments follow.
///
/// **Opened under the button, not over the title.** The default anchors the sheet at the tap and
/// it lands across «طلبية #200», which reads as a rendering fault rather than a menu.
class _CarrierMenu extends StatelessWidget {
  const _CarrierMenu({this.onSend, this.onResend, this.onDelete, this.onUnlink});

  final VoidCallback? onSend;
  final VoidCallback? onResend;
  final VoidCallback? onDelete;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final items = <PopupMenuEntry<void>>[
      if (onSend case final send?)
        _item(
          context,
          key: OrderDetailHeader.sendToCarrierKey,
          icon: AppIcons.outForDelivery,
          label: 'إرسال للنورس',
          onTap: send,
        ),

      if (onResend case final again?)
        _item(
          context,
          key: OrderDetailHeader.resendShipmentKey,
          icon: AppIcons.resend,
          label: 'إعادة الإرسال',
          onTap: again,
        ),

      // A rule between putting goods on the road and the two ways of taking a hand-over back: the
      // lines above make a journey happen and the lines below undo one, and a reader should not
      // have to parse four labels to see that.
      if ((onSend != null || onResend != null) && (onDelete != null || onUnlink != null))
        const PopupMenuDivider(),

      if (onDelete case final remove?)
        _item(
          context,
          key: OrderDetailHeader.deleteShipmentKey,
          icon: AppIcons.delete,
          label: 'حذف الشحنة من النورس',
          onTap: remove,
          // The one here that reaches out and destroys something at their end.
          tone: scheme.error,
        ),
      if (onUnlink case final unlink?)
        _item(
          context,
          key: OrderDetailHeader.unlinkShipmentKey,
          icon: AppIcons.unlink,
          label: 'فكّ الربط',
          onTap: unlink,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<void>(
      key: OrderDetailHeader.overflowKey,
      tooltip: 'إجراءات الشحن',
      // The bar paints its own teal and every foreground on it is `onPrimary` — see the class
      // comment on [OrderDetailHeader] for why that is load-bearing rather than a choice.
      iconColor: scheme.onPrimary,
      // Under the button, so the sheet never lands on the order's number.
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerLowest,
      // The app's own corner, not Material's 4dp — every plate on this screen is rounder.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (context) => items,
    );
  }

  PopupMenuItem<void> _item(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? tone,
  }) {
    final colour = tone ?? context.colorScheme.onSurface;

    return PopupMenuItem<void>(
      key: key,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 19.sp, color: colour),
          SizedBox(width: 12.w),
          // **`Flexible`, and it is not cosmetic**: the menu is given a maximum width, and
          // «حذف الشحنة من النورس» is wider than it. A bare `Text` overflowed the row by 82
          // pixels — the sheet still sizes itself to the longest label that fits.
          Flexible(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.onOpenNotes, required this.onOpenLog});

  final Order order;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenLog;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Directional, so the light corner is the one an Arabic reader starts at.
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(scheme.onPrimary.withValues(alpha: 0.18), scheme.primary),
            scheme.primary,
          ],
        ),
      ),
      child: Padding(
        // The status bar and the toolbar are both above this: the bar draws its title in that
        // space, and content pushed up into it would sit under the back arrow.
        padding: EdgeInsetsDirectional.fromSTEB(
          16.w,
          MediaQuery.paddingOf(context).top + kToolbarHeight + 8.h,
          16.w,
          14.h,
        ),
        child: Column(
          // Bottom-aligned, so what slack there is falls under the title rather than between
          // the lines — and the buttons stay where the thumb learned to find them.
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Customer(order: order),
            SizedBox(height: 10.h),
            _Address(order: order),
            // Who is making it — only on an order somebody else makes. The fourth fact a visit
            // to a وسيط order begins with, and absent rather than «—» on every other.
            if (order.vendorName case final vendor?) ...[
              SizedBox(height: 4.h),
              _Vendor(name: vendor),
            ],
            SizedBox(height: 12.h),
            _Records(
              onOpenNotes: onOpenNotes,
              onOpenLog: onOpenLog,
            ),
          ],
        ),
      ),
    );
  }
}

/// Whose order this is, and what state it is in — one line, because they are read together.
class _Customer extends StatelessWidget {
  const _Customer({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = order.customer;
    // The code leads for the reason it leads on every customer row in this app: it is the short,
    // unique thing one colleague says to another over the counter.
    final name = [
      ?customer?.code,
      customer?.name ?? 'عميل #${order.customerId}',
    ].join(' — ');

    return Row(
      children: [
        Icon(AppIcons.person, size: 18.sp, color: scheme.onPrimary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // The plate is the point — see the class comment. Clipped to the chip's own radius so
        // the two corners agree.
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10.r),
          ),
          // The glyph leads the word here and nowhere else on this screen — see
          // `OrderStatusChip.showIcon` for why a list of cards does not want it.
          child: OrderStatusChip(
            status: order.status,
            label: order.statusLabel,
            showIcon: true,
          ),
        ),
      ],
    );
  }
}

/// Where the goods are going, as the one line the reference screen puts here.
///
/// The rest — the branch, the street, who signs for it, the carrier — stays in its section
/// below. This is the line somebody checks before they pick the phone up.
class _Address extends StatelessWidget {
  const _Address({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Text(
      // **One word, the same one the section below is titled with.** «عنوان استلام مكتب:
      // إستلام مكتب (قرجي)» said the arrangement twice and the place once — and the second
      // «استلام» was the *city's own name*, which no line here can shorten. The label is the
      // question («where is it collected from», «where is it delivered to») and the value is
      // the answer.
      '${order.isOfficePickup ? 'الاستلام' : 'التوصيل'}: ${order.destination}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(
        // Quieter than the name above it without leaving the one readable foreground this
        // ground has.
        color: scheme.onPrimary.withValues(alpha: 0.85),
      ),
    );
  }
}

/// Who is making the goods, for an order a vendor executes.
///
/// **The order's own snapshot, never a lookup.** `vendor_name` is what this order said on the
/// day; a vendor renamed since keeps the new name everywhere except here, which is the whole
/// reason the column exists. Drawn the way the address above it is — a label that is the
/// question and a value that is the answer.
class _Vendor extends StatelessWidget {
  const _Vendor({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Text(
      'المورد: $name',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(
        color: scheme.onPrimary.withValues(alpha: 0.85),
      ),
    );
  }
}

/// The two records kept beside an order: what was written on it, and what was done to it.
///
/// **Here rather than on the dial.** The dial acts — it moves the order, edits it, takes money.
/// These two only ever open something to read, and reading is what the top of a screen is for.
///
/// **One bar cut into sections, not two buttons standing apart.** Outlined pills each drew their
/// own border on a coloured ground, so the header ended in a row of empty boxes competing with
/// the card edges below it. A single soft plate divided by a hairline reads as one control with
/// two doors — and it stays one control when only one door is open.
class _Records extends StatelessWidget {
  const _Records({required this.onOpenNotes, required this.onOpenLog});

  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenLog;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final segments = <Widget>[
      if (onOpenLog case final open?)
        _Segment(
          key: OrderDetailHeader.logKey,
          label: 'السجل',
          icon: AppIcons.history,
          onTap: open,
        ),
      if (onOpenNotes case final open?)
        _Segment(
          key: OrderDetailHeader.notesKey,
          label: 'الملاحظات',
          icon: AppIcons.notes,
          onTap: open,
        ),
    ];

    if (segments.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        // A wash of the one foreground this ground has, so the plate belongs to the header
        // rather than sitting on it — and it is legible in either brightness for the same
        // reason every other colour up here is.
        color: scheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.r),
      ),
      // The ink of a tapped section has to stop at the plate's corners.
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final (index, segment) in segments.indexed) ...[
            if (index > 0)
              // A hairline, not a gap: a gap would make two plates out of one.
              Container(width: 1, height: 22.h, color: scheme.onPrimary.withValues(alpha: 0.22)),
            // Halves rather than shrink-wrapped labels: two sections of different widths read as
            // a heading and an afterthought, and one alone still spans the header.
            Expanded(child: segment),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.icon, required this.onTap, super.key});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // Not `AppButton`, and no longer an `OutlinedButton`: this is a section of a plate, and both
    // of those bring a shape and a colour of their own to a ground that already has one.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: scheme.onPrimary),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
