import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/credit_categories_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_money_fields.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_wallet_sheet_frame.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أيُّ الاثنين كتبت الورقة، فتقول الصفحة الجملة التي تناسبه.
enum EmployeeDepositKind { money, credit }

typedef EmployeeMoneySubmit = Future<Failure?> Function(EmployeeMoneyDraft draft);

typedef EmployeeCreditSubmit = Future<Failure?> Function(EmployeeCreditDraft draft);

/// «إيداع» — زرٌّ واحد، والورقة تسأل: مال استلمناه أم مستحق. قرار صاحب العمل س٢.
///
/// **الاثنان شيئان في الدفاتر**: الأول مالٌ دخل حساباً فيُسأل عن طريقته وحسابه، والثاني مصروفٌ على
/// الشركة بلا كاش فيُسأل عن تصنيفه. ومن يملك واحداً منهما لا يرى السؤال.
///
/// اختيارُ «رواتب» يكتب راتب الموظف ويبقى قابلاً للتغيير (س٣)، ومن لا يملك رؤية الرواتب يكتبه
/// بنفسه. تبقى مفتوحةً على رفض الخادم وتُغلق على قبوله، وتعود بما كُتب.
Future<EmployeeDepositKind?> showEmployeeDepositSheet({
  required BuildContext context,
  required bool mayReceiveMoney,
  required bool mayCredit,
  required EmployeeMoneySubmit onMoney,
  required EmployeeCreditSubmit onCredit,
  String? salary,
}) {
  return showModalBottomSheet<EmployeeDepositKind>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) {
      final sheet = _DepositSheet(
        mayReceiveMoney: mayReceiveMoney,
        mayCredit: mayCredit,
        salary: salary,
        onMoney: onMoney,
        onCredit: onCredit,
      );

      return mayCredit
          ? BlocProvider(create: (_) => sl<CreditCategoriesCubit>()..load(), child: sheet)
          : sheet;
    },
  );
}

class _DepositSheet extends StatefulWidget {
  const _DepositSheet({
    required this.mayReceiveMoney,
    required this.mayCredit,
    required this.salary,
    required this.onMoney,
    required this.onCredit,
  });

  final bool mayReceiveMoney;
  final bool mayCredit;
  final String? salary;
  final EmployeeMoneySubmit onMoney;
  final EmployeeCreditSubmit onCredit;

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _formKey = GlobalKey<FormState>();
  final _money = EmployeeMoneyForm();
  final _creditAmount = TextEditingController();
  final _creditNotes = TextEditingController();

  late EmployeeDepositKind _kind = widget.mayReceiveMoney
      ? EmployeeDepositKind.money
      : EmployeeDepositKind.credit;

  ExpenseCategory? _category;
  bool _isSaving = false;

  bool get _isMoney => _kind == EmployeeDepositKind.money;

  @override
  void dispose() {
    _money.dispose();
    _creditAmount.dispose();
    _creditNotes.dispose();
    super.dispose();
  }

  /// **«رواتب» يكتب الراتب، وأيُّ تصنيفٍ آخر يفرّغ المبلغ**: مبلغٌ بقي من تصنيفٍ سابق يُحفظ بلا أن
  /// يراه أحد.
  void _choose(ExpenseCategory? category) {
    setState(() {
      _category = category;
      final salary = widget.salary;

      _creditAmount.text = (category?.isSalary ?? false) && salary != null
          ? trimDecimals(salary)
          : '';
    });
  }

  /// الورقة تبدأ بـ«رواتب»، لأنها ما يُسجَّل كل شهر.
  void _onCategories(BuildContext context, CreditCategoriesState state) {
    if (state case CreditCategoriesLoaded(:final categories) when _category == null) {
      final salary = categories.where((category) => category.isSalary).firstOrNull;

      if (salary != null) _choose(salary);
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final needsReceipt = _isMoney && _money.needsReceipt;

    if (needsReceipt) _money.markReceiptMissed();

    if (!(_formKey.currentState?.validate() ?? false) || needsReceipt) return;

    setState(() => _isSaving = true);

    final failure = _isMoney
        ? await widget.onMoney(_money.draft())
        : await widget.onCredit(
            EmployeeCreditDraft(
              amount: Validators.toWesternDigits(_creditAmount.text.trim()),
              categoryId: _category!.id,
              notes: _creditNotes.text,
            ),
          );

    if (!mounted) return;

    if (failure != null) {
      setState(() => _isSaving = false);
      context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop(_kind);
  }

  @override
  Widget build(BuildContext context) {
    final sheet = EmployeeWalletSheetFrame(
      title: 'إيداع',
      formKey: _formKey,
      children: [
        if (widget.mayReceiveMoney && widget.mayCredit) ...[
          // **السؤالُ قبل الحقول**، بعرض الورقة: هو ما يقرّر أيَّ حقولٍ تُسأل.
          SegmentedButton<EmployeeDepositKind>(
            segments: const [
              ButtonSegment(value: EmployeeDepositKind.money, label: Text('مال استلمناه')),
              ButtonSegment(value: EmployeeDepositKind.credit, label: Text('مستحق')),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (choice) => setState(() => _kind = choice.first),
          ),
          SizedBox(height: 16.h),
        ],
        if (_isMoney)
          EmployeeMoneyFields(form: _money, incoming: true)
        else ...[
          _CategoryField(value: _category, onChanged: _choose),
          SizedBox(height: 16.h),
          EmployeeAmountField(controller: _creditAmount),
          SizedBox(height: 16.h),
          EmployeeNotesField(controller: _creditNotes),
        ],
        SizedBox(height: 24.h),
        AppButton(
          label: _isMoney ? 'إيداع' : 'تسجيل المستحق',
          icon: AppIcons.fundDeposit,
          isLoading: _isSaving,
          onPressed: _submit,
        ),
        SizedBox(height: 8.h),
        AppButton.outlined(label: 'إلغاء', onPressed: () => Navigator.of(context).pop()),
      ],
    );

    return widget.mayCredit
        ? BlocListener<CreditCategoriesCubit, CreditCategoriesState>(
            listener: _onCategories,
            child: sheet,
          )
        : sheet;
  }
}

/// «التصنيف» — القائمة تُسأل من الخادم، وفشلُها يُرسم خطأً بزرّ «إعادة المحاولة» كمنتقي الحساب.
class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.value, required this.onChanged});

  final ExpenseCategory? value;
  final ValueChanged<ExpenseCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCategoriesCubit, CreditCategoriesState>(
      builder: (context, state) => switch (state) {
        CreditCategoriesLoading() => _dropdown(const [], enabled: false),
        CreditCategoriesLoaded(:final categories) => _dropdown(categories),
        CreditCategoriesFailed(:final failure) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dropdown(const [], enabled: false, error: failure.message),
            SizedBox(height: 8.h),
            AppButton.tonal(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: context.read<CreditCategoriesCubit>().load,
            ),
          ],
        ),
      },
    );
  }

  Widget _dropdown(List<ExpenseCategory> categories, {bool enabled = true, String? error}) {
    return AppDropdown<ExpenseCategory>(
      value: value,
      items: categories,
      keyOf: (category) => category.id,
      labelOf: (category) => category.name,
      label: 'التصنيف',
      prefixIcon: AppIcons.salary,
      enabled: enabled,
      errorText: error,
      validator: (category) => category == null ? 'التصنيف مطلوب' : null,
      onChanged: onChanged,
    );
  }
}
