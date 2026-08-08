import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';

/// What a shipment brought.
typedef ReceivedShipment = ({
  Map<int, String> quantities,
  String? invoiceNumber,
  String? notes,
});

/// Booking a shipment in against a purchase order.
///
/// **It opens on what is still owing, one box per line, and every box starts empty.** A
/// shipment that brought two of five sizes is the ordinary case, not the exception — pre-filling
/// each box with the outstanding quantity would turn «what turned up» into «confirm what we
/// hoped for», and the difference between those two is the entire reason this screen exists.
///
/// The remaining quantity is printed beside each box instead, so nobody has to subtract.
///
/// Returns null when the user backs out.
Future<ReceivedShipment?> showReceiveArrivalSheet({
  required BuildContext context,
  required PurchaseOrder order,
}) {
  return showModalBottomSheet<ReceivedShipment>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _ReceiveArrivalSheet(order: order),
  );
}

class _ReceiveArrivalSheet extends StatefulWidget {
  const _ReceiveArrivalSheet({required this.order});

  final PurchaseOrder order;

  @override
  State<_ReceiveArrivalSheet> createState() => _ReceiveArrivalSheetState();
}

class _ReceiveArrivalSheetState extends State<_ReceiveArrivalSheet> {
  final _invoice = TextEditingController();
  final _notes = TextEditingController();

  /// One controller per outstanding line, keyed by product variant — which is what the API
  /// addresses a received line by, not by the line's own id.
  late final Map<int, TextEditingController> _quantities = {
    for (final item in widget.order.outstanding) item.productVariantId: TextEditingController(),
  };

  @override
  void dispose() {
    _invoice.dispose();
    _notes.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final filled = {
      for (final entry in _quantities.entries)
        if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text,
    };

    if (filled.isEmpty) {
      context.showInfo('اكتب الكمية التي وصلت من بند واحد على الأقل');

      return;
    }

    Navigator.of(context).pop((
      quantities: filled,
      invoiceNumber: _invoice.text,
      notes: _notes.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final outstanding = widget.order.outstanding;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
            child: Text(
              'تسجيل شحنة واردة',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Text(
              // Said out loud, because it is the part that surprises people: this writes to the
              // stock ledger the moment it is sent.
              'ما تكتبه هنا يدخل المخزن فوراً — اكتب ما وصل فعلاً، لا ما كان مطلوباً',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              children: [
                for (final item in outstanding) ...[
                  _LineBox(item: item, controller: _quantities[item.productVariantId]!),
                  SizedBox(height: 10.h),
                ],
                SizedBox(height: 6.h),
                AppTextField(
                  controller: _invoice,
                  label: 'رقم الفاتورة (اختياري)',
                  prefixIcon: AppIcons.tag,
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _notes,
                  label: 'ملاحظات (اختياري)',
                  prefixIcon: AppIcons.edit,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: AppButton(
                label: 'تسجيل الشحنة',
                icon: AppIcons.receiveShipment,
                onPressed: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineBox extends StatelessWidget {
  const _LineBox({required this.item, required this.controller});

  final PurchaseOrderItem item;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            // The arithmetic the server already did. A screen that subtracted would be a second
            // opinion about the number that decides whether the shipment is refused.
            'المتبقي ${item.remainingLabel} من ${item.orderedLabel}',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: 8.h),
          AppTextField(
            controller: controller,
            label: 'الكمية التي وصلت',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
          ),
        ],
      ),
    );
  }
}
