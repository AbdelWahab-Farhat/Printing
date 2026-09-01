import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_picker_sheet.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_picker_sheet.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Raising a purchase order, or correcting one.
///
/// **Every line carries a cost, and it has to be typed.** What we pay a supplier is not in any
/// catalogue — the tiers there price what we *sell* — so there is nothing to quote against and
/// no sensible default to prefill. The server requires it on every line and the form asks for it
/// beside the quantity.
///
/// **It asks for the line's total, not a unit price.** That is what a supplier's invoice is
/// written in — «٤ لفّات بـ ٧٥ د.ل» — and it is what the server stores; it works the per-unit
/// figure out itself. A box asking for the unit price would have buyers dividing on paper before
/// they could fill the form in.
///
/// **A line names a shelf, and a shelf appears at most once.** The picker offers «الأصناف
/// المخزنية» rather than a product and then a size: «كيس شحن سادة 25*35» and «كيس شحن مطبوع
/// 25*35» are one pile, so asking «أي منتج؟» then «أي مقاس؟» asked two questions to reach a thing
/// with one name — and let a buyer raise two lines for one heap at two prices. The server now
/// refuses that outright with a unique index, so the form refuses it first, in a sentence.
///
/// **Delivery and customs are a second list, not a line.** They are charged on the order rather
/// than on any one size, so the form collects them separately and the server spreads them across
/// the lines in proportion to what each is worth.
///
/// **The supplier is chosen once and then fixed while editing.** The server accepts a different
/// `vendor_id` on an update, but an order that changed hands would leave its received lines
/// pointing at a shipment from somebody else — so the picker is offered while raising one and
/// locked afterwards.
class PurchaseOrderFormPage extends StatelessWidget {
  const PurchaseOrderFormPage({this.order, this.vendor, super.key});

  /// Null raises a new order; anything else corrects that one.
  final PurchaseOrder? order;

  /// Pre-chosen when the form was opened from a supplier's own screen.
  final Vendor? vendor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SavePurchaseOrderCubit>(
      create: (_) => sl<SavePurchaseOrderCubit>(),
      child: _PurchaseOrderFormView(order: order, vendor: vendor),
    );
  }
}

class _PurchaseOrderFormView extends StatefulWidget {
  const _PurchaseOrderFormView({this.order, this.vendor});

  final PurchaseOrder? order;
  final Vendor? vendor;

  @override
  State<_PurchaseOrderFormView> createState() => _PurchaseOrderFormViewState();
}

class _PurchaseOrderFormViewState extends State<_PurchaseOrderFormView> {
  final _formKey = GlobalKey<FormState>();

  late final _notes = TextEditingController(text: widget.order?.notes ?? '');

  /// Who it is raised against, and where the goods will land. Held as id-and-name so the tile
  /// can say what was chosen without the picker's whole record.
  late ({int id, String name})? _vendor = _seedVendor();
  late ({int id, String name})? _warehouse = _seedWarehouse();

  late String _orderDate = widget.order?.orderDate ?? _today;
  late String? _expectedDate = widget.order?.expectedDate;

  late final List<_LineDraft> _lines = [
    for (final item in widget.order?.items ?? const <PurchaseOrderItem>[])
      _LineDraft(
        id: item.id,
        stockItemId: item.stockItemId,
        title: item.title,
        code: item.itemCode,
        // Snapshotted on the line when it was raised, not looked up again: a shelf whose unit was
        // re-declared since must not silently re-label the quantity already agreed with the
        // vendor.
        unit: item.lineUnit,
        quantity: item.orderedLabel,
        // Empty for a line raised before cost tracking, so the field opens asking rather than
        // opening on a zero somebody would have to notice was never typed.
        //
        // The *base* total, not the landed one: this box is the figure the buyer typed, and
        // seeding it with the line's share of delivery folded in would add that share again on
        // every save.
        baseTotalCost: item.baseTotalCost == null
            ? ''
            : trimDecimals(item.baseTotalCost!),
      ),
  ];

  /// The order's delivery, unloading and customs, as they stand.
  ///
  /// **Seeded from what the server has, and sent back in full every save.** The set is replaced
  /// wholesale, so a cost left out of this list is deleted — which is exactly what removing a
  /// row on screen should mean, and exactly what must not happen by accident.
  late final List<_AdditionalCostDraft> _additionalCosts = [
    for (final cost
        in widget.order?.additionalCosts ??
            const <PurchaseOrderAdditionalCost>[])
      _AdditionalCostDraft(
        id: cost.id,
        name: cost.name,
        amount: trimDecimals(cost.amount),
      ),
  ];

  bool get _isEditing => widget.order != null;

  /// Locked once the order exists — see the note on the page.
  bool get _mayPickVendor => !_isEditing;

  ({int id, String name})? _seedVendor() {
    if (widget.vendor case final vendor?) {
      return (id: vendor.id, name: vendor.name);
    }

    final order = widget.order;
    if (order == null) return null;

    return (id: order.vendorId, name: order.vendorName);
  }

  ({int id, String name})? _seedWarehouse() {
    final order = widget.order;
    if (order?.warehouseId case final id?) {
      return (id: id, name: order!.warehouseName);
    }

    return null;
  }

  static String get _today {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    for (final cost in _additionalCosts) {
      cost.dispose();
    }
    super.dispose();
  }

  Future<void> _pickVendor() async {
    final picked = await showVendorPicker(context: context);
    if (picked == null) return;

    setState(() => _vendor = (id: picked.id, name: picked.name));
  }

  Future<void> _pickWarehouse() async {
    final picked = await showWarehousePicker(context: context);
    if (picked == null) return;

    setState(() => _warehouse = (id: picked.id, name: picked.name));
  }

  Future<void> _pickDate({required bool isExpected}) async {
    final initial = DateTime.tryParse(
      (isExpected ? _expectedDate : _orderDate) ?? _orderDate,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      // A purchase order is dated within a working lifetime, not within a century.
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );

    if (picked == null) return;

    final value =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    setState(() {
      if (isExpected) {
        _expectedDate = value;
      } else {
        _orderDate = value;
      }
    });
  }

  /// Opens the shelf picker and adds what came back.
  ///
  /// **Opened wide, with no size to narrow it by.** The picker takes a width and a height when
  /// there is a variant to hint from; a purchase order starts from the supplier, not from a
  /// product, so there is nothing to pre-narrow with and it opens on everything.
  Future<void> _addLine() async {
    final picked = await showStockItemPicker(context: context);
    if (picked == null) return;

    // Refused here as well as by the server, and with a sentence rather than a 422: the API's
    // `distinct` rule — and now a unique index behind it — points at `items.2.stock_item_id`,
    // which is not a thing on screen. It matters more than it used to: two products at one size
    // are now one shelf, so a buyer adding «سادة» and «مطبوع» is naming one line twice without
    // anything on the screen looking like a duplicate.
    if (_lines.any((line) => line.stockItemId == picked.id)) {
      if (!mounted) return;
      context.showInfo('هذه المادة مضافة بالفعل');

      return;
    }

    setState(() {
      _lines.add(
        _LineDraft(
          stockItemId: picked.id,
          // The server's own composition, drawn as sent — never rebuilt from the name and the
          // two dimensions.
          title: picked.displayName,
          code: picked.code,
          // The **shelf's** unit, so the two boxes below say what they want before anything is
          // typed into them. `CreatePurchaseOrder` force-fills the line from the same field when
          // it saves, so the form asks in the word the order will report in.
          unit: PurchaseLineUnit(picked.unitLabel),
          quantity: '',
          baseTotalCost: '',
        ),
      );
    });
  }

  void _removeLine(_LineDraft line) {
    setState(() => _lines.remove(line));
    // Disposed after the rebuild, so nothing is reading the controller as it goes.
    WidgetsBinding.instance.addPostFrameCallback((_) => line.dispose());
  }

  /// A blank row, rather than a dialog: there is nothing to pick from — the name is whatever the
  /// supplier called it on the invoice — so a sheet would be one more tap around an empty box.
  void _addAdditionalCost() {
    setState(
      () => _additionalCosts.add(_AdditionalCostDraft(name: '', amount: '')),
    );
  }

  void _removeAdditionalCost(_AdditionalCostDraft cost) {
    setState(() => _additionalCosts.remove(cost));
    WidgetsBinding.instance.addPostFrameCallback((_) => cost.dispose());
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vendor = _vendor;
    final warehouse = _warehouse;

    if (vendor == null || warehouse == null || _lines.isEmpty) {
      context.showInfo('اختر المورد والمخزن، وأضف بنداً واحداً على الأقل');

      return;
    }

    context.read<SavePurchaseOrderCubit>().submit(
      id: widget.order?.id,
      vendorId: vendor.id,
      warehouseId: warehouse.id,
      orderDate: _orderDate,
      expectedDate: _expectedDate,
      notes: _notes.text,
      items: [
        for (final line in _lines)
          DraftLine(
            // Carried through, so an existing line is corrected rather than replaced — and its
            // received quantity survives the edit.
            id: line.id,
            stockItemId: line.stockItemId,
            quantity: line.quantity.text,
            baseTotalCost: line.baseTotalCost.text,
          ),
      ],
      // The whole current list every time, including when it is empty — that is how the server
      // is told the last one was removed.
      additionalCosts: [
        for (final cost in _additionalCosts)
          DraftAdditionalCost(
            id: cost.id,
            name: cost.name.text,
            amount: cost.amount.text,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavePurchaseOrderCubit, SavePurchaseOrderState>(
      listener: (context, state) {
        switch (state) {
          case SavePurchaseOrderSuccess(:final order):
            // The saved order goes back with it, so the screen behind redraws its row from what
            // the server stored rather than asking for it again.
            Navigator.of(context).pop(order);
            context.showSuccess(
              _isEditing ? 'تم حفظ أمر الشراء' : 'تم إنشاء أمر الشراء',
            );
          case SavePurchaseOrderFailure(:final failure)
              when state.hasUnrenderedErrors:
            context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SavePurchaseOrderCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'تعديل أمر الشراء' : 'أمر شراء جديد'),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                children: [
                  _PickerTile(
                    icon: AppIcons.vendors,
                    label: 'المورد',
                    value: _vendor?.name,
                    hint: 'اختر المورد',
                    error: state.vendorError,
                    // Locked while editing, and said rather than merely greyed.
                    lockedNote: _mayPickVendor
                        ? null
                        : 'المورد لا يتغيّر بعد إنشاء الأمر',
                    onTap: _mayPickVendor ? _pickVendor : null,
                  ),
                  SizedBox(height: 12.h),
                  _PickerTile(
                    icon: AppIcons.warehouse,
                    label: 'مخزن الوجهة',
                    value: _warehouse?.name,
                    hint: 'أين تدخل البضاعة',
                    error: state.warehouseError,
                    onTap: _pickWarehouse,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: AppIcons.today,
                          label: 'تاريخ الطلب',
                          value: _orderDate,
                          hint: 'اختر التاريخ',
                          error: state.orderDateError,
                          onTap: () => _pickDate(isExpected: false),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _PickerTile(
                          icon: AppIcons.month,
                          label: 'الوصول المتوقع',
                          value: _expectedDate,
                          hint: 'اختياري',
                          error: state.expectedDateError,
                          onTap: () => _pickDate(isExpected: true),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  _ListHeader(
                    title: 'البنود',
                    count: _lines.length,
                    emptyLabel: 'لا بنود',
                    error: state.itemsError,
                  ),
                  SizedBox(height: 8.h),
                  for (final line in _lines)
                    _LineRow(
                      key: ValueKey(line.stockItemId),
                      line: line,
                      onChanged: (_) => cubit.clearFailure(),
                      onRemove: () => _removeLine(line),
                    ),
                  SizedBox(height: 8.h),
                  AppButton.tonal(
                    // «صنف» and no longer «مقاس»: what is added is a shelf, and the size is part
                    // of its name rather than a second choice after it.
                    label: 'إضافة مادة',
                    icon: AppIcons.add,
                    onPressed: _addLine,
                  ),

                  SizedBox(height: 20.h),
                  // Under the lines, because they are what it is spread over: delivery is only
                  // meaningful once there is something being delivered.
                  _ListHeader(
                    title: 'تكاليف إضافية',
                    count: _additionalCosts.length,
                    emptyLabel: 'لا تكاليف',
                    error: state.additionalCostsError,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'التوصيل والتفريغ والجمارك — تُوزَّع على البنود حسب قيمة كل بند',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  for (final cost in _additionalCosts)
                    _AdditionalCostRow(
                      key: ObjectKey(cost),
                      cost: cost,
                      onChanged: (_) => cubit.clearFailure(),
                      onRemove: () => _removeAdditionalCost(cost),
                    ),
                  SizedBox(height: 8.h),
                  AppButton.tonal(
                    label: 'إضافة تكلفة',
                    icon: AppIcons.add,
                    onPressed: _addAdditionalCost,
                  ),

                  SizedBox(height: 20.h),
                  AppTextField(
                    controller: _notes,
                    label: 'ملاحظات (اختياري)',
                    prefixIcon: AppIcons.edit,
                    maxLines: 3,
                    onChanged: (_) => cubit.clearFailure(),
                  ),
                  SizedBox(height: 28.h),

                  AppButton(
                    label: _isEditing ? 'حفظ التعديلات' : 'إنشاء أمر الشراء',
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One line as the form holds it: both numbers are still text, because that is what was typed.
class _LineDraft {
  _LineDraft({
    required this.stockItemId,
    required this.title,
    required String quantity,
    required String baseTotalCost,
    this.code,
    this.unit = const PurchaseLineUnit(null),
    this.id,
  }) : quantity = TextEditingController(text: quantity),
       baseTotalCost = TextEditingController(text: baseTotalCost);

  final int? id;

  /// Which shelf. Also the row's identity on screen — an order may hold only one line per item,
  /// so it is unique among the drafts by construction, which is what makes it a safe `ValueKey`.
  final int stockItemId;

  /// «كيس شحن 25*35», as the server composed it.
  final String title;

  /// `S7` — the shelf's code, kept beside the name because it is the part a buyer reads down a
  /// phone line to the supplier, and because it is what replaced the product photograph. Null
  /// only on a line seeded from an order that arrived without its item.
  final String? code;

  /// «كيلوغرام» or «قطعة» — what the quantity box below is asking for.
  ///
  /// The *same* type the saved line uses, so the form asks in the word the order will report in.
  /// It is the **shelf's** unit: two products sharing a pile cannot disagree about how it is
  /// counted, which is exactly why `products.stock_unit` was dropped. Null only on a line raised
  /// before the unit column existed, and everything built from it then says nothing rather than
  /// guessing.
  final PurchaseLineUnit unit;

  final TextEditingController quantity;

  /// What the whole line costs, as invoiced. Names no unit — see the note on the page.
  final TextEditingController baseTotalCost;

  void dispose() {
    quantity.dispose();
    baseTotalCost.dispose();
  }
}

/// One order-level cost as the form holds it.
class _AdditionalCostDraft {
  _AdditionalCostDraft({required String name, required String amount, this.id})
    : name = TextEditingController(text: name),
      amount = TextEditingController(text: amount);

  /// Carried through so an existing cost is corrected rather than deleted and recreated.
  final int? id;

  final TextEditingController name;
  final TextEditingController amount;

  /// Whether anything has been typed into either box.
  ///
  /// **A row nobody filled in is dropped rather than refused.** Tapping «إضافة تكلفة» and
  /// changing your mind is not an error worth blocking a save over, and the same test runs again
  /// in [DraftAdditionalCost.isBlank] before anything reaches the wire.
  bool get isBlank => name.text.trim().isEmpty && amount.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// The bar above an editable list: what it is, how much is in it, and what the server said about
/// it as a whole.
///
/// Shared by the two lists so they read as one screen — a complaint about the lines and one
/// about the delivery charges land in the same place, in the same words.
class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.title,
    required this.count,
    required this.emptyLabel,
    this.error,
  });

  final String title;
  final int count;

  /// What to say instead of «0», which reads as a figure rather than as an absence.
  final String emptyLabel;

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              count == 0 ? emptyLabel : count.grouped,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (error case final message?) ...[
          SizedBox(height: 6.h),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _LineDraft line;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Under the name and quieter than it: the code identifies the shelf on the
                    // phone to the supplier, and it is what stands where the product's name and
                    // photograph used to. A line that arrived without its item draws nothing here
                    // rather than a code invented from the id.
                    if (line.code case final code?) ...[
                      SizedBox(height: 2.h),
                      Text(
                        code,
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.delete, size: 20.sp),
                color: scheme.error,
                tooltip: 'إزالة البند',
              ),
            ],
          ),
          // On its own full-width row rather than beside the name: a quantity squeezed into a
          // narrow box comes out clipped, which is a number nobody can check.
          AppTextField(
            controller: line.quantity,
            label: line.unit.quantityField,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.').trim(),
              );

              return parsed == null || parsed <= 0
                  ? 'أدخل كمية أكبر من صفر'
                  : null;
            },
            onChanged: onChanged,
          ),
          SizedBox(height: 10.h),
          // Its own row for the same reason as the quantity above, and *under* it because the
          // quantity is what a buyer knows first — the price is what they then ask for.
          AppTextField(
            controller: line.baseTotalCost,
            // The line's total, which is what the invoice in the buyer's hand is written in.
            // The server divides by the quantity above to get the per-unit figure.
            label: 'تكلفة البند الإجمالية (د.ل)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              final parsed = double.tryParse(
                Validators.toWesternDigits(
                  value ?? '',
                ).replaceAll(',', '.').trim(),
              );

              // **Zero passes.** A vendor replacing a bad batch for nothing is a real cost of
              // zero, and refusing it would have buyers typing «0.001» to get past the form.
              if (parsed == null) return 'أدخل التكلفة';

              return parsed < 0 ? 'التكلفة لا يمكن أن تكون سالبة' : null;
            },
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// One order-level cost: what it was for, and how much.
///
/// **The same card the line items use**, so the two lists read as one screen rather than as two
/// features bolted together — one add button under each, one delete on each row, in the same
/// place.
class _AdditionalCostRow extends StatelessWidget {
  const _AdditionalCostRow({
    required this.cost,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final _AdditionalCostDraft cost;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: cost.name,
                  label: 'البيان',
                  hint: 'توصيل، تفريغ، جمارك…',
                  // Only when the row has something in it: an untouched row is dropped before
                  // sending, so refusing to save because of one is a wall with nothing behind it.
                  validator: (value) =>
                      cost.isBlank || (value ?? '').trim().isNotEmpty
                      ? null
                      : 'أدخل بيان التكلفة',
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(AppIcons.delete, size: 20.sp),
                color: scheme.error,
                tooltip: 'إزالة التكلفة',
              ),
            ],
          ),
          SizedBox(height: 10.h),
          AppTextField(
            controller: cost.amount,
            label: 'القيمة (د.ل)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              if (cost.isBlank) return null;

              final parsed = double.tryParse(
                Validators.toWesternDigits(
                  value ?? '',
                ).replaceAll(',', '.').trim(),
              );

              if (parsed == null) return 'أدخل القيمة';

              return parsed < 0 ? 'القيمة لا يمكن أن تكون سالبة' : null;
            },
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A row that opens a picker and shows what came back.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.hint,
    this.value,
    this.error,
    this.lockedNote,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? value;
  final String? error;
  final String? lockedNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEmpty = value == null || value!.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: error == null
                      ? scheme.outlineVariant.withValues(alpha: 0.7)
                      : scheme.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20.sp, color: scheme.onSurfaceVariant),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isEmpty ? hint : value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isEmpty ? scheme.outline : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
        if (lockedNote case final note?) ...[
          SizedBox(height: 4.h),
          Text(
            note,
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (error case final message?) ...[
          SizedBox(height: 4.h),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
