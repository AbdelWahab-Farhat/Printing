import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أنواعُ المصاريف التي تُحمَّل على الصندوق — مرآةُ `DealExpenseKind` في الخادم.
enum FundExpenseKind {
  shipping('shipping', 'شحن'),
  customs('customs', 'جمارك'),
  transport('transport', 'نقل'),
  storage('storage', 'تخزين'),
  other('other', 'أخرى');

  const FundExpenseKind(this.wire, this.label);

  final String wire;
  final String label;
}

Future<void> showFundExpenseSheet({
  required BuildContext context,
  required InvestmentFundCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FundExpenseForm(cubit: cubit),
  );
}

class _FundExpenseForm extends StatefulWidget {
  const _FundExpenseForm({required this.cubit});

  final InvestmentFundCubit cubit;

  @override
  State<_FundExpenseForm> createState() => _FundExpenseFormState();
}

class _FundExpenseFormState extends State<_FundExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  FundExpenseKind _kind = FundExpenseKind.shipping;
  DateTime _incurredOn = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(Validators.toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  /// **تاريخُ وقوعه هو ما يقرّر فترته**، لا يومَ إدخال ورقته: فاتورةُ جماركٍ مؤرّخةٌ في سبتمبر
  /// تأكل من ربح سبتمبر ولو وصلت المحاسبةَ في أكتوبر.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incurredOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked == null || !mounted) return;

    setState(() => _incurredOn = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final notes = _notes.text.trim();

    final failure = await widget.cubit.recordExpense(
      kind: _kind.wire,
      name: _name.text.trim(),
      amount: Validators.toWesternDigits(_amount.text.trim()),
      incurredOn: _incurredOn.toIso8601String().substring(0, 10),
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('سُجِّل المصروف وخرج من الخزينة');
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
                'مصروف على الصندوق',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              AppDropdown<FundExpenseKind>(
                value: _kind,
                items: FundExpenseKind.values,
                labelOf: (kind) => kind.label,
                label: 'النوع',
                prefixIcon: AppIcons.statusChange,
                onChanged: (kind) {
                  if (kind == null) return;

                  setState(() => _kind = kind);
                },
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _name,
                label: 'البيان',
                prefixIcon: AppIcons.notes,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'البيان مطلوب' : null,
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(AppIcons.statusChange, size: 20.sp, color: scheme.onSurfaceVariant),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'تاريخ المصروف',
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        _incurredOn.toIso8601String().substring(0, 10),
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
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

              AppButton(
                label: 'تسجيل المصروف',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
