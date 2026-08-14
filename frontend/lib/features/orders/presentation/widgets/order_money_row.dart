import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the order costs, what has been paid, and what is left — read in one glance.
///
/// **Three cells on one line, and it replaces the single «الإجمالي» that used to sit here.** The
/// total alone answered one question; these three answer the same one more completely, and
/// keeping both would print the order's value twice on one screen.
///
/// **Every number is the string the server sent, including the subtraction.** «المتبقي» is not
/// `grandTotal - paidAmount` computed here — that would be a second answer to one question, and
/// the phone's is the one made of doubles.
///
/// The middle cell is «المدفوع», not «العربون». A deposit is what a part-payment is *called*, and
/// the word stops being true the moment the order is paid in full — one label that is always
/// accurate beats one that is usually accurate.
class OrderMoneyRow extends StatelessWidget {
  const OrderMoneyRow({required this.summary, super.key});

  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Cell(label: 'سعر الطلبية', value: summary.grandTotal),
            ),
            _Divider(color: scheme.outlineVariant),
            Expanded(
              child: _Cell(label: 'المدفوع', value: summary.paidAmount, tone: scheme.primary),
            ),
            _Divider(color: scheme.outlineVariant),
            Expanded(
              child: _Cell(
                label: 'المتبقي',
                value: summary.remainingAmount,
                // The one thing somebody wants from this row at a glance: is anything still
                // owed. Coloured only when the answer is yes — a zero in alarm red would make
                // the settled case look like the problem.
                tone: summary.isOutstanding ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        // The state in words, under the numbers, because «مدفوعة بالزيادة» is a fact the three
        // figures state only if the reader does the arithmetic — and the label is the server's
        // own Arabic, so a state added after this release still reads correctly.
        if (summary.paymentStatusLabel.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _StatusChip(summary: summary),
          ),
        ],

        // An order that finished with money the ledger never saw.
        //
        // **Settling an order writes no entry**, on purpose: nothing records a payment except
        // the person who took it. So instead of inventing a figure nobody collected, the gap is
        // put on screen where somebody can close it.
        if (summary.hasUnrecordedMoney) ...[
          SizedBox(height: 12.h),
          _Warning(amount: summary.remainingAmount),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        Text(label, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        SizedBox(height: 6.h),
        FittedBox(
          // Three money figures share one line on a narrow phone, and a five-digit total in
          // Arabic is wide. Shrinking beats wrapping: half a number on a second line is worse
          // than a smaller whole one.
          fit: BoxFit.scaleDown,
          child: Text(
            value.grouped,
            // A Latin run inside an RTL row: without this the separator lands on the wrong
            // side of the number.
            textDirection: TextDirection.ltr,
            maxLines: 1,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      color: color,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.summary});

  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (background, foreground) = switch (summary.paymentStatus) {
      // The pale green, not the primary container: settled is the one state on this screen worth
      // recognising before it is read, and the teal container is already the app's ordinary fill.
      PaymentStatus.paid => (scheme.paidContainer, scheme.onPaidContainer),
      PaymentStatus.overpaid => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      PaymentStatus.unpaid ||
      PaymentStatus.partiallyPaid ||
      PaymentStatus.unknown => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999.r)),
      child: Text(
        summary.paymentStatusLabel,
        style: context.textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'الطلبية منتهية ولم يُسجَّل قبض ${amount.grouped}',
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
