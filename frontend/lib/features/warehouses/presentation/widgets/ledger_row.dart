import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/movement_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of a shelf's ledger — the reading a storekeeper's paper book gives.
///
/// Two columns. On the reading side, **what happened** and when, and who; on the other, the
/// numbers stacked in the order a ledger is read: **how much, with its sign**, then **what the
/// shelf held afterwards**, then — for a reader who may know — **what it cost**. The sign is
/// the whole point: a thousand in and a thousand out were drawn as the same digits on the old
/// feed, with the direction hidden in a preposition halfway along the line.
///
/// A count says «كان ← صار» underneath: the person entered a count, not a difference, and the
/// row gives them back the number they saw.
///
/// **Big type, few words, air between rows.** Each figure gets one line to itself and the
/// cost is one number, not two — the price of arriving stock, the total of leaving stock — so
/// the row is read at a glance rather than parsed. No card, and no warehouse name: a ledger
/// that is *about* one shelf in one place does not say the place on every line; only a
/// transfer names its other end.
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
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return Padding(
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
                Text(
                  _what(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Text(_whenAndWho(), maxLines: 1, overflow: TextOverflow.ellipsis, style: quiet),
                if (movement.movementType == MovementType.adjustment &&
                    movement.balanceBeforeLabel != null) ...[
                  SizedBox(height: 4.h),
                  Text('كان ${movement.balanceBeforeLabel} ← صار ${movement.balanceAfterLabel}', style: quiet),
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
                movement.signedQuantityLabel ?? movement.quantityLabel,
                textDirection: TextDirection.ltr,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tone,
                  height: 1.1,
                ),
              ),
              if (movement.balanceAfterLabel case final balance?) ...[
                SizedBox(height: 4.h),
                _Balance(label: balance),
              ],
              if (showCost) ...[SizedBox(height: 4.h), _Cost(movement: movement, unitLabel: unitLabel)],
            ],
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

/// «الرصيد 300» — the running total, labelled, with the number carrying the weight.
class _Balance extends StatelessWidget {
  const _Balance({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant);

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'الرصيد '),
          TextSpan(
            text: label,
            style: style?.copyWith(color: context.colorScheme.onSurface, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      style: style,
    );
  }
}

/// The cost, one number; «بلا تكلفة» in `warn` for stock nobody priced; and «التكلفة غير
/// معروفة» for a row older than the cost ledger — said to a reader entitled to know, because
/// silence there would read as «free».
class _Cost extends StatelessWidget {
  const _Cost({required this.movement, required this.unitLabel});

  final StockMovement movement;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = movement.costLine(unitLabel);
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final warn = quiet?.copyWith(color: scheme.warn, fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          line?.text ?? 'التكلفة غير معروفة',
          textDirection: TextDirection.rtl,
          style: line?.warns == true ? warn : quiet,
        ),
        if (line?.detail case final detail?) ...[
          SizedBox(height: 2.h),
          Text(detail, textDirection: TextDirection.rtl, style: warn),
        ],
      ],
    );
  }
}
