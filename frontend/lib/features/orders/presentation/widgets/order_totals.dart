import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/orders/models/order.dart';

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
    this.tone,
    this.isTotal = false,
  });

  final String label;
  final String value;
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
          Text(
            label,
            style: style?.copyWith(
              color: isTotal ? null : scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
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
