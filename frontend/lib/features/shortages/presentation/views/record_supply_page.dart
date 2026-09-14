import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// What the screen came back with — the shape the cubit's `recordSupply` takes.
class SupplyEntry {
  const SupplyEntry({
    required this.quantity,
    this.amount,
    this.method,
    this.warehouseId,
    this.occurredOn,
    this.notes,
    this.receipt,
  });

  final String quantity;
  final String? amount;
  final String? method;
  final int? warehouseId;
  final String? occurredOn;
  final String? notes;

  /// الواصل, and null on most entries — see [RecordSupplyPage].
  final PickedFile? receipt;
}

/// «تسجيل توفير» — what was bought, what it cost, where it landed, and the paper it came with.
///
/// **A page rather than a sheet, and that was a correction.** Six fields, a picker, an
/// attachment and a keyboard do not fit in a sheet on a phone: the thing scrolled under its own
/// handle while the keyboard ate the button, and a form somebody is reading numbers off an
/// invoice into is not a thing to do in a drawer. Every other form in this app — the order, the
/// نقص itself, a stock movement — is a page, so this one is too.
///
/// **A supply is the goods arriving, not a note beside them.** Posting one writes a purchase
/// arrival onto the chosen shelf at `amount ÷ quantity`, which is what lets the order draw its
/// full quantity at «جاهزة» and what carries the money into the P&L. That is why the warehouse
/// is not optional:
///
/// | `is_stockable` | the form |
/// | --- | --- |
/// | `true` — it names a size, so it has a shelf | the picker is shown and **required** |
/// | `false` — free text, «شريط لاصق عريض» | the picker is **hidden**; sending one is a 422 |
///
/// **The flag is read, never inferred.** Deriving it from the variant id would put a shelf picker
/// in front of a roll of tape.
///
/// **الواصل is optional on every method**, which is the one place this parts from a customer's
/// payment — that one demands a receipt for a حوالة, because a transfer to a customer is proved
/// by the paper they send us. A sack bought from the shop next door often comes with nothing, and
/// refusing the entry for want of a document would push the purchase back onto paper, which is
/// the thing this feature exists to end.
///
/// **«المتبقي بعد هذه العملية» is shown live**, because partial supply is the ordinary case and
/// the whole point is that the user sees they are leaving the shortage open.
///
/// **The quantity box is not pre-filled with the remainder.** `receive_arrival_sheet` argues this
/// at length for shipments and it holds here: pre-filling turns «كم وصل» into «أكّد ما كنا
/// نأمله».
class RecordSupplyPage extends StatefulWidget {
  const RecordSupplyPage({required this.shortage, super.key});

  final Shortage shortage;

  @override
  State<RecordSupplyPage> createState() => _RecordSupplyPageState();
}

class _RecordSupplyPageState extends State<RecordSupplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  Warehouse? _warehouse;
  PickedFile? _receipt;

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
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

  Future<void> _pickWarehouse(FormFieldState<Warehouse> field) async {
    final picked = await showWarehousePicker(context: context);

    if (picked == null) return;

    setState(() => _warehouse = picked);
    field.didChange(picked);
  }

  /// **The camera and the photo library, not only the Files app.** The receipt that actually
  /// turns up is a screenshot of a banking app or a photograph of a hand-written slip, which on
  /// iOS lands in the photo library — a place the Files app cannot see at all. The order's
  /// transition screen learnt this the hard way; see `showAttachmentSheet`.
  Future<void> _pickReceipt() async {
    final source = await showAttachmentSheet(context: context, title: 'إرفاق الواصل');

    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);

    if (!mounted || files.isEmpty) return;

    setState(() => _receipt = files.first);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.pop(
      SupplyEntry(
        quantity: Validators.toWesternDigits(_quantity.text.trim()),
        amount: Validators.toWesternDigits(_amount.text.trim()),
        method: _method.wire,
        // Omitted on a shortage with no shelf. Sending one there is a 422 in its own right.
        warehouseId: widget.shortage.isStockable ? _warehouse?.id : null,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        receipt: _receipt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shortage = widget.shortage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل توفير'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(28.h),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              '${shortage.name} · المتبقي ${shortage.withUnit(shortage.remainingQuantity)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
      // **A scrolling Column, not a ListView.** A `ListView` builds only what is on screen, and
      // a `FormField` that was never built never registers with the `Form` — so on a tall phone
      // the warehouse picker below the fold would be silently skipped by `validate()` and the
      // entry would post with no shelf. Six fields are cheap to build; a rule that applies only
      // when you scroll to it is not a rule.
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              // The whole point of the form: the user sees they are leaving it open.
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
                // **Required, because the endpoint requires it.** The box used to be optional
                // here and `amount` has always been mandatory on the server, so leaving it empty
                // bought a 422 after the button — a refusal met at the field instead.
                validator: (value) {
                  final typed = double.tryParse(Validators.toWesternDigits(value ?? ''));

                  return typed == null || typed <= 0 ? 'أدخل القيمة المدفوعة' : null;
                },
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
              SizedBox(height: 16.h),
              _Receipt(
                picked: _receipt,
                onPick: _pickReceipt,
                onClear: () => setState(() => _receipt = null),
              ),
              // The conditional field, and the one this form exists to get right.
              if (shortage.isStockable) ...[
                SizedBox(height: 16.h),
                FormField<Warehouse>(
                  validator: (_) => _warehouse == null ? 'اختر المخزن' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المخزن',
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'تدخل البضاعة إليه بسعر الشراء',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // The very control the order's transition screen draws for the same
                      // question, so a warehouse is chosen the same way wherever it is asked for.
                      AppButton.tonal(
                        label: _warehouse?.name ?? 'اختيار المخزن',
                        icon: AppIcons.warehouse,
                        onPressed: () => _pickWarehouse(field),
                      ),
                      if (field.errorText case final error?) ...[
                        SizedBox(height: 6.h),
                        Text(
                          error,
                          style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              AppTextField(controller: _notes, label: 'ملاحظات', maxLines: 3),
              SizedBox(height: 24.h),
              AppButton(label: 'تسجيل', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// الواصل — the paper the goods were bought with, when there is one.
///
/// Drawn like the order's own file field: the name of what was picked with a way to drop it, and
/// a button to attach one when nothing has been. «(اختياري)» is on the label rather than in a
/// sentence underneath — the label carries the rule.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.picked, required this.onPick, required this.onClear});

  final PickedFile? picked;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final file = picked;

    // Which glyph sits beside the name. The name is only the client's claim — but so is the file
    // at this point, and the server sniffs the bytes either way.
    final isImage = file != null && !file.name.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الواصل (اختياري)',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10.h),
        if (file != null) ...[
          Row(
            children: [
              Icon(
                isImage ? AppIcons.photos : AppIcons.pdf,
                size: 18.sp,
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.close, size: 18.sp),
                tooltip: 'إزالة الواصل',
                onPressed: onClear,
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        AppButton.tonal(
          label: file == null ? 'اختيار الواصل' : 'تغيير الواصل',
          icon: AppIcons.document,
          onPressed: onPick,
        ),
      ],
    );
  }
}
