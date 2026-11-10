import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/uuid.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/expense_categories_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/employee_picker_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما يسجّل العملية — Cubit اللوحة أو Cubit صفحة الحساب. null عند النجاح.
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
      String? clientToken,
      // An expense out of a dollar account: dinars per dollar (USD-ACCOUNTS §٨).
      String? rate,
    });

/// عمليةٌ يدوية — إيداع، سحب، مصروف، تحويل، جرد، رصيد افتتاحي. TREASURY-DESIGN §٤.
///
/// **نموذجٌ واحد للستّ**، لأنها لا تختلف إلا في الحقول التي تُظهرها: المال الخارج يسمّي الحساب
/// الذي يخرج منه، والتحويل يسمّي الاثنين، والجرد يسأل عمّا وُجد بدل المبلغ.
///
/// [account] الحسابُ الذي جاء منه صاحبه، **وهو مقفل**: مفتوحاً من «المصرف» يخرج التحويل من
/// المصرف ولا يُسأل إلا عن وجهته. و[into] يضعه في الجهة المستقبِلة — سدادُ قرضٍ *إليه*. ومن
/// اللوحة، بلا [account]، تُختار الجهتان.
Future<void> showTreasuryOperationSheet({
  required BuildContext context,
  required OperationKind kind,
  required List<TreasuryAccount> accounts,
  required RecordOperationCallback onSubmit,
  TreasuryAccount? account,
  bool into = false,
  String? title,
  // «سعر النظام» — what an expense out of a dollar account opens its rate on.
  String? systemRate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) {
      final form = _OperationForm(
        kind: kind,
        accounts: accounts,
        account: account,
        into: into,
        title: title,
        onSubmit: onSubmit,
        systemRate: systemRate,
      );

      // تصنيفات المصروف من Cubit — والنماذج الأخرى لا تسأل عنها شيئاً.
      if (kind != OperationKind.expense) return form;

      return BlocProvider(
        create: (_) => ExpenseCategoriesCubit(getCategories: sl())..load(),
        child: form,
      );
    },
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
    this.systemRate,
  });

  final OperationKind kind;
  final List<TreasuryAccount> accounts;
  final TreasuryAccount? account;
  final bool into;
  final String? title;
  final RecordOperationCallback onSubmit;
  final String? systemRate;

  @override
  State<_OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<_OperationForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  /// «سعر الصرف» of an expense out of a dollar account — what «المصاريف» counts it at in dinars
  /// (USD-ACCOUNTS §٨). Opens on «سعر النظام» when the screen knows it.
  late final _rate = TextEditingController(text: trimDecimals(widget.systemRate ?? ''));

  /// مفتاح هذا النموذج: يولَّد مرةً ويُعاد مع كل محاولة، فإن وصلت الأولى وانقطع ردّها لم تُكتب
  /// العملية مرتين (`client_token`).
  final _clientToken = uuidV4();

  TreasuryAccount? _from;
  TreasuryAccount? _to;

  /// The account the sheet was opened from — fixed, not one choice among the rest.
  TreasuryAccount? _locked;
  ExpenseCategory? _category;
  AuthUser? _employee;
  bool _saving = false;

  /// آخر رفضٍ من الخادم — حقوله تُعلَّق تحت مربّعاتها.
  Failure? _refusal;

  OperationKind get _kind => widget.kind;

  bool get _isCount => _kind == OperationKind.adjustment;

  /// المفاتيح التي يعرضها هذا النموذج تحت حقوله؛ وما سواها يقوله توست.
  Set<String> get _rendered => {
    'amount',
    'rate',
    'counted_balance',
    'from_account_id',
    'to_account_id',
    'category_id',
    'employee_id',
    'notes',
  };

  /// الافتتاح والجرد قد يمسّان العهدة — افتتاح النورس، وجرد ما فيه. وما سواهما يتركها، والخادم
  /// يقول ذلك أيضاً.
  ///
  /// و«علينا» المفتوح باليد يأخذ أيضاً مصروفاً بالآجل وتحويلاً — اقتراضاً منه وسداداً إليه. أما
  /// «علينا» المورد فلا يأخذ شيئاً هنا: أوامرُه ودفعاتُه تحرّكه. ولا «علينا» النظام: المحافظُ
  /// والطلبياتُ تحرّكه.
  List<TreasuryAccount> get _choices => [
    for (final account in widget.accounts)
      if (account.isActive &&
          !account.isVendorPayable &&
          !account.isSystemPayable &&
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

  /// On a dollar account every figure is dollars, and the box says so.
  String get _inDollars => ((_from ?? _to)?.isDollar ?? false) ? ' بالدولار' : '';

  /// An expense out of dollars, which is asked the rate it is counted at in dinars.
  bool get _dollarExpense => _kind == OperationKind.expense && (_from?.isDollar ?? false);

  /// What the expense comes to in dinars at the typed rate — said under the rate, not sent: the
  /// server works it out the same way and keeps it.
  String? get _inDinars {
    final amount = double.tryParse(Validators.toWesternDigits(_amount.text.trim()));
    final rate = double.tryParse(
      Validators.toWesternDigits(_rate.text.trim()).replaceAll(',', '.'),
    );

    if (amount == null || rate == null || amount <= 0 || rate <= 0) return null;

    return (amount * rate).toStringAsFixed(2);
  }

  String? _validateRate(String? value) {
    final rate = double.tryParse(
      Validators.toWesternDigits((value ?? '').trim()).replaceAll(',', '.'),
    );

    return rate == null || rate <= 0 ? 'اكتب سعر الصرف' : null;
  }

  @override
  void initState() {
    super.initState();

    // نسخةُ القائمة لا النسخة الممرَّرة: صفحة الحساب تحمل نسختها من الحساب نفسه.
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
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    _rate.dispose();
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

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final figure = Validators.toWesternDigits(_amount.text.trim());
    final notes = _notes.text.trim();

    final failure = await widget.onSubmit(
      kind: _kind,
      amount: _isCount ? null : figure,
      countedBalance: _isCount ? figure : null,
      fromAccountId: _from?.id,
      toAccountId: _to?.id,
      categoryId: _category?.id,
      employeeId: _employee?.id,
      notes: notes.isEmpty ? null : notes,
      clientToken: _clientToken,
      rate: _dollarExpense
          ? Validators.toWesternDigits(_rate.text.trim()).replaceAll(',', '.')
          : null,
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
    context.showSuccess('تم تسجيل «${_kind.label}»');
  }

  Widget _accountPicker({
    required String label,
    required TreasuryAccount? value,
    required String errorKey,
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

    // A transfer moves one amount, so its other side is in the same currency — across
    // currencies it is «صرف عملة» (USD-ACCOUNTS §٣).
    final other = identical(value, _from) ? _to : _from;
    final anchor = _kind == OperationKind.transfer ? (locked ?? other) : null;

    return AppDropdown<TreasuryAccount>(
      value: value,
      // The other side of a transfer is never the locked account itself.
      items: [
        for (final account in _choices)
          if (account.id != locked?.id && (anchor == null || account.currency == anchor.currency))
            account,
      ],
      keyOf: (account) => account.id,
      labelOf: (account) => '${account.name} — ${treasuryBalanceLabel(account)}',
      label: label,
      prefixIcon: AppIcons.treasury,
      errorText: _refusal?.fieldError(errorKey),
      onChanged: onChanged,
      validator: (account) => account == null ? '$label مطلوب' : null,
    );
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
                widget.title ?? _kind.label,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              if (_kind.takesFrom) ...[
                _accountPicker(
                  label: 'من حساب',
                  value: _from,
                  errorKey: 'from_account_id',
                  onChanged: (account) => setState(() => _from = account),
                ),
                SizedBox(height: 16.h),
              ],
              if (!_kind.takesFrom || _kind == OperationKind.transfer) ...[
                _accountPicker(
                  label: _kind == OperationKind.transfer ? 'إلى حساب' : 'الحساب',
                  value: _to,
                  errorKey: 'to_account_id',
                  onChanged: (account) => setState(() => _to = account),
                ),
                SizedBox(height: 16.h),
              ],

              if (_kind == OperationKind.expense) ...[
                _Categories(
                  value: _category,
                  errorText: _refusal?.fieldError('category_id'),
                  onChanged: (category) => setState(() => _category = category),
                ),
                SizedBox(height: 16.h),
                if (_category?.requiresEmployee ?? false) ...[
                  AppButton.tonal(
                    label: _employee?.name ?? 'اختيار الموظف',
                    icon: AppIcons.employees,
                    onPressed: _pickEmployee,
                  ),
                  if (_refusal?.fieldError('employee_id') case final error?)
                    TreasuryFieldError(error),
                  SizedBox(height: 16.h),
                ],
              ],

              AppTextField(
                controller: _amount,
                label: switch ((_isCount, _aboutDebt, _kind)) {
                  (true, true, _) => 'المستحق عليه فعلاً',
                  (true, false, _) => 'الرصيد المعدود فعلاً$_inDollars',
                  (false, true, OperationKind.opening) => 'الدَّين يوم الافتتاح',
                  _ => 'المبلغ$_inDollars',
                },
                prefixIcon: _isCount ? AppIcons.countBalance : AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                errorText: _refusal?.fieldError(_isCount ? 'counted_balance' : 'amount'),
                validator: (value) => _validateAmount(value, allowZero: _isCount),
                onChanged: _dollarExpense ? (_) => setState(() {}) : null,
              ),
              SizedBox(height: 16.h),

              // Out of dollars: the rate «المصاريف» counts it at, and what that comes to.
              if (_dollarExpense) ...[
                AppTextField(
                  key: const ValueKey('expense-rate'),
                  controller: _rate,
                  label: 'سعر الصرف (دينار لكل دولار)',
                  prefixIcon: AppIcons.exchange,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫,]'))],
                  errorText: _refusal?.fieldError('rate'),
                  validator: _validateRate,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 4.h),
                Text(
                  _inDinars == null
                      ? 'يُحسب المصروف بالدينار بهذا السعر في «المصاريف»'
                      : 'يُحسب في «المصاريف» بـ ${treasuryMoney(_inDinars!)}',
                  key: const ValueKey('expense-in-dinars'),
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 16.h),
              ],

              AppTextField(
                controller: _notes,
                label: _kind.asksReason ? 'السبب' : 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                errorText: _refusal?.fieldError('notes'),
                validator: _kind.needsNotes
                    ? (value) => (value ?? '').trim().isEmpty ? 'السبب مطلوب' : null
                    : null,
              ),
              SizedBox(height: 24.h),

              AppButton(label: 'تسجيل ${_kind.label}', isLoading: _saving, onPressed: _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// «التصنيف» — من [ExpenseCategoriesCubit]، وفشلُه يُقال تحت الحقل بزرّ «إعادة المحاولة».
class _Categories extends StatelessWidget {
  const _Categories({required this.value, required this.errorText, required this.onChanged});

  final ExpenseCategory? value;
  final String? errorText;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseCategoriesCubit, ExpenseCategoriesState>(
      builder: (context, state) {
        final dropdown = AppDropdown<ExpenseCategory>(
          value: value,
          items: switch (state) {
            ExpenseCategoriesLoaded(:final categories) => categories,
            _ => const [],
          },
          keyOf: (category) => category.id,
          labelOf: (category) => category.name,
          label: 'التصنيف',
          prefixIcon: AppIcons.expense,
          enabled: state is ExpenseCategoriesLoaded,
          errorText: switch (state) {
            ExpenseCategoriesFailed(:final failure) => failure.message,
            _ => errorText,
          },
          onChanged: onChanged,
          validator: (category) => category == null ? 'التصنيف مطلوب' : null,
        );

        if (state is! ExpenseCategoriesFailed) return dropdown;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dropdown,
            SizedBox(height: 8.h),
            AppButton.tonal(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: context.read<ExpenseCategoriesCubit>().load,
            ),
          ],
        );
      },
    );
  }
}
