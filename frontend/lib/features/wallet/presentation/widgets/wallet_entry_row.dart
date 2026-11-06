import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_ledger_row.dart';
import 'package:flutter/material.dart';

/// سطرٌ في محفظة العميل، بشكل [WalletLedgerRow].
class CustomerWalletEntryRow extends StatelessWidget {
  const CustomerWalletEntryRow({
    required this.entry,
    this.showCustomer = false,
    this.onTap,
    this.onReverse,
    super.key,
  });

  final CustomerWalletEntry entry;

  /// «المعاملات المالية» تجمع العملاء كلهم، فيقول كل سطرٍ لمن هو.
  final bool showCustomer;

  /// يفتح الطلبية، أو محفظة العميل في الصفحة الجامعة.
  final VoidCallback? onTap;

  /// يعكس الحركة. `null` حين لا يجوز — والخادمُ هو من يقول إن كان يجوز.
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    return WalletLedgerRow(
      icon: _icon,
      title: entry.typeLabel,
      amount: entry.amount,
      isIn: entry.isIn,
      footer: _footer,
      where: _where,
      notes: entry.notes,
      isReversed: entry.isReversed,
      isReversal: entry.isReversal,
      reversalReason: entry.reversalReason,
      onTap: onTap,
      onReverse: onReverse,
    );
  }

  /// لمن وكيف: العميلُ في الصفحة الجامعة، ثم **طريقةُ الدفع وحدها** — الحسابُ والطلبيةُ والمرجعُ
  /// سقطت بطلب صاحب العمل (٢٠٢٦-١٠-١٧): «وسيلة الدفع فقط التي تهم». الطلبيةُ تُفتح بلمس السطر.
  String? get _where {
    final parts = <String>[
      if (showCustomer && entry.customerName != null) entry.customerName!,
      ?entry.methodLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// من سجّلها ومتى — والزبونُ حين دفع من التطبيق بلا اسم موظف.
  String get _footer => [
    ?entry.recorderName,
    if (entry.occurredAt case final at?) at.timeLabel,
  ].join(' · ');

  /// ما يُعرَف به نوعُ الحركة قبل أن يُقرأ.
  IconData get _icon {
    if (entry.isReversal) return AppIcons.reversePayment;

    return switch (entry.type) {
      'topup' => AppIcons.walletTopUp,
      'order_payment' => AppIcons.payment,
      'order_refund' => AppIcons.refund,
      'adjustment_credit' || 'adjustment_debit' => AppIcons.edit,
      _ => AppIcons.more,
    };
  }
}
