import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';

/// How much of [typed] is beyond [owed], or null when none of it is.
///
/// **Fixed-point, never `double`**: the answer is shown to somebody holding the customer's money,
/// and «زائد 0.9999999» is not a sentence anybody should read. [typed] is what was in the box —
/// Arabic digits and all — and [owed] the server's remaining, which is negative on an order
/// already overpaid and counts as nothing owed.
String? overpaymentExcess(String typed, String owed) {
  final amount = normaliseAmount(typed);

  if (amount.isEmpty) return null;

  final floor = thousandths(owed).isNegative ? BigInt.zero : thousandths(owed);
  final beyond = thousandths(amount) - floor;

  return beyond > BigInt.zero ? fromThousandths(beyond, scale: 2) : null;
}

/// «المبلغ يزيد على المتبقي بـ ١ — تسجيل الزائد للزبون؟» — and true only on a yes.
///
/// **The one place this question is worded**, so the payments screen and the status screen ask
/// it the same way. The server refuses an amount beyond the debt unless this was answered, which
/// is what still catches 500 typed for 50; a yes takes the whole amount and owes the part beyond
/// back to the customer, refundable or kept later.
Future<bool> confirmOverpayment(BuildContext context, {required String excess}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('المبلغ يزيد على المتبقي'),
      content: Text(
        'المبلغ يزيد على المتبقي بـ ${excess.grouped} — تسجيل الزائد للزبون؟\n'
        'يُسجَّل المبلغ كاملاً، ويبقى الزائد للزبون حتى يُردّ له أو يُعتبر إيراداً.',
        style: dialogContext.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('تراجع')),
        TextButton(
          key: const ValueKey('accept-overpayment'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('تسجيل الزائد'),
        ),
      ],
    ),
  );

  return answer ?? false;
}
