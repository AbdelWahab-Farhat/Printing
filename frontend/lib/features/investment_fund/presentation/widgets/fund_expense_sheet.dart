import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
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

  /// الدرج الذي دفع؛ فارغاً يختاره الخادم — نقدُ المسجِّل، وإلا الخزنة.
  int? _accountId;

  /// آخر رفضٍ من الخادم — حقوله تُعلَّق تحت مربّعاتها، وما سواها يقوله توست (RULES §٥).
  Failure? _refusal;

  static const _rendered = {
    'kind',
    'name',
    'amount',
    'incurred_on',
    'treasury_account_id',
    'notes',
  };

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

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final notes = _notes.text.trim();

    final failure = await widget.cubit.recordExpense(
      kind: _kind.wire,
      name: _name.text.trim(),
      amount: Validators.toWesternDigits(_amount.text.trim()),
      incurredOn: _incurredOn.toIso8601String().substring(0, 10),
      notes: notes.isEmpty ? null : notes,
      treasuryAccountId: _accountId,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
      _refusal = failure;
    });

    if (failure != null) {
      if (failure.hasErrorsBeyond(_rendered)) context.showFailure(failure);

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
                errorText: _refusal?.fieldError('kind'),
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
                errorText: _refusal?.fieldError('name'),
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
                errorText: _refusal?.fieldError('amount'),
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
              if (_refusal?.fieldError('incurred_on') case final error?) TreasuryFieldError(error),
              SizedBox(height: 16.h),

              // أيُّ درجٍ دفع. النموذج لا يسأل عن طريقة، فيُعرض كل حسابٍ يُصرف منه، و«تلقائي»
              // يسمّي ما يختاره الخادم لكاشٍ خارج (TREASURY-DESIGN §٧).
              TreasuryAccountPicker(
                method: null,
                incoming: false,
                label: 'دُفع من',
                value: _accountId,
                errorText: _refusal?.fieldError('treasury_account_id'),
                onChanged: (id) => setState(() => _accountId = id),
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                errorText: _refusal?.fieldError('notes'),
              ),
              SizedBox(height: 24.h),

              AppButton(label: 'تسجيل المصروف', isLoading: _saving, onPressed: _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
