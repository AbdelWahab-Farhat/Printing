import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Under one cost on the order's screen: what came back on it, and the way to bring back more.
///
/// [canRefund] is the caller's answer to "may this person, on an order in this status" — the
/// button still needs money left on the cost, and that part is the server's figure.
class CostRefunds extends StatelessWidget {
  const CostRefunds({
    required this.cost,
    required this.canRefund,
    required this.onRefund,
    required this.onReverse,
    super.key,
  });

  final PurchaseOrderAdditionalCost cost;
  final bool canRefund;
  final VoidCallback onRefund;
  final ValueChanged<PurchaseOrderCostRefund> onReverse;

  @override
  Widget build(BuildContext context) {
    final showButton = canRefund && cost.hasRefundableAmount;

    if (cost.refunds.isEmpty && !showButton) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final refund in cost.refunds)
          _RefundLine(
            refund: refund,
            onReverse: canRefund && !refund.isReversed
                ? () => onReverse(refund)
                : null,
          ),
        if (showButton)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: ValueKey('cost-refund-${cost.id}'),
              onPressed: onRefund,
              icon: Icon(AppIcons.undo, size: 16.sp),
              label: Text(
                cost.refunds.isEmpty
                    ? 'استرداد'
                    : 'استرداد المتبقي (${groupedDecimal(cost.refundableAmount ?? '0')} د.ل)',
              ),
            ),
          ),
      ],
    );
  }
}

class _RefundLine extends StatelessWidget {
  const _RefundLine({required this.refund, required this.onReverse});

  final PurchaseOrderCostRefund refund;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final muted = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.outline,
    );
    final byWhom = refund.recordedByName;

    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('استُرد', style: context.textTheme.bodySmall),
              const Spacer(),
              Text(
                '${refund.amountLabel} د.ل',
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: refund.isReversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
          Text(
            byWhom == null ? refund.reason : '${refund.reason} · $byWhom',
            style: muted,
          ),
          if (refund.isReversed)
            Text('تم التراجع: ${refund.reversalReason ?? ''}', style: muted),
          if (onReverse != null)
            TextButton(
              key: ValueKey('cost-refund-reverse-${refund.id}'),
              onPressed: onReverse,
              child: const Text('تراجع عن الاسترداد'),
            ),
        ],
      ),
    );
  }
}
