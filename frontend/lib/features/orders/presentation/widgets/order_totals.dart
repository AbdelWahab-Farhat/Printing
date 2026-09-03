import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// How the order's total was reached.
///
/// **Every number is rendered as the string the server sent.** Not parsed, not re-formatted: a
/// total assembled on the server and then re-derived on the phone is two answers to one
/// question, and the phone's is the one made of doubles.
///
/// Lines that are zero are absent rather than shown as `0.00` — a design fee of nothing is not
/// a fact about this order, it is the absence of one, and printing it invites the reader to
/// wonder what it means.
class OrderTotals extends StatelessWidget {
  const OrderTotals({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        _Line(label: 'المنتجات', value: order.itemsTotal.grouped),
        if (order.hasDesignFee) _Line(label: 'التصميم', value: order.designFee.grouped),
        _Line(
          label: 'التوصيل',
          // '0.00' is a fact worth stating here — it is what an office pickup costs, and the
          // reader is checking a total. Only the *fee* lines hide when empty.
          value: order.deliveryPrice.grouped,
        ),
        // **After the delivery and before the discount — the server's own order of operations.**
        // A reader checking the total works down the column, and a charge printed under the
        // subtraction it comes before turns a correct total into an arithmetic mistake.
        //
        // **What it was for is on the same line, not in a section under this one.** «كم» and
        // «على ماذا» are one fact about one charge; answering them in two places printed the
        // same figure twice, one card apart, and left the reader checking whether they matched.
        // The words are [Order.additionalCostCaption]'s — the same sentence the invoice and the
        // WhatsApp message carry, which is what stops one charge being described three ways.
        if (order.hasAdditionalCost)
          _Line(
            label: 'التكلفة الإضافية',
            note: order.additionalCostCaption,
            value: '+ ${order.additionalCost.grouped}',
          ),
        if (order.hasDiscount)
          _Line(label: 'الخصم', value: '- ${order.discount.grouped}', tone: scheme.error),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
        _Line(label: 'الإجمالي', value: order.grandTotal.grouped, isTotal: true),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.note,
    this.tone,
    this.isTotal = false,
  });

  final String label;
  final String value;

  /// What this line was for, when the label alone does not say it — «نقل — سيارة أجرة».
  ///
  /// Null on every line whose label is the whole answer, which is all of them but the added
  /// charge: «المنتجات» needs no explaining and a note under it would be a sentence invented to
  /// fill a slot.
  final String? note;
  final Color? tone;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = isTotal
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : context.textTheme.bodyMedium;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          // Expanded rather than a `Spacer` beside a bare label: the note is a clerk's own
          // sentence, so the label side has to be the part that gives way, and the number stays
          // where the column expects it however long the sentence runs.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: style?.copyWith(
                    color: isTotal ? null : scheme.onSurfaceVariant,
                  ),
                ),
                if (note case final note?)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      note,
                      // Two lines, because «أخرى» puts the clerk's own sentence here.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            // Grouped by the caller: «الخصم» carries a leading sign, and the separator is added
            // to the number rather than to the sentence around it.
            value,
            // A Latin run inside an RTL row, so the separator stays where it was written.
            textDirection: TextDirection.ltr,
            style: style?.copyWith(color: tone ?? (isTotal ? scheme.primary : null)),
          ),
        ],
      ),
    );
  }
}
