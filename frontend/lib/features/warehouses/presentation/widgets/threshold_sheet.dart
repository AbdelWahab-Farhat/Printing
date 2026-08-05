import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';

/// «نبّهني تحت هذا الرقم» — the one thing a balance line accepts a write for.
///
/// Answers with the level to set, or with the empty string to clear it — and with null when the
/// sheet was dismissed, which is not the same as clearing.
Future<String?> showThresholdSheet({
  required BuildContext context,
  required WarehouseStock stock,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ThresholdForm(stock: stock),
  );
}

class _ThresholdForm extends StatefulWidget {
  const _ThresholdForm({required this.stock});

  final WarehouseStock stock;

  @override
  State<_ThresholdForm> createState() => _ThresholdFormState();
}

class _ThresholdFormState extends State<_ThresholdForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _threshold = TextEditingController(
    text: widget.stock.thresholdLabel ?? '',
  );

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.stock.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2.h),
            Text(
              'الرصيد الحالي ${widget.stock.quantityLabel}',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _threshold,
              label: 'حد التنبيه',
              hint: 'اتركه فارغاً لإلغاء التنبيه',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              // Optional on purpose: an empty box is «لا تنبهني», a decision this sheet exists
              // to let somebody take.
              validator: Validators.optional(Validators.decimal(min: 0)),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 20.h),
            AppButton(label: 'حفظ', onPressed: _save),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(_threshold.text.trim());
  }
}
