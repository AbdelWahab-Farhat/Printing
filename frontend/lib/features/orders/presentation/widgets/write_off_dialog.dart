import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What somebody decided to stop chasing, and why.
typedef WriteOffDraft = ({String amount, String reason});

/// Asks for the difference that is not coming back.
///
/// **A dialog rather than a sheet, like cancelling an entry and unlike recording one.** There are
/// two fields, both short, and the thing being decided is a yes/no with a number attached — a
/// full sheet with a method picker and a file field would dress a decision up as paperwork.
///
/// The amount opens on the whole remaining balance, because that is what a write-off nearly
/// always is: the five dinars that came back short. Somebody forgiving part of it edits one
/// field; everybody else presses the button.
Future<WriteOffDraft?> showWriteOffDialog({
  required BuildContext context,
  required PaymentSummary summary,
}) {
  final amount = TextEditingController(text: _defaultAmount(summary));
  final reason = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<WriteOffDraft>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('شطب الفرق'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **What this is, in the two sentences that stop it being used as a discount.**
              // The order keeps its price and nothing is recorded as collected; what is being
              // written down is that the money is not coming.
              Text(
                'يُقفل المتبقي دون تسجيل أي قبض — سعر الطلبية يبقى '
                '${summary.grandTotal.grouped} والفرق يُقيَّد في السجل خسارةً.',
                style: dialogContext.textTheme.bodyMedium?.copyWith(
                  color: dialogContext.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: amount,
                label: 'المبلغ',
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // The same formatter the payment sheet uses, and for the same reason: a comma
                // is fifteen hundred to most people and one and a half to some, so it never
                // gets typed. Arabic-Indic digits are allowed and converted on the way out.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                helperText: 'المتبقي ${summary.remainingAmount.grouped}',
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: reason,
                label: 'السبب',
                maxLines: 2,
                // Required by the server too. This is the row an auditor stops at, and «تم
                // الشطب» with a blank beside it is not an answer.
                validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('تراجع')),
        TextButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;

            Navigator.of(
              dialogContext,
            ).pop((amount: amount.text.trim(), reason: reason.text.trim()));
          },
          child: Text('شطب الفرق', style: TextStyle(color: dialogContext.colorScheme.error)),
        ),
      ],
    ),
  ).whenComplete(() {
    amount.dispose();
    reason.dispose();
  });
}

/// The whole outstanding balance, which is the ceiling the server enforces anyway.
///
/// An overpaid order has a negative remainder and nothing sensible to suggest, so it opens
/// blank — and the server refuses a write-off there in any case: that order needs a refund.
String _defaultAmount(PaymentSummary summary) {
  final remaining = summary.remainingAmount;

  return remaining.startsWith('-') || remaining == '0.00' ? '' : remaining;
}

/// Only the shape is checked here.
///
/// **Whether it exceeds what is owed is the server's answer**, because it depends on entries
/// this screen may not have seen — a colleague taking a payment at the same counter one second
/// earlier. The same division of labour the payment sheet draws.
String? _validateAmount(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'المبلغ مطلوب';

  final amount = double.tryParse(_toWesternDigits(text));

  if (amount == null) return 'المبلغ يجب أن يكون رقماً';
  if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

  return null;
}

/// Enough of a conversion to *validate* the shape. The real one lives beside the API call — see
/// `normaliseAmount` — and this deliberately does not call it, because a validator that silently
/// rewrote the field would change a number under somebody's finger.
String _toWesternDigits(String input) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();

  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final indic = arabicIndic.indexOf(char);

    buffer.write(indic != -1 ? '$indic' : (char == '٫' ? '.' : char));
  }

  return buffer.toString();
}
