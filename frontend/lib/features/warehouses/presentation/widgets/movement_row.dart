import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of the feed — the whole workshop's ledger, or one warehouse's.
///
/// Read the way [LedgerRow] is read, because it is the same book at a wider zoom: on the
/// reading side **what moved** (the shelf, by code and name), **what happened** to it and for
/// which order, and the time and the hand that signed it; on the other, **how much, with its
/// sign, in its unit**. The day is on the header above the group, not repeated on every row.
///
/// **Big type, few words, no card.** The old feed drew three lines of caption-size type inside
/// a box, and the number that mattered was unsigned and unitless: «1.6» of what, which way?
/// Here the number is the largest thing on the row, its unit sits under it, and a row that came
/// out of an order opens that order when tapped — the thing a reader of the feed most often
/// wants next.
class MovementRow extends StatelessWidget {
  const MovementRow({required this.movement, this.onOpenOrder, super.key});

  final StockMovement movement;

  /// Called with the order's id when a row that belongs to an order is tapped. A row with no
  /// order behind it is not tappable at all, whatever is passed here.
  final ValueChanged<int>? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (icon, tone) = movementLook(context, movement.movementType);
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final orderId = movement.orderId;
    final open = onOpenOrder;

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Icon(icon, size: 20.sp, color: tone),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // The shelf's code, in the accent a code wears everywhere in this app —
                    // «S7» is what is said out loud and searched for. Not a product's: the
                    // pile is shared, and this row moved all of it at once.
                    if (movement.code case final code?) ...[
                      Text(
                        code,
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Flexible(
                      child: Text(
                        movement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  // «صرف لطلب #1242 · من المخزن الرئيسي» — what happened, for what, and where,
                  // in one line, with the halves that do not exist simply absent.
                  _what(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: quiet,
                ),
                if (_whenAndWho() case final line when line.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: quiet),
                ],
                if (movement.notes case final notes?) ...[
                  SizedBox(height: 4.h),
                  Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                movement.directedQuantityLabel,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                  height: 1.1,
                ),
              ),
              if (movement.unitLabel case final unit?) ...[
                SizedBox(height: 2.h),
                Text(unit, style: quiet),
              ],
            ],
          ),
          if (orderId != null && open != null) ...[
            SizedBox(width: 4.w),
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Icon(AppIcons.forward, size: 16.sp, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );

    if (orderId == null || open == null) return row;

    return InkWell(onTap: () => open(orderId), child: row);
  }

  /// «صرف لطلب #1242 · من المخزن الرئيسي», «تحويل داخلي · المخزن الرئيسي ← مخزن التشغيل»,
  /// «توريد · إلى المخزن الرئيسي».
  String _what() => [_kind(), if (movement.route.isNotEmpty) movement.route].join(' · ');

  /// The kind with its reference. An issue and a reversal already say «طلب» in their own
  /// words, so only the number is added — «صرف لطلب #1242» rather than «صرف لطلب · طلب #1242»;
  /// anything else names what the number is the number of: «تلف أثناء الإنتاج · طلب #1229»,
  /// «توريد · مرجع #5».
  String _kind() => switch ((movement.movementType, movement.referenceId)) {
    (_, null) => movement.movementTypeLabel,
    (MovementType.orderFulfillment || MovementType.orderReversal, final reference) =>
      '${movement.movementTypeLabel} #$reference',
    _ => '${movement.movementTypeLabel} · ${movement.referenceLabel}',
  };

  /// The day is on the header above the group; the row keeps only the time.
  String _whenAndWho() => [?movement.createdAt?.timeLabel, ?movement.employee?.name].join(' · ');
}

/// The glyph and colour a kind of movement wears — here and on the ledger, so the two feeds
/// never disagree about what an arrival looks like.
(IconData, Color) movementLook(BuildContext context, MovementType type) {
  final scheme = context.colorScheme;

  return switch (type) {
      MovementType.purchaseArrival => (AppIcons.download, scheme.tertiary),
      MovementType.internalTransfer => (AppIcons.statusChange, scheme.primary),
      MovementType.orderFulfillment => (AppIcons.orders, scheme.onSurfaceVariant),
      MovementType.adjustment => (AppIcons.edit, scheme.onSurfaceVariant),
      // Stock coming back from a cancelled order. [AppIcons.refund] for the turning arrow
      // alone — it is documented for money, but the shape is «the other direction» and that is
      // exactly what this row is: an order's issue, undone.
      MovementType.orderReversal => (AppIcons.refund, scheme.tertiary),
      // Material destroyed on the way through the workshop. Struck out rather than binned:
      // nothing is removed from the ledger, and the quantity was real right up until it was
      // spoiled. Red, because it is the only kind here that is a loss.
      MovementType.scrapLoss => (AppIcons.writeOff, scheme.error),
      // Nothing is claimed about a kind this build has never heard of; its Arabic came with it.
      MovementType.unknown => (AppIcons.more, scheme.onSurfaceVariant),
  };
}
