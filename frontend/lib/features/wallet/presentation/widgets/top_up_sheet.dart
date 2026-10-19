import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/orders/models/receipt_rules.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the sheet sends.
typedef TopUpSubmit =
    Future<Failure?> Function({
      required String amount,
      required TopUpMethod method,
      int? treasuryAccountId,
      String? reference,
      String? notes,
      PickedFile? receipt,
    });

/// «شحن المحفظة» في المكتب — المبلغ، والطريقة، والحساب الذي نزل فيه المال، والواصل للحوالة.
///
/// **على شكل ورقة «تسجيل دفعة»**: الحقول نفسها بالترتيب نفسه، والواصلُ يظهر لحظة تُختار «حوالة».
/// ولا سطرَ تحت العنوان ولا تحت الحقول (٢٠٢٦-١٠-١٧): صفُّ الواصل يقول وحده إنه مطلوب.
/// تبقى مفتوحةً على رفض الخادم وتُغلق على قبوله — فلا يُعاد ملء شيء. تعود `true` حين شُحنت.
Future<bool?> showTopUpSheet({
  required BuildContext context,
  required TopUpSubmit onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TopUpSheet(onSubmit: onSubmit),
  );
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.onSubmit});

  final TopUpSubmit onSubmit;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  TopUpMethod _method = TopUpMethod.cash;
  PickedFile? _receipt;
  int? _accountId;
  bool _receiptWasMissed = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
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
                  'شحن المحفظة',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  controller: _amount,
                  label: 'المبلغ',
                  prefixIcon: AppIcons.wallet,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                  validator: _validateAmount,
                ),
                SizedBox(height: 16.h),
                AppDropdown<TopUpMethod>(
                  value: _method,
                  items: TopUpMethod.values,
                  labelOf: (method) => method.label,
                  label: 'طريقة الشحن',
                  prefixIcon: AppIcons.payment,
                  onChanged: (method) {
                    if (method == null) return;

                    setState(() {
                      _method = method;
                      _receiptWasMissed = false;
                      // حسابٌ اختير للكاش لا يناسب الحوالة.
                      _accountId = null;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                TreasuryAccountPicker(
                  method: _method.wire,
                  incoming: true,
                  value: _accountId,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
                if (_method.requiresReceipt) ...[
                  SizedBox(height: 16.h),
                  _ReceiptRow(
                    receipt: _receipt,
                    isMissing: _receiptWasMissed && _receipt == null,
                    onPick: _pickReceipt,
                    onClear: () => setState(() => _receipt = null),
                  ),
                ],
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _reference,
                  label: 'رقم المرجع',
                  prefixIcon: AppIcons.tag,
                  validator: (value) =>
                      (value != null && value.trim().length > 100) ? 'رقم المرجع طويل جداً' : null,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _notes,
                  label: 'ملاحظات',
                  prefixIcon: AppIcons.edit,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  validator: (value) =>
                      (value != null && value.trim().length > 1000) ? 'الملاحظات طويلة جداً' : null,
                ),
                SizedBox(height: 24.h),
                AppButton(
                  label: 'شحن المحفظة',
                  icon: AppIcons.walletTopUp,
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

  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(Validators.toWesternDigits(text));
    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  Future<void> _pickReceipt() async {
    final source = await showAttachmentSheet(context: context, title: 'إرفاق الواصل');

    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(source);

    if (!mounted || picked.isEmpty) return;

    final file = picked.first;
    final refusal = ReceiptRules.reject(file);

    if (refusal != null) {
      context.showError(refusal);

      return;
    }

    setState(() {
      _receipt = file;
      _receiptWasMissed = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final needsReceipt = _method.requiresReceipt && _receipt == null;

    if (needsReceipt) setState(() => _receiptWasMissed = true);

    if (!(_formKey.currentState?.validate() ?? false) || needsReceipt) return;

    setState(() => _isSaving = true);

    final failure = await widget.onSubmit(
      amount: Validators.toWesternDigits(_amount.text.trim()),
      method: _method,
      treasuryAccountId: _accountId,
      reference: _reference.text,
      notes: _notes.text,
      receipt: _receipt,
    );

    if (!mounted) return;

    if (failure != null) {
      setState(() => _isSaving = false);
      context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop(true);
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.receipt,
    required this.isMissing,
    required this.onPick,
    required this.onClear,
  });

  final PickedFile? receipt;
  final bool isMissing;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final file = receipt;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isMissing ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        border: isMissing ? Border.all(color: scheme.error) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.document, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  file?.name ?? 'الواصل — مطلوب مع الحوالة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isMissing ? scheme.onErrorContainer : null,
                    fontWeight: file != null ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (file != null)
                IconButton(
                  icon: Icon(AppIcons.close, size: 18.sp),
                  tooltip: 'إزالة الواصل',
                  onPressed: onClear,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          AppButton.tonal(
            label: file == null ? 'اختيار الواصل' : 'تغيير الواصل',
            icon: AppIcons.document,
            height: 42.h,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
