import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of the ledger.
///
/// **The kind decides the colour, and the words come from the server.** Stock arriving is the
/// only thing here worth reading as good news; a fulfillment and a downward adjustment both
/// take stock away and are drawn alike, because to a storekeeper checking a balance they are
/// the same event with different paperwork.
class MovementRow extends StatelessWidget {
  const MovementRow({required this.movement, this.showTitle = true, super.key});

  final StockMovement movement;

  /// Whether to name the shelf on the row. False on a feed that is *about* one shelf — there the
  /// header says it once, and repeating it per row is a column of identical words.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (icon, tone) = _look(context, movement.movementType);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: tone),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showTitle) ...[
                  Row(
                    children: [
                      // The shelf's code, in the accent a code wears everywhere in this app —
                      // «S7» is what is said out loud and searched for. Not a product's: the
                      // pile is shared, and this row moved all of it at once.
                      if (movement.code case final code?) ...[
                        Text(
                          code,
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Flexible(
                        child: Text(
                          movement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                ],
                Text(
                  // «توريد · من المخزن الرئيسي ← صالة العرض» — what happened and where, in one
                  // line, with the halves that do not exist simply absent.
                  [
                    movement.movementTypeLabel,
                    if (movement.route.isNotEmpty) movement.route,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (_meta(movement) case final meta when meta.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (movement.notes case final notes?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    notes,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            movement.quantityLabel,
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: tone),
          ),
        ],
      ),
    );
  }

  /// When it happened and who recorded it — the two questions asked of a ledger line that the
  /// quantity does not answer.
  String _meta(StockMovement movement) => [
    if (movement.createdAt case final at?) _stamp(at),
    if (movement.employee?.name case final name?) 'بواسطة $name',
    if (movement.referenceId case final reference?) 'مرجع #$reference',
  ].join(' · ');

  /// «6 أغسطس 2026 · 2:30 م», in the device's own local time — the one stamp the whole app
  /// draws, because a ledger is read as "in what order, and how far apart".
  String _stamp(DateTime at) => at.stampLabel;

  (IconData, Color) _look(BuildContext context, MovementType type) {
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
}
