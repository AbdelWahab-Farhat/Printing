import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Asking what the vendor charged for one unit of a وسيط line that went past «جاهزة» without a
/// cost. See OUTSOURCED-PRODUCTS.md §6.2.
///
/// **Once, and the sheet says so.** The server takes the figure for a line that never had one
/// and refuses a second — the cost is recognised once, as it would have been at «جاهزة» — so a
/// mistyped number is not something to fix later from here.
///
/// Returns the figure exactly as typed, or null when dismissed. Cleaning the digits belongs
/// beside the API call — see `RecordVendorCost`.
Future<String?> showRecordVendorCostSheet({
  required BuildContext context,
  required OrderItem item,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RecordVendorCostSheet(item: item),
  );
}

class _RecordVendorCostSheet extends StatefulWidget {
  const _RecordVendorCostSheet({required this.item});

  final OrderItem item;

  @override
  State<_RecordVendorCostSheet> createState() => _RecordVendorCostSheetState();
}

class _RecordVendorCostSheetState extends State<_RecordVendorCostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cost = TextEditingController();

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_cost.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final item = widget.item;

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
                  'تسجيل تكلفة المورد',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'وصل هذا البند إلى «جاهزة» دون تكلفة، فلا يظهر ربح الطلبية. '
                  'تُسجَّل مرة واحدة ولا تُعدَّل بعدها.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),
                Text(
                  '${item.productName} — ${item.variantLabel}',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10.h),
                AppTextField(
                  controller: _cost,
                  label: 'تكلفة المورد لل${item.pricingUnitLabel}',
                  prefixIcon: AppIcons.edit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // The same digits the scrap sheet admits, for the same reason it gives.
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.٫]'))],
                  helperText: 'من فاتورة المورد — الكمية ${item.quantity.grouped} ${item.pricingUnitLabel}',
                  validator: _validate,
                ),
                SizedBox(height: 24.h),
                AppButton(label: 'تسجيل التكلفة', icon: AppIcons.activate, onPressed: _submit),
                SizedBox(height: 8.h),
                AppButton.outlined(
                  label: 'إلغاء',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Only the shape; zero is a cost somebody could mean, so only a negative is refused.
  String? _validate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'التكلفة مطلوبة';

    final cost = double.tryParse(Validators.toWesternDigits(text));

    if (cost == null) return 'التكلفة يجب أن تكون رقماً';
    if (cost < 0) return 'التكلفة لا يمكن أن تكون سالبة';

    return null;
  }
}
