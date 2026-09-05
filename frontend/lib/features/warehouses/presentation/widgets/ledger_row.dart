import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    // **«1,000 ← 0» is the row's number.** From what to what, and the difference
                    // between them is the movement — so the signed figure that used to sit on
                    // the other side of the row said a third time what these two already say.
                    // The words «كان» and «صار» went with it: an arrow between two balances
                    // needs no verb.
                    if (movement.balanceBeforeLabel case final before?) ...[
                      SizedBox(height: 4.h),
                      Text(
                        '$before ← ${movement.balanceAfterLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                    ] else if (movement.balanceAfterLabel case final after?) ...[
                      // Nothing to say it came *from*: an opening row, or a ledger read from a
                      // page that does not carry the figure before.
                      SizedBox(height: 4.h),
                      Text(
                        after,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tone,
                        ),
                      ),
                    ],
                    // **Whose goods went out.** Drawn only where more than one owner is in the
                    // row: «−1,000» off a shelf nobody funded is the company's by definition,
                    // and saying so on every line would be noise on most of them.
                    if (movement.investorDraws.length > 1) ...[
                      SizedBox(height: 4.h),
                      Text(
                        movement.investorDraws
                            .map((draw) => '${draw.ownerLabel} ${groupedDecimal(draw.quantity)}')
                            .join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: quiet,
                      ),
                    ] else if (movement.investorDraws.firstOrNull?.code case final code?) ...[
                      // One owner, and it is a deal — worth naming, because it is the case the
                      // shelf cannot be read for.
                      SizedBox(height: 4.h),
                      Text('من $code', style: quiet),
                    ],
                    if (movement.notes case final notes?) ...[
                      SizedBox(height: 4.h),
                      Text(notes, style: quiet?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              // **The quantity is gone from here.** «−1,000» beside «1,000 ← 0» was the same
              // fact twice, and the loud one was the redundant one: the pair of balances says
              // both how much moved and where it left the shelf standing.
              if (showCost) _Cost(movement: movement, unitLabel: unitLabel),
            ],
          ),
          // **The time is the last thing that matters and sits where the eye ends.** It used to
          // run under the title, above the figures somebody actually came for.
          if (_whenAndWho() case final line when line.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(line, style: quiet),
            ),
          ],
        ],
      ),
    );
  }

  /// «صرف لطلب #4», «تحويل داخلي ← مخزن التشغيل», «توريد» — the kind, plus only what tells this
  /// row apart from the next of its kind.
  String _what() => [
    movement.movementTypeLabel,
    if (movement.referenceId case final reference?) '#$reference',
    if (movement.otherEndFrom(warehouseId) case final end when end.isNotEmpty) end,
  ].join(' ');

  /// The day is on the header above the group; the row keeps only the time.
  String _whenAndWho() => [?movement.createdAt?.timeLabel, ?movement.employee?.name].join(' · ');
}

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
