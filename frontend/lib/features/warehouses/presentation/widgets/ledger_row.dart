import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/movement_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of a shelf's ledger — the reading a storekeeper's paper book gives.
///
/// Three columns on the first line, right to left: **what happened**, **how much, with its
/// sign**, and **what the shelf held afterwards**. The sign is the whole point: a thousand in
/// and a thousand out were drawn as the same digits on the old feed, with the direction hidden
/// in a preposition halfway along the line. The balance is the quietest thing on the row on
/// purpose — it is there to be checked against the header, not read first.
///
/// The second line is when and who, and — for a reader who may know — what the stock cost.
/// A count says «كان ← صار» underneath: the person entered a count, not a difference, and the
/// row gives them back the number they saw.
///
/// **No card, no warehouse name.** The rows are lines in a table with a hairline between them,
/// and a ledger that is *about* one shelf in one place does not say the place on every line;
/// only a transfer names its other end.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    required this.movement,
    required this.warehouseId,
    required this.unitLabel,
    this.showCost = false,
    super.key,
  });

  final StockMovement movement;

  /// The warehouse this ledger is read for: decides which end of a transfer is «the other».
  final int warehouseId;

  /// The balance's unit — «قطعة», «كيلوغرام» — for the cost line's «د.ل/قطعة».
  final String unitLabel;

  /// Whether the reader holds `inventory.view_cost`. **Decided by the caller from the session,
  /// never from the payload**: a row whose cost nobody recorded must still say so to someone
  /// entitled to know, and stay silent to someone who is not.
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final (icon, tone) = movementLook(context, movement.movementType);
    final quantity = movement.signedQuantityLabel ?? movement.quantityLabel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, size: 18.sp, color: tone),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        _what(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      quantity,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                    if (movement.balanceAfterLabel case final balance?) ...[
                      SizedBox(width: 10.w),
                      _Balance(label: balance),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _whenAndWho(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (showCost) ...[SizedBox(width: 8.w), _Cost(movement: movement, unitLabel: unitLabel)],
                  ],
                ),
                if (movement.movementType == MovementType.adjustment &&
                    movement.balanceBeforeLabel != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'كان ${movement.balanceBeforeLabel} ← صار ${movement.balanceAfterLabel}',
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
        ],
      ),
    );
  }

  /// «صرف لطلب #4», «تحويل داخلي ← صالة العرض», «توريد» — the kind, plus only what tells this
  /// row apart from the next of its kind.
  String _what() => [
    movement.movementTypeLabel,
    if (movement.referenceId case final reference?) '#$reference',
    if (movement.otherEndFrom(warehouseId) case final end when end.isNotEmpty) end,
  ].join(' ');

  /// The day is on the header above the group; the row keeps only the time.
  String _whenAndWho() => [?movement.createdAt?.timeLabel, ?movement.employee?.name].join(' · ');
}

/// «الرصيد 300» — the running total, labelled, in the quietest style on the row.
class _Balance extends StatelessWidget {
  const _Balance({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant);

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'الرصيد '),
          TextSpan(text: label, style: style?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
      textDirection: TextDirection.rtl,
      style: style,
    );
  }
}

/// The cost line, or «التكلفة غير معروفة» for a row older than the cost ledger — said to a
/// reader entitled to know, because silence there would read as «free».
class _Cost extends StatelessWidget {
  const _Cost({required this.movement, required this.unitLabel});

  final StockMovement movement;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = movement.costLine(unitLabel);

    return Text(
      line?.text ?? 'التكلفة غير معروفة',
      textDirection: TextDirection.rtl,
      style: context.textTheme.labelSmall?.copyWith(
        color: line?.warns == true ? scheme.warn : scheme.onSurfaceVariant,
        fontWeight: line?.warns == true ? FontWeight.w700 : null,
      ),
    );
  }
}
