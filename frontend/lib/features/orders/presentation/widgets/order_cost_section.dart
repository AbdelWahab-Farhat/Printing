import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/orders/models/order.dart';

/// What the order cost to make, and what is left of the invoice after it.
///
/// **Null is «لم يُحتسب بعد» and never «٠٫٠٠».** Nothing is costed until the order enters «قيد
/// الطباعة» and stock leaves a shelf; a zero drawn in that gap would read as «هذه الطلبية لم
/// تكلّفنا شيئاً», which is a different — and false — statement about a job nobody has started.
/// So the two figures are absent together and the section says why.
///
/// **Both numbers are the server's, including the subtraction.** `gross_profit` is
/// `grand_total − total_cogs` worked out where the rule lives; re-deriving it here would be a
/// second answer to one question, and this one would be made of doubles. It is also why the
/// margin on this screen and the one in تقرير الأرباح والخسائر are allowed to differ — that
/// report recognises revenue as the lines plus a chargeable design fee, with no delivery in it —
/// so nothing here invites the two to be reconciled.
///
/// Drawn under «الحساب» rather than inside it: what the customer pays is what this screen is
/// opened for, and the cost side is the quieter question asked after it.
class OrderCostSection extends StatelessWidget {
  const OrderCostSection({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final cogs = order.totalCogs;
    final profit = order.grossProfit;

    if (cogs == null && profit == null) {
      return Text(
        'لم تُحتسب التكلفة بعد — تُحتسب عند دخول الطلبية «قيد الطباعة»',
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        _Line(label: 'تكلفة الإنتاج', value: cogs),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
        _Line(
          label: 'مجمل الربح',
          value: profit,
          // The one thing this section is read for at a glance: did the job make money. Coloured
          // only when the answer is no — every order in profit painted green would make the
          // colour mean nothing by the third screen.
          tone: _isLoss(profit) ? scheme.error : null,
          isTotal: true,
        ),
      ],
    );
  }

  /// Whether the margin came out negative.
  ///
  /// `num.tryParse` for a comparison and for nothing else — what gets drawn is the string the
  /// server sent, `'-45.00'` and all. A parse on the way to the screen is how `'465.00'` becomes
  /// `465.00000000000006`.
  bool _isLoss(String? profit) => (num.tryParse(profit ?? '') ?? 0) < 0;
}

/// One figure, or the honest absence of one.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.tone, this.isTotal = false});

  final String label;

  /// Null until the order reached printing — rendered in words, never as a number.
  final String? value;

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
          Text(label, style: style?.copyWith(color: isTotal ? null : scheme.onSurfaceVariant)),
          const Spacer(),
          Text(
            value?.grouped ?? 'لم يُحتسب بعد',
            // Only the number is a Latin run; the absence is a sentence and reads right-to-left.
            textDirection: value == null ? null : TextDirection.ltr,
            style: value == null
                ? context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)
                : style?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}
