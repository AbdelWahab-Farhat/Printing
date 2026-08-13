import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:printing/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:printing/features/vendors/models/vendor.dart';
import 'package:printing/features/vendors/presentation/widgets/vendor_picker_sheet.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';
import 'package:printing/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';

/// Raising a purchase order, or correcting one.
///
/// **Every line carries a cost, and it has to be typed.** What we pay a supplier is not in any
/// catalogue — the tiers there price what we *sell* — so there is nothing to quote against and
/// no sensible default to prefill. The server requires it on every line and the form asks for it
/// beside the quantity.
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
        productVariantId: item.productVariantId,
        title: item.title,
        quantity: item.orderedLabel,
        // Empty for a line raised before cost tracking, so the field opens asking rather than
        // opening on a zero somebody would have to notice was never typed.
        unitCost: item.unitCost == null ? '' : trimDecimals(item.unitCost!),
      ),
  ];

  bool get _isEditing => widget.order != null;

  /// Locked once the order exists — see the note on the page.
  bool get _mayPickVendor => !_isEditing;

  ({int id, String name})? _seedVendor() {
    if (widget.vendor case final vendor?) return (id: vendor.id, name: vendor.name);

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

    final value = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    setState(() {
      if (isExpected) {
        _expectedDate = value;
      } else {
        _orderDate = value;
      }
    });
  }

  Future<void> _addLine() async {
    final picked = await showProductPicker(context: context);
    if (picked == null) return;

    // Refused here as well as by the server, and with a sentence rather than a 422: the API's
    // `distinct` rule points at `items.2.product_variant_id`, which is not a thing on screen.
    if (_lines.any((line) => line.productVariantId == picked.variant.id)) {
      if (!mounted) return;
      context.showInfo('هذا المقاس مضاف بالفعل');

      return;
    }

    setState(() {
      _lines.add(
        _LineDraft(
          productVariantId: picked.variant.id,
          title: '${picked.product.name} · ${picked.variant.label}',
          quantity: '',
          unitCost: '',
        ),
      );
    });
  }

  void _removeLine(_LineDraft line) {
    setState(() => _lines.remove(line));
    // Disposed after the rebuild, so nothing is reading the controller as it goes.
    WidgetsBinding.instance.addPostFrameCallback((_) => line.dispose());
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
            productVariantId: line.productVariantId,
            quantity: line.quantity.text,
            unitCost: line.unitCost.text,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SavePurchaseOrderCubit, SavePurchaseOrderState>(
      listener: (context, state) {
        switch (state) {
          case SavePurchaseOrderSuccess():
            Navigator.of(context).pop(true);
            context.showSuccess(_isEditing ? 'تم حفظ أمر الشراء' : 'تم إنشاء أمر الشراء');
          case SavePurchaseOrderFailure(:final failure) when state.hasUnrenderedErrors:
            context.showFailure(failure);
          case _:
            break;
        }
      },
      builder: (context, state) {
        final cubit = context.read<SavePurchaseOrderCubit>();

        return Scaffold(
          appBar: AppBar(title: Text(_isEditing ? 'تعديل أمر الشراء' : 'أمر شراء جديد')),
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

                  _LinesHeader(count: _lines.length, error: state.itemsError),
                  SizedBox(height: 8.h),
                  for (final line in _lines)
                    _LineRow(
                      key: ValueKey(line.productVariantId),
                      line: line,
                      onChanged: (_) => cubit.clearFailure(),
                      onRemove: () => _removeLine(line),
                    ),
                  SizedBox(height: 8.h),
                  AppButton.tonal(
                    label: 'إضافة مقاس',
                    icon: AppIcons.add,
                    onPressed: _addLine,
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
    required this.productVariantId,
    required this.title,
    required String quantity,
    required String unitCost,
    this.id,
  }) : quantity = TextEditingController(text: quantity),
       unitCost = TextEditingController(text: unitCost);

  final int? id;
  final int productVariantId;
  final String title;
  final TextEditingController quantity;
  final TextEditingController unitCost;

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}

class _LinesHeader extends StatelessWidget {
  const _LinesHeader({required this.count, this.error});

  final int count;
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
              'البنود',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              count == 0 ? 'لا بنود' : '$count',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                child: Text(
                  line.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
            label: 'الكمية المطلوبة',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              final parsed = double.tryParse(
                (value ?? '').replaceAll(',', '.').trim(),
              );

              return parsed == null || parsed <= 0 ? 'أدخل كمية أكبر من صفر' : null;
            },
            onChanged: onChanged,
          ),
          SizedBox(height: 10.h),
          // Its own row for the same reason as the quantity above, and *under* it because the
          // quantity is what a buyer knows first — the price is what they then ask for.
          AppTextField(
            controller: line.unitCost,
            label: 'تكلفة الوحدة (د.ل)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
            ],
            validator: (value) {
              final parsed = double.tryParse(
                Validators.toWesternDigits(value ?? '').replaceAll(',', '.').trim(),
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
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
