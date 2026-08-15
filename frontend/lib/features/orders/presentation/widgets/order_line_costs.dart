import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';

/// What one line cost to make, under what it is being charged for.
///
/// **Absent, not zero, and absent rather than «لم يُحتسب بعد».** All four figures are null until
/// the line reaches «جاهزة», and a `0.00` there would say the bags cost nothing to make. The
/// order's own cost section says «لم تُحتسب بعد» once, in words; repeating it on every line of an
/// order still on the press would be the same sentence four times over a screen whose subject is
/// what the customer pays.
///
/// **A part missing is a part left out.** The rates are resolved one cost type at a time, and a
/// type with no applicable rate is skipped rather than posted as zero — so an order costed with
/// labour but no overhead shows two figures, not three, and the reader is not told an overhead of
/// nothing was applied.
///
/// One quiet line in the muted colour, deliberately: the revenue side is what an invoice is read
/// for, and a cost printed at the same weight beside it would compete with the number the
/// customer is being asked to pay.
class OrderLineCosts extends StatelessWidget {
  const OrderLineCosts({required this.item, super.key});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final parts = <String>[
      if (item.materialCost case final material?) 'مواد ${material.grouped}',
      if (item.laborCost case final labor?) 'عمالة ${labor.grouped}',
      if (item.overheadCost case final overhead?) 'مصاريف ${overhead.grouped}',
    ];

    final total = item.cogs;
    if (total == null && parts.isEmpty) return const SizedBox.shrink();

    final line = [
      if (total != null) 'التكلفة ${total.grouped}',
      if (parts.isNotEmpty) parts.join(' · '),
    ].join(' — ');

    return Text(
      line,
      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
