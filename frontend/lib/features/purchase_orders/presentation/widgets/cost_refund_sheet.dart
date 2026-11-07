import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «استرداد» — money coming back on a cost paid outside the vendor's bill.
/// Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
///
/// Like [showReverseReceiptSheet], the sheet sends the request itself and stays open until the
/// server agrees, so a refusal lands in front of the person still holding the decision.
///
/// Returns `true` once it went through, and null when the person backed out.
Future<bool?> showCostRefundSheet({
  required BuildContext context,
  required PurchaseOrderAdditionalCost cost,
  required Future<Failure?> Function(String amount, String reason) onConfirm,
}) {
  final account = cost.treasuryAccount?.name ?? 'الحساب الذي دفعها';

  return _show(
    context,
    _CostRefundSheet(
      title: 'استرداد من ${cost.name}',
      confirmLabel: 'استرداد',
      lines: [
        if (cost.isOwedToPayable)
          'يُخصم المبلغ مما علينا لـ$account'
        else
          'يعود المبلغ إلى $account',
        'لا تتغير تكلفة المخزون، ولا ما يستحقه المورد',
      ],
      // Plain, without separators: a comma in a text field reads as a decimal point.
      maxAmount: trimDecimals(cost.refundableAmount ?? '0'),
      onConfirm: onConfirm,
    ),
  );
}

/// Taking back a refund recorded in error. Same sheet, the reason alone.
Future<bool?> showReverseCostRefundSheet({
  required BuildContext context,
  required PurchaseOrderAdditionalCost cost,
  required PurchaseOrderCostRefund refund,
  required Future<Failure?> Function(String reason) onConfirm,
}) {
  return _show(
    context,
    _CostRefundSheet(
      title: 'التراجع عن الاسترداد',
      confirmLabel: 'التراجع عن الاسترداد',
      lines: [
        'يعود ${refund.amountLabel} د.ل مصروفاً على ${cost.name}',
        'يبقى الاسترداد في السجل مؤشَّراً عليه بأنه أُلغي',
      ],
      onConfirm: (_, reason) => onConfirm(reason),
    ),
  );
}

Future<bool?> _show(BuildContext context, Widget sheet) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Off: it holds a typed reason and, after a refusal, the server's only explanation.
    isDismissible: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => sheet,
  );
}

class _CostRefundSheet extends StatefulWidget {
  const _CostRefundSheet({
    required this.title,
    required this.confirmLabel,
    required this.lines,
    required this.onConfirm,
    this.maxAmount,
  });

  final String title;
  final String confirmLabel;

  /// What will happen, said before it is asked.
  final List<String> lines;

  /// The most that may come back. Null asks for no amount at all.
  final String? maxAmount;
  final Future<Failure?> Function(String amount, String reason) onConfirm;

  @override
  State<_CostRefundSheet> createState() => _CostRefundSheetState();
}

class _CostRefundSheetState extends State<_CostRefundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late final _amount = TextEditingController(text: widget.maxAmount);

  bool _isSending = false;
  Failure? _failure;

  @override
  void dispose() {
    _reason.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSending = true;
      _failure = null;
    });

    final failure = await widget.onConfirm(_amount.text, _reason.text);

    if (!mounted) return;

    if (failure != null) {
      setState(() {
        _isSending = false;
        _failure = failure;
      });

      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12.h),
                for (final line in widget.lines) ...[
                  Text(
                    line,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
                SizedBox(height: 10.h),
                if (widget.maxAmount != null) ...[
                  AppTextField(
                    key: const Key('cost-refund-amount'),
                    controller: _amount,
                    label: 'المبلغ المسترد (د.ل)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9٠-٩۰-۹.,]'),
                      ),
                    ],
                    validator: _validateAmount,
                  ),
                  SizedBox(height: 12.h),
                ],
                AppTextField(
                  key: const Key('cost-refund-reason'),
                  controller: _reason,
                  label: widget.maxAmount == null
                      ? 'سبب التراجع'
                      : 'سبب الاسترداد',
                  prefixIcon: AppIcons.edit,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: _validateReason,
                ),
                if (_failure case final failure?) ...[
                  SizedBox(height: 16.h),
                  Container(
                    key: const Key('cost-refund-refusal'),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      [failure.message, ?failure.details].join('\n'),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                AppButton(
                  key: const Key('cost-refund-confirm'),
                  label: widget.confirmLabel,
                  icon: AppIcons.undo,
                  isLoading: _isSending,
                  onPressed: _submit,
                ),
                SizedBox(height: 8.h),
                AppButton.outlined(
                  label: 'رجوع',
                  onPressed: _isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final text = Validators.toWesternDigits(
      (value ?? '').trim(),
    ).replaceAll(',', '.');
    final parsed = double.tryParse(text);

    if (parsed == null) return 'أدخل المبلغ';
    if (parsed <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';
    if (parsed > (double.tryParse(widget.maxAmount ?? '') ?? 0)) {
      return 'أقصى ما يمكن استرداده ${widget.maxAmount}';
    }

    return null;
  }

  String? _validateReason(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'السبب مطلوب';
    if (text.length < 3) return 'السبب قصير جداً';
    if (text.length > 500) return 'السبب طويل جداً';

    return null;
  }
}
