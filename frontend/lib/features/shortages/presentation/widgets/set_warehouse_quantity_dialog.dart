import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «حدِّد الكمية من المخزن» — the weight nobody could know when the shortage was declared.
///
/// **Why it is asked here and not when the shortage was written down.** The bags are missing —
/// that is what «ناقص» means — so at the moment somebody declares one there is nothing to put on
/// a scale, and no factor in the catalogue converts a count of bags into a weight. The person who
/// first knows is almost always whoever is standing on this screen about to record a purchase,
/// and sending them to the order screen to unblock their own form was a detour through a screen
/// they had no other reason to open.
///
/// **Until it is stated, every supply is refused** — kilograms cannot be subtracted from a count
/// of bags, and the result would go on to credit the customer's invoice.
///
/// **It does not touch what the customer pays.** The invoice keeps the figure it was cut with;
/// only the warehouse's number is written. That is why this costs `shortages.manage` rather than
/// an order grant.
///
/// A `StatefulWidget` rather than a controller created beside `showDialog` and disposed in
/// `.whenComplete()`: that fires the moment the route pops, while the dialog is still fading out
/// and its field can still be rebuilt. The order payments screen carries the same note, having
/// been caught by exactly that.
Future<String?> showSetWarehouseQuantityDialog({
  required BuildContext context,
  required Shortage shortage,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SetWarehouseQuantityDialog(shortage: shortage),
  );
}

class _SetWarehouseQuantityDialog extends StatefulWidget {
  const _SetWarehouseQuantityDialog({required this.shortage});

  final Shortage shortage;

  @override
  State<_SetWarehouseQuantityDialog> createState() => _SetWarehouseQuantityDialogState();
}

class _SetWarehouseQuantityDialogState extends State<_SetWarehouseQuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(Validators.toWesternDigits(_quantity.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shortage = widget.shortage;
    final stockUnit = shortage.stockUnitLabel ?? '';
    final soldUnit = shortage.unitLabel ?? '';

    return AlertDialog(
      title: const Text('تحديد الكمية من المخزن'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هذا الصنف يُباع بـ$soldUnit ويُخزَّن بـ$stockUnit، ولا تحويل بينهما — '
              'الناقص ${shortage.requiredQuantity.grouped} $soldUnit من الطلبية.',
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 8.h),
            Text(
              'أدخل الكمية التي ستُشترى وتدخل المخزن. لا يمكن تسجيل أي توفير قبلها.',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _quantity,
              label: 'الكمية من المخزن${stockUnit.isEmpty ? '' : ' ($stockUnit)'}',
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Arabic-Indic digits are what the keyboard produces; the same rule every other
              // quantity in this app follows.
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]'))],
              validator: (value) {
                final typed = double.tryParse(Validators.toWesternDigits(value ?? ''));

                // No ceiling: the ordered figure is in the *other* unit, and measuring a weight
                // against it would be the conversion this box exists because nobody can make.
                if (typed == null || typed <= 0) return 'أدخل كمية';

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}
