import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef AdjustSubmit = Future<Failure?> Function({
  required String amount,
  required bool credit,
  required String reason,
});

/// «تعديل الرصيد» — زيادةٌ أو نقص، ومبلغ، وسببٌ إجباري. **لا مال يتحرّك**: تصحيحٌ للرصيد يُكتب
/// سطراً في المحفظة وعلى «أرصدة محافظ الزبائن»، ولذلك لا طريقةَ دفعٍ فيها ولا حساب — وهذا ما
/// يفرّقها عن «شحن المحفظة».
///
/// **ورقةٌ من الأسفل لا حوار** بطلب صاحب العمل (٢٠٢٦-١٠-١٧)، على شكل ورقة الشحن أختِها. والرصيدُ
/// بعد التعديل يُحسب وهو يُكتب، فلا يُكتشف نقصٌ أكبرُ من الرصيد برسالة رفضٍ من الخادم.
///
/// تبقى مفتوحةً على رفض الخادم وتُغلق على قبوله. تعود `true` حين حُفظ.
Future<bool?> showAdjustWalletSheet({
  required BuildContext context,
  required String balance,
  required AdjustSubmit onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AdjustSheet(balance: balance, onSubmit: onSubmit),
  );
}

class _AdjustSheet extends StatefulWidget {
  const _AdjustSheet({required this.balance, required this.onSubmit});

  /// الرصيدُ كما قرأته الصفحة — منه يُحسب ما بعد التعديل. والخادمُ هو الحَكَم إن تغيّر في الأثناء.
  final String balance;
  final AdjustSubmit onSubmit;

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  bool _credit = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // الرصيدُ بعده يتبع كلَّ حرف.
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  /// المبلغ بأرقامٍ غربية، أو null ما لم يكن رقماً موجباً.
  String? get _typed {
    final text = Validators.toWesternDigits(_amount.text.trim());
    final value = double.tryParse(text);

    return value != null && value > 0 ? text : null;
  }

  /// الرصيدُ لو حُفظ ما كُتب — على السلاسل لا `double`.
  String? get _after => switch (_typed) {
    final amount? => _credit
        ? addDecimals(widget.balance, amount)
        : subtractDecimals(widget.balance, amount),
    null => null,
  };

  String? _validateAmount(String? value) {
    final text = Validators.toWesternDigits((value ?? '').trim());
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(text);
    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    // النقصُ لا ينزل بالمحفظة تحت الصفر — يقوله الخادم، ويُقال هنا قبل الإرسال.
    if (!_credit && thousandths(text) > thousandths(widget.balance)) {
      return 'في المحفظة ${widget.balance.grouped} د.ل فقط';
    }

    return null;
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final failure = await widget.onSubmit(
      amount: Validators.toWesternDigits(_amount.text.trim()),
      credit: _credit,
      reason: _reason.text.trim(),
    );

    if (!mounted) return;

    if (failure != null) {
      setState(() => _isSaving = false);
      context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
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
                  'تعديل الرصيد',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 20.h),
                // **الاتجاهُ قبل المبلغ**، بعرض الورقة: هو ما يقرّر معنى الرقم الذي يُكتب بعده.
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: const Text('زيادة'), icon: Icon(AppIcons.add)),
                    const ButtonSegment(
                      value: false,
                      label: Text('نقص'),
                      icon: Icon(Icons.remove_rounded),
                    ),
                  ],
                  selected: {_credit},
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  onSelectionChanged: (choice) => setState(() => _credit = choice.first),
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _amount,
                  label: 'المبلغ',
                  prefixIcon: AppIcons.wallet,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                  validator: _validateAmount,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: _reason,
                  label: 'السبب',
                  prefixIcon: AppIcons.notes,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
                ),
                SizedBox(height: 16.h),
                _BalanceAfter(balance: widget.balance, after: _after),
                SizedBox(height: 24.h),
                AppButton(
                  label: _credit ? 'إضافة للرصيد' : 'خصم من الرصيد',
                  icon: _credit ? AppIcons.add : Icons.remove_rounded,
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
                SizedBox(height: 8.h),
                AppButton.outlined(label: 'إلغاء', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// الرصيدُ الحالي، ثم ما بعد التعديل ما إن يُكتب مبلغ. وتحت الصفر بلون الخطأ.
class _BalanceAfter extends StatelessWidget {
  const _BalanceAfter({required this.balance, required this.after});

  final String balance;
  final String? after;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shown = after ?? balance;
    final isBelowZero = shown.startsWith('-');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              after == null ? 'الرصيد الحالي' : 'الرصيد بعد التعديل',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            '${shown.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isBelowZero ? scheme.error : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
