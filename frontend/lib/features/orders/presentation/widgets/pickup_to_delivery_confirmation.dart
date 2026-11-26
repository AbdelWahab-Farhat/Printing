import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';

/// «ستنتقل الطلبية إلى «إعادة إرسال»» — and true only on a yes.
///
/// Asked by the edit form before it saves a delivery city onto an order at «استلام مكتب»: the
/// server moves such an order to «إعادة إرسال» with the edit (owner's decision, 2026-11-26), and a
/// status change should never be a surprise found on the order card afterwards.
Future<bool> confirmPickupBecomesDelivery(BuildContext context, {required String cityName}) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تحويل إلى توصيل'),
      content: Text(
        'ستنتقل الطلبية إلى «إعادة إرسال» للتوصيل إلى $cityName. متابعة؟',
        style: dialogContext.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('تراجع')),
        TextButton(
          key: const ValueKey('accept-pickup-to-delivery'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('متابعة'),
        ),
      ],
    ),
  );

  return answer ?? false;
}
