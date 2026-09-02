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
  const OrderDetailHeader({required this.order, this.onOpenNotes, this.onOpenLog, super.key});

  /// Let tests reach the two buttons without matching on Arabic that may be reworded.
  static const Key notesKey = Key('order-header-notes');
  static const Key logKey = Key('order-header-log');

  final Order order;

  /// Null on an order nobody wrote anything on — an empty sheet is a wasted tap, and this app
  /// leaves such a button out rather than greying it.
  final VoidCallback? onOpenNotes;

  /// Null without `logs.view`, for the reason the customer card's chevron is: an affordance
  /// promising a screen that would answer 403 is worse than no affordance.
  final VoidCallback? onOpenLog;

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
    final records = math.max(text.scale(22), glyph) + 22.h;

    return kToolbarHeight + 8.h + customer + 10.h + address + 12.h + records + 14.h;
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
      flexibleSpace: FlexibleSpaceBar(
        // `background` rather than `title`, because this is a block of facts and not a heading:
        // it fades out as the bar collapses, leaving the order's number behind it.
        background: _Header(order: order, onOpenNotes: onOpenNotes, onOpenLog: onOpenLog),
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
