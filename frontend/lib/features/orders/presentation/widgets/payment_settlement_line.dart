import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «سُوّيت إلى المصرف — فلان · التاريخ» with «تراجع», or «في النورس» with «تسوية».
/// TREASURY-DESIGN §٢٣.
///
/// **Every decision here is the server's**, as on [PaymentReviewLine]: whether this person may
/// settle ([OrderPayment.canSettle]) or undo ([OrderPayment.canUnsettle]), and why not
/// ([OrderPayment.unsettleBlockedReason]). Draws nothing on a row with nothing to say — a refund,
/// a payment from before the treasury, or somebody without the grant looking at an unsettled one.
class PaymentSettlementLine extends StatelessWidget {
  const PaymentSettlementLine({
    required this.payment,
    required this.isBusy,
    required this.onSettle,
    required this.onUnsettle,
    super.key,
  });

  final OrderPayment payment;
  final bool isBusy;
  final VoidCallback onSettle;
  final VoidCallback onUnsettle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final settlement = payment.settlement;

    if (settlement != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.settled, size: 15.sp, color: scheme.primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _settledLine(settlement),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (payment.canUnsettle)
                TextButton(
                  key: ValueKey('unsettle-${payment.id}'),
                  onPressed: isBusy ? null : onUnsettle,
                  style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                  child: const Text('تراجع'),
                ),
            ],
          ),
          if (settlement.hasFee)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 21.w),
              child: Text(
                'احتفظ الناقل بـ ${settlement.fee.grouped} — وصل ${settlement.received.grouped}',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (payment.unsettleBlockedReason case final reason?)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 21.w),
              child: Text(
                reason,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      );
    }

    if (!payment.canSettle) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(AppIcons.transfer, size: 15.sp, color: scheme.tertiary),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            switch ((payment.treasuryAccount?.name, payment.settlementTarget?.name)) {
              (final from?, final to?) => 'في $from — تُسوّى إلى $to',
              (final from?, null) => 'في $from',
              _ => 'لم تُسوَّ بعد',
            },
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          key: ValueKey('settle-${payment.id}'),
          onPressed: isBusy ? null : onSettle,
          child: const Text('تسوية'),
        ),
      ],
    );
  }

  static String _settledLine(PaymentSettlement settlement) {
    final parts = <String>[
      'سُوّيت إلى ${settlement.toAccount?.name ?? 'حساب'}',
      if (settlement.settledBy case final who?) who.name,
      if (settlement.settledAt case final at?) at.stampLabel,
    ];

    return parts.join(' · ');
  }
}

/// Why a settlement is being taken back — required, like every money correction here.
Future<String?> askUnsettleReason(BuildContext context, OrderPayment payment) {
  return showDialog<String>(
    context: context,
    builder: (_) => _UnsettleReasonDialog(payment: payment),
  );
}

/// A widget rather than a closure, so the controller is disposed after the dialog has left the
/// tree, not while it is still fading out.
class _UnsettleReasonDialog extends StatefulWidget {
  const _UnsettleReasonDialog({required this.payment});

  final OrderPayment payment;

  @override
  State<_UnsettleReasonDialog> createState() => _UnsettleReasonDialogState();
}

class _UnsettleReasonDialogState extends State<_UnsettleReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.payment.treasuryAccount?.name;
    final to = widget.payment.settlement?.toAccount?.name;

    return AlertDialog(
      title: const Text('التراجع عن التسوية'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                'يعود ${widget.payment.amount.grouped}',
                if (to != null) 'من $to',
                if (from != null) 'إلى $from',
                '— وتبقى التسوية في السجل معكوسة.',
              ].join(' '),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _reason,
              label: 'السبب',
              autofocus: true,
              maxLines: 2,
              validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        TextButton(onPressed: _submit, child: const Text('تراجع')),
      ],
    );
  }
}
