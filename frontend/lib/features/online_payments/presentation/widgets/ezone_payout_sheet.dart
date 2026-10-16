import 'package:dartz/dartz.dart' show Either;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef EzonePayoutSubmit =
    Future<Either<Failure, EzonePayout>> Function({
      required String amount,
      String? kept,
      int? toAccountId,
      String? reference,
      required String clientToken,
    });

/// «تحويل Ezone إلى المصرف» (الخطوة ٦) — ما وصل المصرفَ من EzonePay، وما احتفظت به عند التحويل.
///
/// يُكتب تحويلاً من «Ezone» إلى الحساب، وما احتفظت به مصروفاً «عمولة الدفع الإلكتروني». **الرمزُ
/// يبقى حتى ينجح**، فإعادةُ إرسالٍ ضاع جوابُه تعود بالتحويل الأول ولا تكتب ثانياً. تعود بما قاله
/// الخادم حين سُجّل.
Future<EzonePayout?> showEzonePayoutSheet({
  required BuildContext context,
  required String ezoneBalance,
  required EzonePayoutSubmit onSubmit,
}) {
  return showModalBottomSheet<EzonePayout>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PayoutSheet(ezoneBalance: ezoneBalance, onSubmit: onSubmit),
  );
}

class _PayoutSheet extends StatefulWidget {
  const _PayoutSheet({required this.ezoneBalance, required this.onSubmit});

  final String ezoneBalance;
  final EzonePayoutSubmit onSubmit;

  @override
  State<_PayoutSheet> createState() => _PayoutSheetState();
}

class _PayoutSheetState extends State<_PayoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _kept = TextEditingController();
  final _reference = TextEditingController();

  /// يُولَّد مرّةً للورقة، ويبقى عبر المحاولات حتى ينجح أحدها.
  final String _token = uuidV4();

  int? _accountId;
  bool _isSaving = false;

  @override
  void dispose() {
    _amount.dispose();
    _kept.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'تحويل Ezone إلى المصرف',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'في «Ezone» الآن ${widget.ezoneBalance.grouped} د.ل — سجّل ما وصل المصرف كما في كشفه',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  controller: _amount,
                  label: 'المبلغ الواصل',
                  prefixIcon: AppIcons.bank,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                  validator: (value) => _validateAmount(value, required: true),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _kept,
                  label: 'احتفظت به EzonePay عند التحويل',
                  helperText: 'إن خصمت شيئاً فوق عمولات الشحن — يُسجَّل مصروفاً',
                  prefixIcon: AppIcons.expense,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                  validator: (value) => _validateAmount(value, required: false),
                ),
                SizedBox(height: 16.h),
                TreasuryAccountPicker(
                  method: 'bank_transfer',
                  incoming: true,
                  label: 'وصل إلى',
                  value: _accountId,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _reference,
                  label: 'رقم المرجع',
                  prefixIcon: AppIcons.tag,
                  validator: (value) =>
                      (value != null && value.trim().length > 100) ? 'رقم المرجع طويل جداً' : null,
                ),
                SizedBox(height: 24.h),
                AppButton(
                  label: 'تسجيل التحويل',
                  icon: AppIcons.transfer,
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                SizedBox(height: 8.h),
                AppButton.outlined(label: 'إلغاء', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateAmount(String? value, {required bool required}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return required ? 'المبلغ مطلوب' : null;

    final amount = double.tryParse(_western(text));
    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (required ? amount <= 0 : amount < 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

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

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final result = await widget.onSubmit(
      amount: _amount.text,
      kept: _kept.text,
      toAccountId: _accountId,
      reference: _reference.text,
      clientToken: _token,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSaving = false);
        context.showFailure(failure);
      },
      (payout) => Navigator.of(context).pop(payout),
    );
  }
}
