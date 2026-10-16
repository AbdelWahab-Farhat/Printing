import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الدفع من المحفظة» — how much of the customer's wallet goes to this order, or null when it was
/// dismissed. Docs/payments/CUSTOMER-WALLET.md.
///
/// **A dialog, like the write-off**: one number and a yes. It opens on the smaller of the balance
/// and what the order owes — the most the server would take — so the common case is one tap.
/// Neither ceiling is enforced here: a colleague may pay from the same wallet a second earlier,
/// and the server's answer is the one that counts.
Future<String?> showPayFromWalletDialog({
  required BuildContext context,
  required PaymentSummary summary,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PayFromWalletDialog(summary: summary),
  );
}

/// Stateful so the controller is disposed after the exit animation, not when the route pops —
/// see `_WriteOffDialog`.
class _PayFromWalletDialog extends StatefulWidget {
  const _PayFromWalletDialog({required this.summary});

  final PaymentSummary summary;

  @override
  State<_PayFromWalletDialog> createState() => _PayFromWalletDialogState();
}

class _PayFromWalletDialogState extends State<_PayFromWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;

  /// The smaller of what the wallet holds and what the order owes.
  String get _most {
    final balance = widget.summary.walletBalance;
    final remaining = widget.summary.remainingAmount;

    final smaller = thousandths(balance) <= thousandths(remaining) ? balance : remaining;

    return fromThousandths(thousandths(smaller), scale: 2);
  }

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _most);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_amount.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AlertDialog(
      title: const Text('الدفع من المحفظة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'في المحفظة ${widget.summary.walletBalance.grouped} — '
              'والمتبقي على الطلبية ${widget.summary.remainingAmount.grouped}',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _amount,
              label: 'المبلغ',
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'المبلغ مطلوب';

                final amount = double.tryParse(_western(text));
                if (amount == null) return 'المبلغ يجب أن يكون رقماً';
                if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(onPressed: _submit, child: const Text('ادفع من المحفظة')),
      ],
    );
  }

  /// Enough to validate the shape; the real conversion is `normaliseAmount` on the way out.
  static String _western(String input) {
    const indic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();

    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final at = indic.indexOf(char);
      buffer.write(at != -1 ? '$at' : (char == '٫' ? '.' : char));
    }

    return buffer.toString();
  }
}
