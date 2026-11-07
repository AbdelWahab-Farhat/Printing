import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ما ردّت به [showAmountSheet]. و[amount] الفارغ قرارٌ: `showModalBottomSheet` يردّ `null` عند الإغلاق،
/// والإغلاق تراجعٌ لا جواب.
@immutable
class AmountChoice {
  const AmountChoice(this.amount);

  /// بأرقامٍ غربية كما يقرؤها الخادم. و`null` حين تُرك الحقل فارغاً.
  final String? amount;
}

/// ورقة مبلغٍ واحد اختياري: أجر التذكرة، والسعر المقترح، والقبول.
///
/// [initial] يُكتب في الحقل بلا أصفاره، ويبقى قابلاً للتغيير والتفريغ.
Future<AmountChoice?> showAmountSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String confirmLabel,
  String? description,
  String? initial,
}) {
  return showModalBottomSheet<AmountChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AmountSheet(
      title: title,
      label: label,
      confirmLabel: confirmLabel,
      description: description,
      initial: initial,
    ),
  );
}

/// حقل مبلغٍ اختياري: يقبل الفراغ، ويقبل الصفر، ويرفض ما ليس رقماً.
class OptionalAmountField extends StatelessWidget {
  const OptionalAmountField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  static String? _validate(String? value) {
    final text = Validators.toWesternDigits((value ?? '').trim());

    if (text.isEmpty) return null;

    return double.tryParse(text) == null ? 'المبلغ يجب أن يكون رقماً' : null;
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      prefixIcon: AppIcons.wallet,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
      validator: _validate,
    );
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.description,
    this.initial,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String? description;
  final String? initial;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: switch (widget.initial) {
      final initial? => trimDecimals(initial),
      null => '',
    },
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final text = Validators.toWesternDigits(_amount.text.trim());

    Navigator.of(context).pop(AmountChoice(text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (widget.description case final description?) ...[
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                OptionalAmountField(controller: _amount, label: widget.label, autofocus: true),
                SizedBox(height: 16.h),
                AppButton(label: widget.confirmLabel, onPressed: _confirm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
