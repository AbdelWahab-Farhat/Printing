import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/employee_picker_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef SaveAccountCallback =
    Future<Failure?> Function({
      required String name,
      String? kind,
      bool? isDefault,
      bool? isActive,
      int? holderUserId,
      String? notes,
    });

/// A new account — «مصرف علي»، a second bank, a driver's custody — or an edit of one.
///
/// **The kind is chosen once.** It decides which payments may land in the account, so the edit
/// form shows it and does not offer it. And the default of a kind is replaced, never unset: the
/// switch is offered only to make an account the default.
Future<void> showTreasuryAccountSheet({
  required BuildContext context,
  required SaveAccountCallback onSubmit,
  TreasuryAccount? account,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AccountForm(account: account, onSubmit: onSubmit),
  );
}

class _AccountForm extends StatefulWidget {
  const _AccountForm({required this.onSubmit, this.account});

  final TreasuryAccount? account;
  final SaveAccountCallback onSubmit;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _notes = TextEditingController(text: widget.account?.notes ?? '');

  late AccountKind _kind = widget.account?.kind ?? AccountKind.bank;
  late bool _isDefault = widget.account?.isDefault ?? false;
  late bool _isActive = widget.account?.isActive ?? true;
  AuthUser? _holder;
  bool _saving = false;

  bool get _isNew => widget.account == null;

  static const _kinds = [
    AccountKind.cash,
    AccountKind.bank,
    AccountKind.wallet,
    AccountKind.custody,
    AccountKind.payable,
  ];

  static String _kindLabel(AccountKind kind) => switch (kind) {
    AccountKind.cash => 'خزنة',
    AccountKind.bank => 'مصرف',
    AccountKind.wallet => 'محفظة ليبيانا',
    AccountKind.custody => 'عهدة (مال في يد مندوب أو شركة توصيل)',
    AccountKind.payable => 'التزام — علينا (قرض، إيجار مستحق…)',
    AccountKind.unknown => '—',
  };

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickHolder() async {
    final picked = await showEmployeePicker(context: context, title: 'صاحب الحساب');

    if (picked != null && mounted) setState(() => _holder = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final notes = _notes.text.trim();
    final account = widget.account;

    final failure = await widget.onSubmit(
      name: _name.text.trim(),
      kind: _isNew ? _kind.wire : null,
      // Sent only when it changes something: an unchanged default is not re-asserted.
      isDefault: _isDefault && !(account?.isDefault ?? false) ? true : null,
      isActive: _isNew || _isActive == account?.isActive ? null : _isActive,
      holderUserId: _holder?.id,
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message, details: failure.details);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess(_isNew ? 'تم إنشاء الحساب' : 'تم حفظ الحساب');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final account = widget.account;
    final holderName = _holder?.name ?? account?.holder?.name;
    // Nothing falls back into custody or into a debt.
    final canBeDefault = _kind != AccountKind.custody &&
        _kind != AccountKind.payable &&
        !(account?.isDefault ?? false);
    // A vendor's «علينا» carries the vendor's name and stays open while the vendor does (§٢٠).
    final ofVendor = account?.isVendorPayable ?? false;

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
                _isNew ? 'حساب جديد' : 'تعديل الحساب',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 20.h),

              AppTextField(
                controller: _name,
                label: ofVendor ? 'اسم الحساب (اسم المورد)' : 'اسم الحساب',
                prefixIcon: AppIcons.treasury,
                readOnly: ofVendor,
                validator: (value) => (value ?? '').trim().isEmpty ? 'اسم الحساب مطلوب' : null,
              ),
              SizedBox(height: 16.h),

              if (_isNew)
                AppDropdown<AccountKind>(
                  value: _kind,
                  items: _kinds,
                  labelOf: _kindLabel,
                  iconOf: accountKindIcon,
                  label: 'النوع',
                  onChanged: (kind) {
                    if (kind == null) return;

                    setState(() {
                      _kind = kind;
                      if (kind == AccountKind.custody || kind == AccountKind.payable) {
                        _isDefault = false;
                      }
                    });
                  },
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(accountKindIcon(_kind)),
                  title: Text(account!.kindLabel),
                  subtitle: const Text('نوع الحساب لا يتغيّر بعد إنشائه'),
                ),
              SizedBox(height: 8.h),

              if (!ofVendor) ...[
                AppButton.tonal(
                  label: holderName == null ? 'صاحب الحساب (اختياري)' : 'باسم $holderName',
                  icon: AppIcons.employees,
                  onPressed: _pickHolder,
                ),
                SizedBox(height: 8.h),
              ],

              if (canBeDefault)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  title: const Text('الحساب الافتراضي لنوعه'),
                  subtitle: const Text('تنزل فيه الدفعات حين لا يُختار حساب'),
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
              if (!_isNew && !account!.isDefault && !account.isSystem && !ofVendor)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('مفعّل'),
                  subtitle: const Text('المعطَّل لا يظهر في الاختيار ولا يستقبل عمليات يدوية'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              SizedBox(height: 8.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 24.h),

              AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
