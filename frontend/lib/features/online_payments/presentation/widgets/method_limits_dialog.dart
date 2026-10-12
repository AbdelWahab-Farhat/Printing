import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart' show normaliseAmount;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef MethodLimitsSave =
    Future<Failure?> Function({required String daily, required String monthly, required String yearly});

/// حدود طريقةٍ لكل زبون — يومي وشهري وسنوي، بما يصل المحفظة. **الفارغُ «بلا حد»**.
///
/// يبقى مفتوحاً على رفض الخادم ويُغلق على قبوله. المتحكّماتُ تُغلق في `dispose` الحوار نفسه لا بعد
/// أن يعود — حركةُ الإغلاق ما زالت تستعملها.
Future<void> showMethodLimitsDialog({
  required BuildContext context,
  required OnlinePaymentMethodSetting method,
  required MethodLimitsSave onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _LimitsDialog(method: method, onSave: onSave),
  );
}

class _LimitsDialog extends StatefulWidget {
  const _LimitsDialog({required this.method, required this.onSave});

  final OnlinePaymentMethodSetting method;
  final MethodLimitsSave onSave;

  @override
  State<_LimitsDialog> createState() => _LimitsDialogState();
}

class _LimitsDialogState extends State<_LimitsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _daily = TextEditingController(text: _plain(widget.method.dailyLimit));
  late final _monthly = TextEditingController(text: _plain(widget.method.monthlyLimit));
  late final _yearly = TextEditingController(text: _plain(widget.method.yearlyLimit));
  bool _isSaving = false;

  /// «1000.00» يُكتب «1000» — ما يكتبه الموظف.
  static String _plain(String? value) => value == null ? '' : trimDecimals(value);

  @override
  void dispose() {
    _daily.dispose();
    _monthly.dispose();
    _yearly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('حدود ${widget.method.label}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'لكل زبون، بما يصل محفظته. اترك الخانة فارغة لتكون بلا حد',
                style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 16.h),
              _field(_daily, 'الحد اليومي'),
              SizedBox(height: 12.h),
              _field(_monthly, 'الحد الشهري'),
              SizedBox(height: 12.h),
              _field(_yearly, 'الحد السنوي'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2))
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) => AppTextField(
    controller: controller,
    label: label,
    hint: 'بلا حد',
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
    validator: (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return null;

      final amount = double.tryParse(normaliseAmount(text));

      return (amount == null || amount < 1) ? 'دينارٌ على الأقل — أو اتركه فارغاً' : null;
    },
  );

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final failure = await widget.onSave(daily: _daily.text, monthly: _monthly.text, yearly: _yearly.text);

    if (!mounted) return;

    if (failure != null) {
      setState(() => _isSaving = false);
      context.showFailure(failure);

      return;
    }

    Navigator.of(context).pop();
  }
}
