import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_receipt_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما كُتب على ورقة مالٍ عبر الطاولة — **الحقول نفسها في الاتجاهين**، فورقتا الإيداع والسحب تملكان
/// واحداً منه وترسمانه بـ[EmployeeMoneyFields]. حالةُ نموذجٍ لا قاعدةُ عمل: الخادم هو الحَكَم.
class EmployeeMoneyForm extends ChangeNotifier {
  final amount = TextEditingController();
  final reference = TextEditingController();
  final notes = TextEditingController();

  EmployeeWalletMethod method = EmployeeWalletMethod.cash;
  PickedFile? receipt;
  int? accountId;

  bool _receiptWasMissed = false;

  /// الحوالة بلا واصل، بعد أن حاول الحفظ.
  bool get receiptIsMissing => _receiptWasMissed && receipt == null;

  bool get needsReceipt => method.requiresReceipt && receipt == null;

  void chooseMethod(EmployeeWalletMethod value) {
    method = value;
    // حسابٌ اختير للكاش لا يناسب الحوالة، وواصلُ الحوالة لا معنى له مع الكاش.
    accountId = null;
    receipt = null;
    _receiptWasMissed = false;
    notifyListeners();
  }

  void chooseAccount(int? id) {
    accountId = id;
    notifyListeners();
  }

  void attachReceipt(PickedFile? file) {
    receipt = file;
    notifyListeners();
  }

  void markReceiptMissed() {
    _receiptWasMissed = true;
    notifyListeners();
  }

  EmployeeMoneyDraft draft() => EmployeeMoneyDraft(
    amount: Validators.toWesternDigits(amount.text.trim()),
    method: method,
    treasuryAccountId: accountId,
    reference: reference.text,
    notes: notes.text,
    receiptPath: receipt?.path,
    receiptFilename: receipt?.name,
  );

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }
}

/// المبلغ بأرقامٍ غربية، أو null ما لم يكن رقماً موجباً.
String? typedEmployeeAmount(String text) {
  final western = Validators.toWesternDigits(text.trim());
  final value = double.tryParse(western);

  return value != null && value > 0 ? western : null;
}

/// حقل «المبلغ» على أوراق المحفظة. [ceiling] رصيدٌ لا يُتجاوز، ويُقال هنا قبل الإرسال.
class EmployeeAmountField extends StatelessWidget {
  const EmployeeAmountField({
    required this.controller,
    this.ceiling,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String? ceiling;
  final bool autofocus;

  String? _validate(String? value) {
    final text = Validators.toWesternDigits((value ?? '').trim());
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(text);
    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    if (ceiling case final ceiling? when thousandths(text) > thousandths(ceiling)) {
      return 'في المحفظة ${ceiling.grouped} د.ل فقط';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'المبلغ',
      prefixIcon: AppIcons.wallet,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
      validator: _validate,
    );
  }
}

/// حقل «ملاحظات» على أوراق المحفظة.
class EmployeeNotesField extends StatelessWidget {
  const EmployeeNotesField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'ملاحظات',
      prefixIcon: AppIcons.edit,
      maxLines: 2,
      textInputAction: TextInputAction.newline,
      validator: (value) =>
          (value != null && value.trim().length > 1000) ? 'الملاحظات طويلة جداً' : null,
    );
  }
}

/// المبلغ، والطريقة، والحساب، والواصل للحوالة، والمرجع، والملاحظة — بترتيب ورقة «شحن المحفظة».
class EmployeeMoneyFields extends StatelessWidget {
  const EmployeeMoneyFields({required this.form, required this.incoming, this.ceiling, super.key});

  final EmployeeMoneyForm form;

  /// مالٌ داخل: «استُلم في»، وخارج: «دُفع من» — واختيار الحساب نفسه يتبعه.
  final bool incoming;

  /// رصيد المحفظة حين لا يُتجاوز — للسحب.
  final String? ceiling;

  Future<void> _pickReceipt(BuildContext context) async {
    final file = await pickWalletReceipt(context);

    if (file != null) form.attachReceipt(file);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmployeeAmountField(controller: form.amount, ceiling: ceiling, autofocus: true),
          SizedBox(height: 16.h),
          AppDropdown<EmployeeWalletMethod>(
            value: form.method,
            items: EmployeeWalletMethod.values,
            labelOf: (method) => method.label,
            label: 'الطريقة',
            prefixIcon: AppIcons.payment,
            onChanged: (method) {
              if (method != null) form.chooseMethod(method);
            },
          ),
          SizedBox(height: 16.h),
          TreasuryAccountPicker(
            method: form.method.wire,
            incoming: incoming,
            value: form.accountId,
            onChanged: form.chooseAccount,
          ),
          if (form.method.requiresReceipt) ...[
            SizedBox(height: 16.h),
            WalletReceiptRow(
              receipt: form.receipt,
              isMissing: form.receiptIsMissing,
              onPick: () => _pickReceipt(context),
              onClear: () => form.attachReceipt(null),
            ),
          ],
          SizedBox(height: 16.h),
          AppTextField(
            controller: form.reference,
            label: 'رقم المرجع',
            prefixIcon: AppIcons.tag,
            validator: (value) =>
                (value != null && value.trim().length > 100) ? 'رقم المرجع طويل جداً' : null,
          ),
          SizedBox(height: 16.h),
          EmployeeNotesField(controller: form.notes),
        ],
      ),
    );
  }
}
