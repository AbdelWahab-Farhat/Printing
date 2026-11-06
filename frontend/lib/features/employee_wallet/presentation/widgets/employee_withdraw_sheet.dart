import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_money_fields.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_sheet_frame.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_balance_after.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef EmployeeWithdrawSubmit = Future<Failure?> Function(EmployeeMoneyDraft draft);

/// «سحب» — مالٌ قبضه الموظف. لا يتجاوز رصيد المحفظة، ويُقال ذلك قبل الإرسال.
///
/// **وما في الحساب لا يُقال هنا**: يرفضه الخادم والورقة تبقى مفتوحة، فمن يسحب قد لا يملك رؤية
/// الرصيد. والرصيدُ بعد السحب يتبع كلَّ حرف. تعود `true` حين سُحب.
Future<bool?> showEmployeeWithdrawSheet({
  required BuildContext context,
  required String balance,
  required EmployeeWithdrawSubmit onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _WithdrawSheet(balance: balance, onSubmit: onSubmit),
  );
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.balance, required this.onSubmit});

  /// الرصيدُ كما قرأته الصفحة. والخادمُ هو الحَكَم إن تغيّر في الأثناء.
  final String balance;
  final EmployeeWithdrawSubmit onSubmit;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _money = EmployeeMoneyForm();

  bool _isSaving = false;

  @override
  void dispose() {
    _money.dispose();
    super.dispose();
  }

  /// الرصيدُ لو حُفظ ما كُتب — على السلاسل لا `double`.
  String? get _after => switch (typedEmployeeAmount(_money.amount.text)) {
    final amount? => subtractDecimals(widget.balance, amount),
    null => null,
  };

  Future<void> _submit() async {
    if (_isSaving) return;

    final needsReceipt = _money.needsReceipt;

    if (needsReceipt) _money.markReceiptMissed();

    if (!(_formKey.currentState?.validate() ?? false) || needsReceipt) return;

    setState(() => _isSaving = true);

    final failure = await widget.onSubmit(_money.draft());

    if (!mounted) return;

    if (failure != null) {
      setState(() => _isSaving = false);
      context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeWalletSheetFrame(
      title: 'سحب',
      formKey: _formKey,
      children: [
        EmployeeMoneyFields(form: _money, incoming: false, ceiling: widget.balance),
        SizedBox(height: 16.h),
        ListenableBuilder(
          listenable: _money.amount,
          builder: (context, _) => WalletBalanceAfter(
            balance: widget.balance,
            after: _after,
            afterLabel: 'الرصيد بعد السحب',
          ),
        ),
        SizedBox(height: 24.h),
        AppButton(
          label: 'سحب',
          icon: AppIcons.fundWithdraw,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
        SizedBox(height: 8.h),
        AppButton.outlined(label: 'إلغاء', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
