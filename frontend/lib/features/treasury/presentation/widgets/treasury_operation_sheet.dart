import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/employee_picker_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What records the operation — the dashboard's cubit or the account page's. Null on success.
typedef RecordOperationCallback =
    Future<Failure?> Function({
      required OperationKind kind,
      String? amount,
      int? fromAccountId,
      int? toAccountId,
      int? categoryId,
      int? employeeId,
      String? countedBalance,
      String? notes,
    });

/// One hand operation — إيداع، سحب، مصروف، تحويل، جرد، رصيد افتتاحي. TREASURY-DESIGN §٤.
///
/// **One sheet for all six**, because they differ by which boxes they show and nothing else:
/// money leaving names the account it leaves, a transfer names both, a count asks what was found
/// instead of an amount.
///
/// [account] is the account the person came from, and **it is locked**: opened from «المصرف»,
/// a transfer goes out of the bank and only its destination is asked. [into] puts it on the
/// receiving side instead — repaying a loan *into* it. From the dashboard, with no [account],
/// every side is chosen.
Future<void> showTreasuryOperationSheet({
  required BuildContext context,
  required OperationKind kind,
  required List<TreasuryAccount> accounts,
  required RecordOperationCallback onSubmit,
  TreasuryAccount? account,
  bool into = false,
  String? title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OperationForm(
      kind: kind,
      accounts: accounts,
      account: account,
      into: into,
      title: title,
      onSubmit: onSubmit,
    ),
  );
}

class _OperationForm extends StatefulWidget {
  const _OperationForm({
    required this.kind,
    required this.accounts,
    required this.onSubmit,
    this.account,
    this.into = false,
    this.title,
  });

  final OperationKind kind;
  final List<TreasuryAccount> accounts;
  final TreasuryAccount? account;
  final bool into;
  final String? title;
  final RecordOperationCallback onSubmit;

  @override
  State<_OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<_OperationForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  TreasuryAccount? _from;
  TreasuryAccount? _to;

  /// The account the sheet was opened from — fixed, not one choice among the rest.
  TreasuryAccount? _locked;
  ExpenseCategory? _category;
  AuthUser? _employee;
  List<ExpenseCategory> _categories = const [];
  bool _saving = false;

  OperationKind get _kind => widget.kind;

  /// Opening and count may touch custody — Nawris's opening, a count of what it holds. Every
  /// other operation leaves it alone, and the server says so too.
  ///
  /// A payable opened by hand also takes an expense bought on credit and a transfer — borrowing
  /// from it, repaying into it. A vendor's takes nothing here: its orders and payments move it.
  List<TreasuryAccount> get _choices => [
    for (final account in widget.accounts)
      if (account.isActive &&
          !account.isVendorPayable &&
          (account.isSpendable ||
              _kind == OperationKind.opening ||
              _kind == OperationKind.adjustment ||
              (account.isPayable &&
                  (_kind == OperationKind.expense || _kind == OperationKind.transfer))))
        account,
  ];

  /// The account the figure is about is a debt — its opening and its count are said as what is
  /// owed, and the server turns the sign (§٢٠).
  bool get _aboutDebt => (_to ?? _from)?.isPayable ?? false;

  @override
  void initState() {
    super.initState();

    // The instance from the list, not the one handed in: the dropdown matches by identity, and
    // an account page holds its own copy of the same account.
    final start = [
      for (final account in _choices)
        if (account.id == widget.account?.id) account,
    ].firstOrNull;

    if (start != null) {
      _locked = start;

      if (_kind.takesFrom && !widget.into) {
        _from = start;
      } else {
        _to = start;
      }
    }

    if (_kind == OperationKind.expense) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await sl<GetExpenseCategories>()();

    if (!mounted) return;

    result.fold(
      (failure) => context.showError(failure.message),
      (categories) => setState(() => _categories = categories),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value, {bool allowZero = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(Validators.toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount < 0 || (!allowZero && amount == 0)) return 'المبلغ يجب أن يكون أكبر من صفر';

    return null;
  }

  Future<void> _pickEmployee() async {
    final picked = await showEmployeePicker(context: context);

    if (picked != null && mounted) setState(() => _employee = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_kind == OperationKind.expense &&
        (_category?.requiresEmployee ?? false) &&
        _employee == null) {
      context.showError('هذا التصنيف يتطلب تحديد الموظف');

      return;
    }

    setState(() => _saving = true);

    final figure = Validators.toWesternDigits(_amount.text.trim());
    final notes = _notes.text.trim();
    final isCount = _kind == OperationKind.adjustment;

    final failure = await widget.onSubmit(
      kind: _kind,
      amount: isCount ? null : figure,
      countedBalance: isCount ? figure : null,
      fromAccountId: _from?.id,
      toAccountId: _to?.id,
      categoryId: _category?.id,
      employeeId: _employee?.id,
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message, details: failure.details);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('تم تسجيل «${_kind.label}»');
  }

  Widget _accountPicker({
    required String label,
    required TreasuryAccount? value,
    required ValueChanged<TreasuryAccount?> onChanged,
  }) {
    final locked = _locked;

    // The account the sheet came from is said, not offered.
    if (locked != null && value?.id == locked.id) {
      return InputDecorator(
        key: const ValueKey('locked-account'),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(accountKindIcon(locked.kind)),
          border: const OutlineInputBorder(),
        ),
        child: Text('${locked.name} — ${treasuryBalanceLabel(locked)}'),
      );
    }

    return AppDropdown<TreasuryAccount>(
      value: value,
      // The other side of a transfer is never the locked account itself.
      items: [
        for (final account in _choices)
          if (account.id != locked?.id) account,
      ],
      keyOf: (account) => account.id,
      labelOf: (account) => '${account.name} — ${treasuryBalanceLabel(account)}',
      label: label,
      prefixIcon: AppIcons.treasury,
      onChanged: onChanged,
      validator: (account) => account == null ? '$label مطلوب' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isCount = _kind == OperationKind.adjustment;

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
                widget.title ?? _kind.label,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              if (_kind.takesFrom) ...[
                _accountPicker(
                  label: 'من حساب',
                  value: _from,
                  onChanged: (account) => setState(() => _from = account),
                ),
                SizedBox(height: 16.h),
              ],
              if (!_kind.takesFrom || _kind == OperationKind.transfer) ...[
                _accountPicker(
                  label: _kind == OperationKind.transfer ? 'إلى حساب' : 'الحساب',
                  value: _to,
                  onChanged: (account) => setState(() => _to = account),
                ),
                SizedBox(height: 16.h),
              ],

              if (_kind == OperationKind.expense) ...[
                AppDropdown<ExpenseCategory>(
                  value: _category,
                  items: _categories,
                  keyOf: (category) => category.id,
                  labelOf: (category) => category.name,
                  label: 'التصنيف',
                  prefixIcon: AppIcons.expense,
                  onChanged: (category) => setState(() => _category = category),
                  validator: (category) => category == null ? 'التصنيف مطلوب' : null,
                ),
                SizedBox(height: 16.h),
                if (_category?.requiresEmployee ?? false) ...[
                  AppButton.tonal(
                    label: _employee?.name ?? 'اختيار الموظف',
                    icon: AppIcons.employees,
                    onPressed: _pickEmployee,
                  ),
                  SizedBox(height: 16.h),
                ],
              ],

              AppTextField(
                controller: _amount,
                label: switch ((isCount, _aboutDebt, _kind)) {
                  (true, true, _) => 'المستحق عليه فعلاً',
                  (true, false, _) => 'الرصيد المعدود فعلاً',
                  (false, true, OperationKind.opening) => 'الدَّين يوم الافتتاح',
                  _ => 'المبلغ',
                },
                prefixIcon: isCount ? AppIcons.countBalance : AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: (value) => _validateAmount(value, allowZero: isCount),
              ),
              if (isCount && _to?.balance != null) ...[
                SizedBox(height: 6.h),
                Text(
                  _to!.isPayable
                      ? 'المستحق في النظام الآن ${treasuryMoney(_to!.owed)} — يُسجَّل الفرق وحده'
                      : 'رصيد النظام الآن ${treasuryMoney(_to!.balance!)} — يُسجَّل الفرق وحده',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: _kind.asksReason ? 'السبب' : 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                validator: _kind.needsNotes
                    ? (value) => (value ?? '').trim().isEmpty ? 'السبب مطلوب' : null
                    : null,
              ),
              SizedBox(height: 24.h),

              AppButton(
                label: 'تسجيل ${_kind.label}',
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
