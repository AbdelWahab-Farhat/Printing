import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/receipt_viewer.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/models/shortage_supply.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Every operation on a shortage, oldest first as the server sorts it.
///
/// **Reversals stay in the table, struck through.** §٩ of the brief asks for a log of every
/// operation, and a correction that vanished from the very screen meant to explain the numbers
/// would make a shortage reading «١٠ كجم» after two entries of twenty look like a mistake rather
/// than a recorded one.
///
/// **Rows this section never wrote sit here too.** A `resolved_externally` entry came from the
/// order screen when a colleague typed what turned up — it carries no money at all, so its value
/// and method columns print a dash. **Never `0.00`**, which reads as a free purchase and sits
/// wrongly in anybody's mental total.
class SuppliesTable extends StatelessWidget {
  const SuppliesTable({required this.shortage, this.onReverse, super.key});

  final Shortage shortage;

  /// Null for a reader without `shortages.supplies.reverse`. A row that may not be undone —
  /// an arrival from the order, or a reversal itself — is decided by the row's own
  /// `is_reversible`, which the server has already answered.
  final void Function(ShortageSupply supply)? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العمليات',
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: shortage.supplies.isEmpty
              // Not «٠ عمليات»: nothing has been bought yet, and a zero would suggest a figure
              // was measured.
              ? Text(
                  'لم تُسجَّل أي عملية توفير بعد',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                )
              : Column(
                  children: [
                    for (final (index, supply) in shortage.supplies.indexed) ...[
                      if (index > 0) Divider(height: 20.h),
                      _SupplyRow(
                        shortage: shortage,
                        supply: supply,
                        onReverse: supply.isReversible && onReverse != null
                            ? () => onReverse!(supply)
                            : null,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SupplyRow extends StatelessWidget {
  const _SupplyRow({required this.shortage, required this.supply, required this.onReverse});

  final Shortage shortage;
  final ShortageSupply supply;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final struck = supply.isStruckThrough;

    final style = context.textTheme.bodyMedium?.copyWith(
      decoration: struck ? TextDecoration.lineThrough : null,
      color: struck ? scheme.onSurfaceVariant : scheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shortage.withUnit(supply.quantity),
                style: style?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              // A dash, not a zero — see the class note.
              switch (supply.amount) {
                final amount? => '${amount.grouped} د.ل',
                null => '—',
              },
              textDirection: TextDirection.ltr,
              style: style,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Text(
              // The server's own word for what kind of entry this is — «شراء», «وصلت من
              // الطلبية», «عكس عملية».
              supply.kindLabel,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (supply.methodLabel case final method?) ...[
              Text(' · ', style: context.textTheme.bodySmall),
              Text(
                method,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const Spacer(),
            if (supply.occurredOn case final day?)
              Text(
                day,
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            if (supply.recorder case final who?)
              Text(
                who.name,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            // **Where the goods landed, named.** `moved_stock` is the flag, never `warehouse_id`:
            // the three stock fields are null together on a purchase that moved nothing.
            if (supply.movedStock && supply.warehouse != null) ...[
              Text(' · ', style: context.textTheme.bodySmall),
              Text(
                supply.warehouse!.name,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            // **الواصل, and pressing it shows the paper itself** — an image full screen in the
            // app, a PDF handed to the phone. On most rows this is a fact to skim past; for
            // whoever is checking what a sack actually cost it is the proof, so the fact opens
            // it. Which glyph it wears is the server's `receipt_is_image` answer.
            if (supply.hasReceipt) ...[
              Text(' · ', style: context.textTheme.bodySmall),
              InkWell(
                onTap: () => unawaited(
                  showReceipt(
                    context,
                    Receipt(
                      cacheKey: 'supply-receipt-${supply.id}',
                      url: supply.receiptUrl,
                      isImage: supply.receiptIsImage,
                      filename: supply.receiptFilename,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      supply.receiptIsImage ? AppIcons.photos : AppIcons.pdf,
                      size: 14.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'الواصل',
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (onReverse != null)
              TextButton(
                onPressed: onReverse,
                child: Text('عكس', style: TextStyle(color: scheme.error)),
              ),
          ],
        ),
      ],
    );
  }
}
