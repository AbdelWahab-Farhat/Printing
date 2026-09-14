import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the sheet came back with — the shape the cubit's `recordSupply` takes.
class SupplyEntry {
  const SupplyEntry({
    required this.quantity,
    this.amount,
    this.method,
    this.warehouseId,
    this.reference,
    this.occurredOn,
    this.notes,
  });

  final String quantity;
  final String? amount;
  final String? method;
  final int? warehouseId;
  final String? reference;
  final String? occurredOn;
  final String? notes;
}

/// «تسجيل توفير» — what was bought, what it cost, and where it landed.
///
/// **A supply is the goods arriving, not a note beside them.** Posting one writes a purchase
/// arrival onto the chosen shelf at `amount ÷ quantity`, which is what lets the order draw its
/// full quantity at «جاهزة» and what carries the money into the P&L. That is why the warehouse
/// is not optional:
///
/// | `is_stockable` | the sheet |
/// | --- | --- |
/// | `true` — it names a size, so it has a shelf | the picker is shown and **required** |
/// | `false` — free text, «شريط لاصق عريض» | the picker is **hidden**; sending one is a 422 |
///
/// **The flag is read, never inferred.** Deriving it from the variant id would put a shelf picker
/// in front of a roll of tape.
///
/// > Why required rather than optional: the order draws the *full* ordered quantity off the shelf
/// > when it reaches «جاهزة», and nothing about that subtracts the shortage. Sacks that never
/// > reached a warehouse leave the order refused a week later with a message about a balance that
/// > says nothing about the purchase. Asking here is that failure moved to the moment somebody
/// > can still fix it.
///
/// **«المتبقي بعد هذه العملية» is shown live**, because partial supply is the ordinary case and
/// the whole point is that the user sees they are leaving the shortage open.
///
/// **The quantity box is not pre-filled with the remainder.** `receive_arrival_sheet` argues this
/// at length for shipments and it holds here: pre-filling turns «كم وصل» into «أكّد ما كنا
/// نأمله».
class RecordSupplySheet extends StatefulWidget {
  const RecordSupplySheet({required this.shortage, super.key});

  final Shortage shortage;

  static Future<SupplyEntry?> open(BuildContext context, {required Shortage shortage}) {
    return showModalBottomSheet<SupplyEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RecordSupplySheet(shortage: shortage),
    );
  }

  @override
  State<RecordSupplySheet> createState() => _RecordSupplySheetState();
}

class _RecordSupplySheetState extends State<RecordSupplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  Warehouse? _warehouse;

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// What is left after what has been typed — recomputed on every keystroke.
  ///
  /// Null while the box holds something that is not a number, which is most of the time somebody
  /// is halfway through typing one: a line that flickered «—» between digits would be noise.
  String? get _remainderAfter {
    final typed = double.tryParse(Validators.toWesternDigits(_quantity.text));
    final remaining = double.tryParse(widget.shortage.remainingQuantity);

    if (typed == null || remaining == null) return null;

    final left = remaining - typed;

    return left < 0 ? null : left.toStringAsFixed(3);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SupplyEntry(
        quantity: Validators.toWesternDigits(_quantity.text.trim()),
        amount: _amount.text.trim().isEmpty
            ? null
            : Validators.toWesternDigits(_amount.text.trim()),
        method: _method.wire,
        // Omitted on a shortage with no shelf. Sending one there is a 422 in its own right.
        warehouseId: widget.shortage.isStockable ? _warehouse?.id : null,
        reference: _reference.text.trim().isEmpty ? null : _reference.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shortage = widget.shortage;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        16.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تسجيل توفير',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                'المتبقي ${shortage.withUnit(shortage.remainingQuantity)}',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 16.h),
              AppTextField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                label: 'الكمية${shortage.unitLabel == null ? '' : ' (${shortage.unitLabel})'}',
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final typed = double.tryParse(Validators.toWesternDigits(value ?? ''));
                  final remaining = double.tryParse(shortage.remainingQuantity) ?? 0;

                  if (typed == null || typed <= 0) return 'أدخل كمية';

                  // The cap is here so the refusal is met before the request — but the server
                  // checks it again under a lock, so «أكبر من المتبقي» can still arrive: two
                  // clerks can record the last ten kilos at once.
                  if (typed > remaining) return 'أكبر من المتبقي (${remaining.toStringAsFixed(3)})';

                  return null;
                },
              ),
              // The whole point of the sheet: the user sees they are leaving it open.
              if (_remainderAfter case final left?) ...[
                SizedBox(height: 6.h),
                Text(
                  'المتبقي بعد هذه العملية ${shortage.withUnit(left)}',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              SizedBox(height: 12.h),
              AppTextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                label: 'القيمة (د.ل)',
              ),
              SizedBox(height: 12.h),
              // **A picker, never free text** — the same four a customer's payment uses.
              AppDropdown<PaymentMethod>(
                value: _method,
                items: PaymentMethod.selectable,
                labelOf: (method) => method.label,
                label: 'طريقة الدفع',
                onChanged: (method) => setState(() => _method = method ?? _method),
              ),
              // The conditional field, and the one this sheet exists to get right.
              if (shortage.isStockable) ...[
                SizedBox(height: 12.h),
                FormField<Warehouse>(
                  validator: (_) => _warehouse == null ? 'اختر المخزن' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showWarehousePicker(context: context);

                          if (picked != null) {
                            setState(() => _warehouse = picked);
                            field.didChange(picked);
                          }
                        },
                        icon: const Icon(Icons.warehouse_rounded),
                        label: Text(_warehouse?.name ?? 'المخزن'),
                      ),
                      if (field.errorText case final error?) ...[
                        SizedBox(height: 4.h),
                        Text(
                          error,
                          style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              AppTextField(controller: _reference, label: 'رقم العملية'),
              SizedBox(height: 12.h),
              AppTextField(controller: _notes, label: 'ملاحظات', maxLines: 2),
              SizedBox(height: 20.h),
              // Full width, like every action button in this app.
              AppButton(label: 'تسجيل', onPressed: _submit),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
