import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef AdjustSubmit = Future<Failure?> Function({
  required String amount,
  required bool credit,
  required String reason,
});

/// «تعديل الرصيد» — زيادةٌ أو نقص، ومبلغ، وسببٌ إجباري. **لا مال يتحرّك**: تصحيحٌ للرصيد يُكتب
/// سطراً في المحفظة وعلى «أرصدة محافظ الزبائن». النقصُ لا ينزل بالمحفظة تحت الصفر — يقوله الخادم.
///
/// يبقى مفتوحاً على رفض الخادم ويُغلق على قبوله. تعود `true` حين حُفظ.
Future<bool?> showAdjustWalletDialog({required BuildContext context, required AdjustSubmit onSubmit}) {
  return showDialog<bool>(context: context, builder: (_) => _AdjustDialog(onSubmit: onSubmit));
}

/// Stateful so its controllers are disposed after the exit animation — see `_WriteOffDialog`.
class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({required this.onSubmit});

  final AdjustSubmit onSubmit;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();

  bool _credit = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final failure = await widget.onSubmit(
      amount: _amount.text.trim(),
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
    return AlertDialog(
      title: const Text('تعديل الرصيد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilterOptionChip(
                  label: 'زيادة',
                  isSelected: _credit,
                  onTap: () => setState(() => _credit = true),
                ),
                SizedBox(width: 8.w),
                FilterOptionChip(
                  label: 'نقص',
                  isSelected: !_credit,
                  onTap: () => setState(() => _credit = false),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _amount,
              label: 'المبلغ',
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
              validator: (value) {
                final text = (value ?? '').trim().replaceAll('٫', '.');
                if (text.isEmpty) return 'المبلغ مطلوب';

                return text == '0' || text == '٠' ? 'المبلغ يجب أن يكون أكبر من صفر' : null;
              },
            ),
            SizedBox(height: 12.h),
            AppTextField(
              controller: _reason,
              label: 'السبب',
              maxLines: 2,
              validator: (value) => (value ?? '').trim().length < 3 ? 'السبب مطلوب' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_credit ? 'إضافة للرصيد' : 'خصم من الرصيد'),
        ),
      ],
    );
  }
}
