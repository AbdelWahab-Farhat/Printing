import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/branches/branch_repository.dart';
import 'package:dayaa/features/branches/branches_cubit.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/employee_picker_sheet.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إعدادات الفروع» — INSTANT-ORDERS-PLAN.md §8, §12.
///
/// A branch is an office-pickup city. Here it gets what an instant sale needs from it: whether it
/// sells, the warehouse its stock comes from, the account for each payment method, and who works
/// there. Nothing here touches a past order. The «متأخرة» threshold sits at the top: it is the
/// company's, not one branch's.
class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BranchesCubit>(
      create: (_) => sl<BranchesCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات الفروع')),
        body: BlocConsumer<BranchesCubit, BranchesState>(
          listenWhen: (before, after) => before.saveFailure != after.saveFailure,
          listener: (context, state) {
            if (state.saveFailure case final failure?) context.showError(failure.message);
          },
          builder: (context, state) {
            final list = state.list;

            if (list == null) {
              if (state.failure case final failure?) {
                return Center(child: Text(failure.message, textAlign: TextAlign.center));
              }

              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: context.read<BranchesCubit>().load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  _LateHours(hours: list.lateHours),
                  SizedBox(height: 20.h),
                  if (list.branches.isEmpty)
                    const Text('لا توجد مكاتب استلام — أضف مدينة بنوع «استلام مكتب» أولاً'),
                  for (final branch in list.branches) ...[
                    _BranchCard(branch: branch, isSaving: state.savingId == branch.id),
                    SizedBox(height: 12.h),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LateHours extends StatefulWidget {
  const _LateHours({required this.hours});

  final int hours;

  @override
  State<_LateHours> createState() => _LateHoursState();
}

class _LateHoursState extends State<_LateHours> {
  late final _hours = TextEditingController(text: '${widget.hours}');

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final hours = int.tryParse(Validators.toWesternDigits(_hours.text.trim()));
    if (hours == null || hours < 1) {
      context.showError('أدخل عدد ساعات صحيحاً');

      return;
    }

    final saved = await context.read<BranchesCubit>().saveLateHours(hours);
    if (saved && mounted) context.showSuccess('تم الحفظ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            controller: _hours,
            label: 'الطلب الفوري «متأخر» بعد (ساعة)',
            helperText: 'لا يُلغى أي طلب تلقائياً — تظهر فقط علامة «متأخرة»',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))],
          ),
        ),
        SizedBox(width: 8.w),
        AppButton(label: 'حفظ', expands: false, onPressed: _save),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.isSaving});

  final BranchSettings branch;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final missing = branch.missing;

    return Card(
      child: ListTile(
        title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            branch.isActive ? 'نشط' : 'غير نشط',
            'المخزن: ${branch.warehouse?.name ?? '—'}',
            '${branch.employees.length} موظف',
            if (missing.isNotEmpty) 'ينقصه: ${missing.join('، ')}',
          ].join(' · '),
        ),
        trailing: isSaving
            ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
            : Icon(AppIcons.edit),
        onTap: isSaving ? null : () => _edit(context),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<BranchesCubit>();

    final edited = await showModalBottomSheet<BranchSettings>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BranchSheet(branch: branch),
    );

    if (edited != null && context.mounted) {
      final saved = await cubit.save(edited);
      if (saved && context.mounted) context.showSuccess('تم حفظ إعدادات ${branch.name}');
    }
  }
}

/// One branch's settings, edited as a draft and handed back whole on «حفظ».
class _BranchSheet extends StatefulWidget {
  const _BranchSheet({required this.branch});

  final BranchSettings branch;

  @override
  State<_BranchSheet> createState() => _BranchSheetState();
}

class _BranchSheetState extends State<_BranchSheet> {
  late BranchSettings _draft = widget.branch;

  Future<void> _pickWarehouse() async {
    final warehouse = await showWarehousePicker(context: context);
    if (warehouse != null && mounted) {
      setState(() => _draft = _draft.copyWith(warehouse: (id: warehouse.id, name: warehouse.name)));
    }
  }

  Future<Named?> _pickAccount(AccountKind kind) async {
    final result = await sl<TreasuryRepository>().accounts(activeOnly: true);
    if (!mounted) return null;

    final accounts = result.fold(
      (failure) {
        context.showError(failure.message);

        return const <TreasuryAccount>[];
      },
      (all) => all.accounts.where((a) => a.kind == kind && !a.isDollar).toList(),
    );

    if (accounts.isEmpty || !mounted) return null;

    return showModalBottomSheet<Named>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final account in accounts)
            ListTile(
              title: Text(account.name),
              onTap: () => Navigator.of(context).pop((id: account.id, name: account.name)),
            ),
        ],
      ),
    );
  }

  Future<void> _addEmployee() async {
    final user = await showEmployeePicker(context: context, title: 'إضافة موظف للفرع');
    if (user == null || !mounted || _draft.employees.any((e) => e.id == user.id)) return;

    setState(() => _draft = _draft.copyWith(employees: [..._draft.employees, (id: user.id, name: user.name)]));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.branch.name,
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('نشط'),
            subtitle: const Text('غير النشط لا يقبل طلبات فورية جديدة، وتبقى طلباته السابقة'),
            value: _draft.isActive,
            onChanged: (value) => setState(() => _draft = _draft.copyWith(isActive: value)),
          ),
          _PickTile(
            caption: 'المخزن الافتراضي',
            value: _draft.warehouse?.name,
            onTap: _pickWarehouse,
            onClear: () => setState(() => _draft = _draft.copyWith(clearWarehouse: true)),
          ),
          _PickTile(
            caption: 'حساب الكاش',
            value: _draft.cashAccount?.name,
            onTap: () async {
              final picked = await _pickAccount(AccountKind.cash);
              if (picked != null) setState(() => _draft = _draft.copyWith(cashAccount: picked));
            },
            onClear: () => setState(() => _draft = _draft.copyWith(clearCash: true)),
          ),
          _PickTile(
            caption: 'حساب الحوالة',
            value: _draft.bankTransferAccount?.name,
            onTap: () async {
              final picked = await _pickAccount(AccountKind.bank);
              if (picked != null) setState(() => _draft = _draft.copyWith(bankTransferAccount: picked));
            },
            onClear: () => setState(() => _draft = _draft.copyWith(clearTransfer: true)),
          ),
          _PickTile(
            caption: 'حساب البطاقة',
            value: _draft.bankCardAccount?.name,
            onTap: () async {
              final picked = await _pickAccount(AccountKind.bank);
              if (picked != null) setState(() => _draft = _draft.copyWith(bankCardAccount: picked));
            },
            onClear: () => setState(() => _draft = _draft.copyWith(clearCard: true)),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: Text('الموظفون المصرح لهم', style: context.textTheme.titleSmall)),
              TextButton.icon(onPressed: _addEmployee, icon: Icon(AppIcons.add), label: const Text('إضافة')),
            ],
          ),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final employee in _draft.employees)
                InputChip(
                  label: Text(employee.name),
                  onDeleted: () => setState(
                    () => _draft = _draft.copyWith(
                      employees: _draft.employees.where((e) => e.id != employee.id).toList(),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          AppButton(label: 'حفظ', onPressed: () => Navigator.of(context).pop(_draft)),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({required this.caption, required this.value, required this.onTap, required this.onClear});

  final String caption;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(caption),
      subtitle: Text(value ?? 'غير محدد'),
      onTap: onTap,
      trailing: value == null ? Icon(AppIcons.add) : IconButton(onPressed: onClear, icon: Icon(AppIcons.clear)),
    );
  }
}
