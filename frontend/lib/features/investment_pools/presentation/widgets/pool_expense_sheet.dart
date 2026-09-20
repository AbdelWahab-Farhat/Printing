import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What a cost is, in the five words the business uses for them.
enum _ExpenseKind {
  storage('storage', 'تخزين'),
  transport('transport', 'نقل'),
  shipping('shipping', 'شحن'),
  customs('customs', 'جمارك'),
  other('other', 'أخرى');

  const _ExpenseKind(this.wire, this.label);

  final String wire;
  final String label;

  /// Whether this kind usually arrives **already inside the cost of the goods**.
  ///
  /// Only a warning on the form — the server decides, from whether the cost was typed on a
  /// purchase order and landed into the layers. A person typing «شحن» by hand for a lorry that
  /// already carried its freight is the mistake this line is here to catch **before** the figure
  /// is recorded and then quietly not subtracted.
  bool get isUsuallyLanded =>
      this == _ExpenseKind.shipping || this == _ExpenseKind.customs;
}

/// A cost charged to the صندوق.
///
/// **Charged to a period, not dated into one.** A closed period is immutable, so an invoice
/// bearing last month's date is charged to the period that is open now — keeping its true
/// `incurred_on` and a note saying where it was meant for. Back-dating a closed month would rewrite
/// a division that has already been paid into wallets.
Future<bool> showPoolExpenseSheet({
  required BuildContext context,
  required int poolId,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PoolExpenseForm(poolId: poolId),
  );

  return saved ?? false;
}

class _PoolExpenseForm extends StatefulWidget {
  const _PoolExpenseForm({required this.poolId});

  final int poolId;

  @override
  State<_PoolExpenseForm> createState() => _PoolExpenseFormState();
}

class _PoolExpenseFormState extends State<_PoolExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  _ExpenseKind _kind = _ExpenseKind.storage;
  late DateTime _incurredOn;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _incurredOn = DateTime.now();
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incurredOn,
      firstDate: DateTime(2020),
      // A cost incurred next week has not been incurred.
      lastDate: DateTime.now(),
    );

    if (picked != null) setState(() => _incurredOn = picked);
  }

  String get _incurredOnWire =>
      '${_incurredOn.year.toString().padLeft(4, '0')}-'
      '${_incurredOn.month.toString().padLeft(2, '0')}-'
      '${_incurredOn.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final result = await sl<RecordPoolExpense>()(
      poolId: widget.poolId,
      kind: _kind.wire,
      name: _name.text,
      amount: Validators.toWesternDigits(_amount.text),
      incurredOn: _incurredOnWire,
      notes: _notes.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold((failure) => context.showError(failure.message), (_) {
      Navigator.of(context).pop(true);
      context.showSuccess('سُجّلت المصروفة');
    });
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
                'مصروفة على الصندوق',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'تُخصم من ربح الفترة التي تُسجَّل فيها',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),

              AppDropdown<_ExpenseKind>(
                value: _kind,
                items: _ExpenseKind.values,
                labelOf: (kind) => kind.label,
                label: 'النوع',
                onChanged: (kind) {
                  if (kind == null) return;
                  setState(() => _kind = kind);
                },
              ),

              // **«محسوبة مسبقاً», said before the figure is typed and not after.** §6.2.4 puts
              // this warning in three places; this is the first of them, and the only one that
              // can stop the mistake rather than explain it.
              if (_kind.isUsuallyLanded) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    'إن كان الشحن أو الجمارك مكتوباً على أمر الشراء فهو داخل أصلاً في تكلفة '
                    'البضاعة، ويُسجَّل هنا دون أن يُخصم مرة ثانية. الخصم من عدمه قرار الخادم، '
                    'لا هذه الشاشة.',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ],
              SizedBox(height: 16.h),

              AppTextField(
                controller: _name,
                label: 'البيان',
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.length < 2) return 'اكتب بياناً واضحاً';

                  return null;
                },
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14.r),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الصرف',
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  child: Text(
                    _incurredOnWire,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 6.h, right: 4.w, left: 4.w),
                child: Text(
                  'التاريخ للسجلّ. الخصم يقع على الفترة المفتوحة الآن — الفترة المقفلة لا تُمسّ.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              AppTextField(controller: _notes, label: 'ملاحظات', maxLines: 2),
              SizedBox(height: 20.h),

              AppButton(
                label: 'سجّل المصروفة',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
