import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/orders/models/order.dart';

/// Correcting what is missing from an order — and with it, what the customer pays.
///
/// **Every line is here, short or not.** The set is replaced wholesale on the way out, so a line
/// the sheet did not show could not be cleared; and «أي بند نقص؟» is a question about the order,
/// which means the answer has to be able to move from one line to another. Emptying a box is the
/// gesture for «وصلت الكمية», and it is the one that puts the money back.
///
/// **The arithmetic is on screen as it is typed.** A shortage is not a note any more — it is
/// subtracted from the invoice — so each row says what that line will be charged before anybody
/// presses save. Finding out afterwards, on a total, is finding out from the wrong number.
///
/// Returns line id → what is missing, or null when it was dismissed. Sending it is the caller's
/// job: this is a form, and a form's answer is what the person entered.
Future<Map<int, String?>?> showEditShortagesSheet({
  required BuildContext context,
  required List<OrderItem> items,
}) {
  return showModalBottomSheet<Map<int, String?>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EditShortagesSheet(items: items),
  );
}

class _EditShortagesSheet extends StatefulWidget {
  const _EditShortagesSheet({required this.items});

  final List<OrderItem> items;

  @override
  State<_EditShortagesSheet> createState() => _EditShortagesSheetState();
}

class _EditShortagesSheetState extends State<_EditShortagesSheet> {
  final _formKey = GlobalKey<FormState>();

  /// One controller per line, opened on whatever is recorded against it today.
  late final Map<int, TextEditingController> _missing = {
    for (final item in widget.items)
      item.id: TextEditingController(text: item.hasShortage ? item.shortageQuantity : ''),
  };

  @override
  void dispose() {
    for (final controller in _missing.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      for (final entry in _missing.entries) entry.key: entry.value.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      // The keyboard's height, so the save button is never underneath it.
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
                  'تعديل النواقص',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'الناقص لا يُحاسَب عليه العميل. أفرغ الحقل إذا وصلت الكمية، فيرجع المبلغ.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                for (final item in widget.items) ...[
                  _LineField(
                    item: item,
                    controller: _missing[item.id]!,
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                ],

                AppButton(label: 'حفظ', icon: AppIcons.settled, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line: what was ordered, how much of it is missing, and what that leaves to pay.
class _LineField extends StatelessWidget {
  const _LineField({
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  final OrderItem item;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// What the line will be charged for, given what is in the box right now.
  ///
  /// Null while the box holds something that is not a number — the validator is what says so,
  /// and a red total under a half-typed figure would be shouting at somebody mid-keystroke.
  String? get _billable {
    final ordered = double.tryParse(item.quantity);
    if (ordered == null) return null;

    final text = controller.text.trim();
    final missing = text.isEmpty ? 0.0 : double.tryParse(text);
    if (missing == null || missing < 0 || missing > ordered) return null;

    return (ordered - missing).toStringAsFixed(3);
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final missing = double.tryParse(text);
    if (missing == null) return 'أدخل رقماً';
    if (missing < 0) return 'الناقص لا يكون سالباً';

    final ordered = double.tryParse(item.quantity);
    if (ordered != null && missing > ordered) {
      return 'الناقص أكبر من المطلوب (${item.quantity.grouped})';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final billable = _billable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${item.productName} — ${item.variantLabel}',
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        AppTextField(
          controller: controller,
          label: 'الناقص (${item.pricingUnitLabel})',
          prefixIcon: AppIcons.error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Arabic-Indic digits are what the keyboard produces, so they are allowed through and
          // the server normalises them — the same rule every other quantity here follows.
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]'))],
          helperText: 'المطلوب ${item.quantity.grouped} — اتركه فارغاً إذا لم ينقص شيء',
          validator: _validate,
          onChanged: onChanged,
        ),
        if (billable != null) ...[
          SizedBox(height: 6.h),
          Text(
            'يُحاسَب على ${billable.grouped} ${item.pricingUnitLabel} × ${item.unitPrice.grouped}',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
