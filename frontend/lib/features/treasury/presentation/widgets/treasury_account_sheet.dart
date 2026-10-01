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

/// ما يحفظ الحساب — Cubit اللوحة أو صفحة الحساب أو الإعدادات. null عند النجاح.
///
/// [notes] الفارغة (`''`) تمسح الملاحظات على الخادم، والغائبة (`null`) تتركها كما هي.
typedef SaveAccountCallback =
    Future<Failure?> Function({
      required String name,
      String? kind,
      bool? isDefault,
      bool? isActive,
      int? holderUserId,
      String? notes,
    });

/// حسابٌ جديد — «مصرف علي»، مصرفٌ ثانٍ، عهدةُ مندوب — أو تعديلُ قائم.
///
/// **النوع يُختار مرةً واحدة.** هو ما يقرّر أيُّ الدفعات تنزل في الحساب، فنموذج التعديل يُظهره
/// ولا يعرضه للتغيير. **وافتراضيُّ النوع يُستبدل ولا يُنزع**: المفتاح يُعرض لجعل الحساب
/// افتراضياً فقط.
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

  /// آخر رفضٍ من الخادم — حقوله تُعلَّق تحت مربّعاتها.
  Failure? _refusal;

  static const _rendered = {
    'name',
    'kind',
    'holder_user_id',
    'is_default',
    'is_active',
    'notes',
  };

  bool get _isNew => widget.account == null;

  static const _kinds = [
    AccountKind.cash,
    AccountKind.bank,
    AccountKind.wallet,
    AccountKind.custody,
  ];

  static String _kindLabel(AccountKind kind) => switch (kind) {
    AccountKind.cash => 'خزنة',
    AccountKind.bank => 'مصرف',
    AccountKind.wallet => 'محفظة ليبيانا',
    AccountKind.custody => 'عهدة (مال في يد مندوب أو شركة توصيل)',
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

    setState(() {
      _saving = true;
      _refusal = null;
    });

    final notes = _notes.text.trim();
    final account = widget.account;

    // ملاحظاتٌ كانت ومُسحت: غيابُ المفتاح كان يُبقيها، فتُرسل فارغةً صراحةً — والخادم يقرأ
    // الفارغة مسحاً (`AccountData::hasNotes`).
    final cleared = !_isNew && notes.isEmpty && (account?.notes ?? '').trim().isNotEmpty;

    final failure = await widget.onSubmit(
      name: _name.text.trim(),
      kind: _isNew ? _kind.wire : null,
      // يُرسل حين يغيّر شيئاً فقط: افتراضيٌّ لم يتغيّر لا يُعاد تأكيده.
      isDefault: _isDefault && !(account?.isDefault ?? false) ? true : null,
      isActive: _isNew || _isActive == account?.isActive ? null : _isActive,
      holderUserId: _holder?.id,
      notes: notes.isEmpty ? (cleared ? '' : null) : notes,
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
    context.showSuccess(_isNew ? 'تم إنشاء الحساب' : 'تم حفظ الحساب');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final account = widget.account;
    final holderName = _holder?.name ?? account?.holder?.name;
    final canBeDefault = _kind != AccountKind.custody && !(account?.isDefault ?? false);

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
                label: 'اسم الحساب',
                prefixIcon: AppIcons.treasury,
                errorText: _refusal?.fieldError('name'),
                validator: (value) => (value ?? '').trim().isEmpty ? 'اسم الحساب مطلوب' : null,
              ),
              SizedBox(height: 16.h),

              // النوع على التعديل معروضٌ لا معروضٌ للتغيير — الحقل نفسه معطّلاً، بلا سطرٍ يشرح.
              if (_isNew)
                AppDropdown<AccountKind>(
                  value: _kind,
                  items: _kinds,
                  labelOf: _kindLabel,
                  iconOf: accountKindIcon,
                  label: 'النوع',
                  errorText: _refusal?.fieldError('kind'),
                  onChanged: (kind) {
                    if (kind == null) return;

                    setState(() {
                      _kind = kind;
                      if (kind == AccountKind.custody) _isDefault = false;
                    });
                  },
                )
              else
                AppDropdown<AccountKind>(
                  value: _kind,
                  items: [_kind],
                  labelOf: (_) => account!.kindLabel,
                  iconOf: accountKindIcon,
                  label: 'النوع',
                  enabled: false,
                  onChanged: (_) {},
                ),
              SizedBox(height: 16.h),

              AppButton.tonal(
                label: holderName == null ? 'صاحب الحساب (اختياري)' : 'باسم $holderName',
                icon: AppIcons.employees,
                onPressed: _pickHolder,
              ),
              if (_refusal?.fieldError('holder_user_id') case final error?)
                TreasuryFieldError(error),
              SizedBox(height: 8.h),

              if (canBeDefault) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isDefault,
                  title: const Text('الحساب الافتراضي لنوعه'),
                  onChanged: (value) => setState(() => _isDefault = value),
                ),
                if (_refusal?.fieldError('is_default') case final error?)
                  TreasuryFieldError(error),
              ],
              if (!_isNew && !account!.isDefault && !account.isSystem) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  title: const Text('مفعّل'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                if (_refusal?.fieldError('is_active') case final error?)
                  TreasuryFieldError(error),
              ],
              SizedBox(height: 8.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                errorText: _refusal?.fieldError('notes'),
              ),
              SizedBox(height: 24.h),

              AppButton(label: 'حفظ', isLoading: _saving, onPressed: _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
