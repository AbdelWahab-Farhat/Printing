import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The three movements a person may record against an investor's money: money in, money out,
/// profit out. Each of them is cash crossing the counter, which is why every one of them carries
/// a payment method.
///
/// **`profit` and `loss` are deliberately absent.** An earning is written by the order that
/// produced it, and offering it on a form would be offering somebody the chance to invent one —
/// after which the deal screen and the orders behind it would say two different things.
///
/// **`allocation` — «تمويل صفقة» — is absent for the same kind of reason.** Money enters a deal
/// by funding the purchase order it was raised for, where the goods, their cost and the
/// investor's share are all in front of the person doing it — `FundPurchaseOrder`. Typed
/// here as a bare amount against a deal code, it was the one movement on this form with nothing
/// on the other side of it to check against.
enum WalletAction {
  deposit('deposit', 'إيداع رأس مال'),
  withdrawal('withdrawal', 'سحب رأس مال'),
  profitWithdrawal('profit_withdrawal', 'سحب أرباح');

  const WalletAction(this.wire, this.label);

  final String wire;
  final String label;
}

Future<void> showWalletEntrySheet({
  required BuildContext context,
  required InvestorDetailCubit cubit,
  required Investor investor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _WalletEntryForm(cubit: cubit, investor: investor),
  );
}

class _WalletEntryForm extends StatefulWidget {
  const _WalletEntryForm({required this.cubit, required this.investor});

  final InvestorDetailCubit cubit;
  final Investor investor;

  @override
  State<_WalletEntryForm> createState() => _WalletEntryFormState();
}

class _WalletEntryFormState extends State<_WalletEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  WalletAction _action = WalletAction.deposit;
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// **Whether the money is actually there is the server's answer**, because it depends on rows
  /// this screen may not have seen — a colleague recording a withdrawal at the same counter one
  /// second earlier. This checks the shape and nothing else.
  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    // The app's own conversion, not a copy of it. A local copy handled ٠-٩ and dropped ٫ — the
    // Arabic decimal separator — so «١٢٫٥», which the field's own formatter deliberately admits,
    // was refused here as «not a number» one layer before the send path could convert it.
    final amount = double.tryParse(Validators.toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final failure = await widget.cubit.record(
      investorId: widget.investor.id,
      type: _action.wire,
      amount: _amount.text,
      method: _method.wire,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      // The server's own words. It refuses a withdrawal above the balance and a payout of profit
      // a running deal has not released, and its message says which — restating either rule here
      // would be a second copy to keep in step.
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل الحركة');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
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
                'حركة مالية',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.investor.name,
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 20.h),

              // The app's own dropdown, generic over the model — see [AppDropdown]. It draws to
              // match the fields around it, which a hand-rolled picker per form never does for
              // long.
              AppDropdown<WalletAction>(
                value: _action,
                items: WalletAction.values,
                labelOf: (action) => action.label,
                label: 'نوع الحركة',
                prefixIcon: AppIcons.statusChange,
                onChanged: (action) {
                  if (action == null) return;

                  setState(() => _action = action);
                },
              ),
              SizedBox(height: 16.h),

              AppDropdown<PaymentMethod>(
                value: _method,
                // `selectable` rather than `values`: the unknown case exists so an entry written
                // by a newer server still renders, and it is never a person's choice.
                items: PaymentMethod.selectable,
                labelOf: (method) => method.label,
                label: 'طريقة الدفع',
                prefixIcon: AppIcons.payment,
                onChanged: (method) {
                  if (method == null) return;

                  setState(() => _method = method);
                },
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // **The formatter is the real defence against a comma.** `1,500` is fifteen
                // hundred to most people who type it and one and a half to some, and no amount
                // of cleverness downstream can tell which — so the character never gets typed.
                // Arabic-Indic digits *are* allowed, because that is what an Arabic keyboard
                // produces, and they are converted on the way to the API.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
              SizedBox(height: 24.h),

              AppButton(label: 'تسجيل', isLoading: _saving, onPressed: _saving ? null : _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
