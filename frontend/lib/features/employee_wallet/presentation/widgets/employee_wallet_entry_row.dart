import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_ledger_row.dart';
import 'package:flutter/material.dart';

/// سطرٌ في محفظة موظف، بشكل [WalletLedgerRow].
///
/// **يذكر الطريقة أو التصنيف وحدهما لا اسم الحساب**، كقرار محفظة العميل (٢٠٢٦-١٠-١٧). وصاحبُ
/// المحفظة لا يصله اسم من سجّلها، فيبقى الوقت وحده.
class EmployeeWalletEntryRow extends StatelessWidget {
  const EmployeeWalletEntryRow({
    required this.entry,
    this.showEmployee = false,
    this.onTap,
    this.onReverse,
    super.key,
  });

  final EmployeeWalletEntry entry;

  /// «حركات محافظ الموظفين» تجمعهم كلهم، فيقول كل سطرٍ لمن هو.
  final bool showEmployee;

  /// يفتح محفظة الموظف من الصفحة الجامعة.
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

  String? get _where {
    final parts = <String>[
      if (showEmployee) ?entry.employeeName,
      ?(entry.methodLabel ?? entry.categoryName),
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  String get _footer => [
    ?entry.recorderName,
    if (entry.occurredAt case final at?) at.timeLabel,
  ].join(' · ');

  IconData get _icon {
    if (entry.isReversal) return AppIcons.reversePayment;

    return switch (entry.type) {
      'deposit' => AppIcons.fundDeposit,
      'credit' => AppIcons.salary,
      'withdrawal' => AppIcons.fundWithdraw,
      'adjustment_credit' || 'adjustment_debit' => AppIcons.edit,
      _ => AppIcons.more,
    };
  }
}
