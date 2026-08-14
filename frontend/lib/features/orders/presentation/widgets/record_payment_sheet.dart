import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Which direction the money is going.
///
/// One sheet for both, because the form is the same one: an amount, a method, a reference and a
/// note. Only the words and the defaults change, and two near-identical files would be two
/// places to fix the receipt rule in.
enum PaymentDirection {
  /// Money in.
  incoming,

  /// Money genuinely handed back — **not** the way to fix a mistyped entry. That is a reversal,
  /// which is a different act with a different permission and lives on the entry itself.
  outgoing,
}

/// What the sheet came back with, or null when it was dismissed.
class PaymentDraft {
  const PaymentDraft({
    required this.direction,
    required this.amount,
    required this.method,
    this.reference,
    this.notes,
    this.receipt,
  });

  final PaymentDirection direction;

  /// Exactly what was typed. Normalising it is `normaliseAmount`'s job on the way to the API —
  /// this is a form, and a form's answer is what the person entered.
  final String amount;

  final PaymentMethod method;
  final String? reference;
  final String? notes;

  /// The receipt PDF, when one was attached.
  final PickedFile? receipt;
}

/// Taking money, or giving it back.
///
/// **The amount opens pre-filled with the whole outstanding balance.** Paying the order off is
/// what most of these are, so the common case is now one tap; anything else is a number typed
/// over a selected field. A blank box made the commonest entry the one that cost the most work.
///
/// **The receipt field appears the moment «حوالة» is chosen, not when the server refuses.** A
/// transfer cannot be recorded without its PDF — that is the rule on the API and a constraint in
/// the database — and being told at the counter that the paper is missing is the point of it.
/// Finding out after pressing save is a second trip for the customer.
Future<PaymentDraft?> showRecordPaymentSheet({
  required BuildContext context,
  required PaymentDirection direction,
  required String remainingAmount,
  required String paidAmount,
}) {
  return showModalBottomSheet<PaymentDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RecordPaymentSheet(
      direction: direction,
      remainingAmount: remainingAmount,
      paidAmount: paidAmount,
    ),
  );
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({
    required this.direction,
    required this.remainingAmount,
    required this.paidAmount,
  });

  final PaymentDirection direction;
  final String remainingAmount;
  final String paidAmount;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  PickedFile? _receipt;

  /// Set only after a save was attempted, so the missing-receipt message appears when somebody
  /// tries to submit rather than the instant they pick «حوالة».
  bool _receiptWasMissed = false;

  bool get _isIncoming => widget.direction == PaymentDirection.incoming;

  /// What the field opens on.
  ///
  /// **The whole balance for a payment, the whole paid amount for a refund** — each is the
  /// ceiling the server would enforce anyway, and each is what the entry usually is. A negative
  /// remaining (an overpaid order) has nothing sensible to prefill, so it opens blank.
  String get _defaultAmount {
    final suggested = _isIncoming ? widget.remainingAmount : widget.paidAmount;

    return suggested.startsWith('-') || suggested == '0.00' ? '' : suggested;
  }

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _defaultAmount);
  }

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
      // The keyboard's height, so the save button is never underneath it — this form is filled
      // in with one hand at a counter.
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
                  _isIncoming ? 'تسجيل دفعة' : 'ردّ مبلغ للعميل',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  _isIncoming
                      ? 'المتبقي على الطلبية ${widget.remainingAmount.grouped}'
                      : 'الردّ حركة نقدية حقيقية — لتصحيح دفعة مسجّلة بالخطأ استعمل «إلغاء الدفعة»',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                AppTextField(
                  controller: _amount,
                  label: _isIncoming ? 'المبلغ المدفوع' : 'المبلغ المردود',
                  prefixIcon: AppIcons.payment,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // **The formatter is the real defence against a comma.** `1,500` is fifteen
                  // hundred to most people who type it and one and a half to some, and no
                  // amount of cleverness downstream can tell which — so the character never
                  // gets typed. Arabic-Indic digits *are* allowed, because that is what an
                  // Arabic keyboard produces, and they are converted on the way to the API.
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                  helperText: _isIncoming
                      ? 'مبدئياً كامل المتبقي — عدّله إن دفع أقل'
                      : 'لا يتجاوز المدفوع فعلاً (${widget.paidAmount.grouped})',
                  validator: _validateAmount,
                ),
                SizedBox(height: 16.h),

                // The app's own dropdown, generic over the model — see [AppDropdown]. It draws
                // to match the fields around it, which a hand-rolled picker per form never does
                // for long.
                AppDropdown<PaymentMethod>(
                  value: _method,
                  // `selectable` rather than `values`: the unknown case exists so an entry
                  // written by a newer server still renders, and it is never a person's choice.
                  items: PaymentMethod.selectable,
                  labelOf: (method) => method.label,
                  label: _isIncoming ? 'طريقة الدفع' : 'طريقة الردّ',
                  prefixIcon: AppIcons.payment,
                  helperText: _method.requiresReceipt ? 'الحوالة تتطلب إرفاق الواصل' : null,
                  onChanged: (method) {
                    if (method == null) return;

                    setState(() {
                      _method = method;
                      _receiptWasMissed = false;
                    });
                  },
                ),

                // Only for the method that demands it. The server refuses a transfer without a
                // receipt and so does a database CHECK; this is the copy that asks *before* the
                // rest of the form is filled in.
                if (_method.requiresReceipt) ...[
                  SizedBox(height: 16.h),
                  _ReceiptField(
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
                  hint: _method.referenceHint,
                  prefixIcon: AppIcons.tag,
                  validator: (value) =>
                      (value != null && value.trim().length > 100) ? 'رقم المرجع طويل جداً' : null,
                ),

                SizedBox(height: 16.h),
                AppTextField(
                  controller: _notes,
                  label: 'ملاحظات',
                  prefixIcon: AppIcons.edit,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: (value) =>
                      (value != null && value.trim().length > 1000) ? 'الملاحظات طويلة جداً' : null,
                ),

                SizedBox(height: 24.h),
                AppButton(
                  label: _isIncoming ? 'تسجيل الدفعة' : 'تسجيل الردّ',
                  icon: _isIncoming ? AppIcons.payment : AppIcons.refund,
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

  /// Only the shape is checked here.
  ///
  /// **Whether it exceeds what is owed is the server's answer**, because it depends on entries
  /// this screen may not have seen — a colleague taking a payment at the same counter one second
  /// earlier.
  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(_toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  /// Enough of a conversion to *validate* the shape. The real one lives beside the API call —
  /// see `normaliseAmount` — and this deliberately does not call it, because a validator that
  /// silently rewrote the field would change a number under somebody's finger.
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

  /// The document browser only, and filtered to PDF.
  ///
  /// **No photo library and no camera**, unlike a customer's artwork. A receipt is a document a
  /// bank produces, and offering the camera would invite a blurred phone picture as proof of
  /// payment — which is the thing this file exists to prevent. The server accepts nothing but a
  /// PDF anyway, so the other two rows would be taps that end in a 422.
  Future<void> _pickReceipt() async {
    final picked = await sl<AttachmentPicker>().pick(AttachmentSource.documents);

    if (!mounted || picked.isEmpty) return;

    final file = picked.first;

    // The picker is filtered to PDF, but a filter is a courtesy and this is money: a file that
    // is not one is refused here rather than after an upload the person waited through.
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      context.showError('الواصل يجب أن يكون ملف PDF');

      return;
    }

    setState(() {
      _receipt = file;
      _receiptWasMissed = false;
    });
  }

  void _submit() {
    final needsReceipt = _method.requiresReceipt && _receipt == null;

    // Set before validating, so a form that is otherwise fine still lights up the file field
    // instead of appearing to do nothing.
    if (needsReceipt) setState(() => _receiptWasMissed = true);

    if (!(_formKey.currentState?.validate() ?? false) || needsReceipt) return;

    Navigator.of(context).pop(
      PaymentDraft(
        direction: widget.direction,
        amount: _amount.text,
        method: _method,
        reference: _reference.text,
        notes: _notes.text,
        receipt: _receipt,
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({
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
              Icon(AppIcons.pdf, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  file?.name ?? 'الواصل (PDF) — مطلوب مع الحوالة',
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

extension on PaymentMethod {
  /// A hint for the reference field, in the words of the method that was chosen.
  String get referenceHint => switch (this) {
    PaymentMethod.bankTransfer => 'رقم الحوالة',
    PaymentMethod.bankCard => 'رقم العملية',
    PaymentMethod.libyana => 'رقم العملية',
    PaymentMethod.cash || PaymentMethod.unknown => 'رقم الإيصال، إن وُجد',
  };
}
