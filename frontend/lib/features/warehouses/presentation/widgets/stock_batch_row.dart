import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One cost layer under a balance, in the order the next issue will draw it.
///
/// Its [position] is drawn as a numeral because the order *is* the information: the first
/// layer is what the next order will be costed at, and «التالية للصرف» says so in words on it.
/// The price is the loudest thing on the row — it is the number a person knows is wrong on
/// sight — and a layer nobody priced says «بلا تكلفة» there in `warn`, never `0.000`.
class StockBatchRow extends StatelessWidget {
  const StockBatchRow({required this.batch, required this.position, this.isNext = false, super.key});

  final StockBatch batch;

  /// 1-based, in FIFO order.
  final int position;

  /// Whether this is the layer the next issue draws from — the first one still on the shelf.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Position(position: position, highlighted: isNext),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _source(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (batch.isUncosted)
                      Text(
                        'بلا تكلفة',
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: scheme.warn,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else
                      Text(
                        '${batch.unitCostLabel} د.ل/${batch.unitLabel}',
                        textDirection: TextDirection.rtl,
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        batch.isFullyConsumed
                            ? 'استُهلكت كلّها · ${batch.receivedLabel} ${batch.unitLabel}'
                            : 'متبقي ${batch.remainingLabel} من ${batch.receivedLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (!batch.isUncosted && !batch.isFullyConsumed) ...[
                      SizedBox(width: 8.w),
                      Text(
                        '${_money(batch.remainingValue)} د.ل',
                        textDirection: TextDirection.rtl,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isNext) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'التالية للصرف',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (batch.revaluedAt case final at?) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'عُدّلت تكلفتها ${at.shortDayLabel}',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// «توريد · 31 أغسطس 2026» — where it came from and when, the FIFO key in words.
  String _source() => [batch.sourceTypeLabel, ?batch.receivedAt?.dayLabel].join(' · ');

  /// `1050.00` → `1,050`: the value line is a rounded fact, and the two decimals of a sum only
  /// pretend to a precision the eye does not check here.
  String _money(String value) {
    final trimmed = value.endsWith('.00') ? value.substring(0, value.length - 3) : value;

    return trimmed.grouped;
  }
}

/// The numeral in the margin: the layer's place in the queue.
class _Position extends StatelessWidget {
  const _Position({required this.position, required this.highlighted});

  final int position;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: 26.w,
      height: 26.w,
      margin: EdgeInsets.only(top: 1.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? scheme.primary : scheme.surfaceContainerHighest,
      ),
      child: Text(
        '$position',
        textDirection: TextDirection.ltr,
        style: context.textTheme.labelMedium?.copyWith(
          color: highlighted ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
