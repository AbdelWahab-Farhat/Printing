import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/product_picker_sheet.dart';
import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/save_shortage_cubit.dart';
import 'package:dayaa/features/shortages/presentation/widgets/assign_shortage_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Writing a shortage down by hand, and correcting one.
///
/// **A shortage born of an order never opens this screen.** Its quantity belongs to the order —
/// the server refuses the edit, «نقصٌ مصدره طلبية — تُعدَّل كميته من شاشة الطلبية لا من هنا» — and
/// `Shortage.isEditable` says so in advance, so the pencil is simply not drawn on one.
class ShortageFormPage extends StatelessWidget {
  const ShortageFormPage({this.shortage, super.key});

  /// The one being corrected, or null when one is being written down.
  final Shortage? shortage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveShortageCubit>(
      create: (_) => sl<SaveShortageCubit>(),
      child: _ShortageFormView(shortage: shortage),
    );
  }
}

class _ShortageFormView extends StatefulWidget {
  const _ShortageFormView({required this.shortage});

  final Shortage? shortage;

  @override
  State<_ShortageFormView> createState() => _ShortageFormViewState();
}

class _ShortageFormViewState extends State<_ShortageFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.shortage?.name);
  late final TextEditingController _quantity = TextEditingController(
    // The figure as the column holds it, trimmed of its padding: a box opening on «30.000» is a
    // box asking to be cleared before it can be agreed with.
    text: widget.shortage == null ? null : trimDecimals(widget.shortage!.requiredQuantity),
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.shortage?.description,
  );

  /// **The server requires it on a create** — «الوحدة مطلوبة» — and the form used to send no
  /// unit at all, so every hand-written shortage was refused. `PricingUnit` is the app's own
  /// enum for the one screen that has to name the units before there is anything to read them
  /// off, which is exactly this one.
  late PricingUnit _unit = PricingUnit.fromWire(widget.shortage?.unit);

  /// The catalogue row behind it, when there is one.
  ///
  /// **A shortage names a product *or* is free text, and both are ordinary.** «كيس شحن — 25*35»
  /// has a shelf, so a supply against it can be put on one; «شريط لاصق عريض» has none, and the
  /// server answers `is_stockable` accordingly. Picking one fills the name and the unit from the
  /// catalogue rather than leaving somebody to retype what the picker just showed them.
  ///
  /// Only ever set while *creating*: the ids are not part of an edit — the server takes the name
  /// and the quantity there.
  PickedProduct? _picked;

  /// Who is chasing it. Optional, and «غير مُسنَد» is an ordinary answer — it is the queue a
  /// supervisor works from.
  late int? _assignedToUserId = widget.shortage?.assignedToUserId;
  late String? _assigneeName = widget.shortage?.assignee?.name;

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final picked = await showProductPicker(context: context);
    if (picked == null || !mounted) return;

    setState(() {
      _picked = picked;
      // The catalogue's own words and its own unit, so the two boxes agree with the row above
      // them. Both stay editable: «كيس شحن — 25*35» is a starting point, not a lock.
      _name.text = '${picked.product.name} — ${picked.variant.label}';
      _unit = PricingUnit.fromWire(picked.product.pricingUnit);
    });
  }

  Future<void> _pickAssignee() async {
    final choice = await showAssignShortageSheet(
      context: context,
      currentUserId: _assignedToUserId,
    );

    // Null is a dismissal; «غير مُسنَد» arrives as a choice carrying a null id.
    if (choice == null || !mounted) return;

    setState(() {
      _assignedToUserId = choice.userId;
      _assigneeName = choice.name;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<SaveShortageCubit>().submit(
      id: widget.shortage?.id,
      name: _name.text.trim(),
      quantity: Validators.toWesternDigits(_quantity.text.trim()),
      unit: _unit.wire,
      productId: _picked?.product.id,
      productVariantId: _picked?.variant.id,
      assignedToUserId: _assignedToUserId,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shortage != null;

    return BlocConsumer<SaveShortageCubit, SaveShortageState>(
      listener: (context, state) {
        switch (state) {
          // The saved row is handed back, so the list patches rather than re-reads.
          case SaveShortageSuccess(:final shortage):
            Navigator.of(context).pop(shortage);
          case SaveShortageFailure(:final failure):
            context.showFailure(failure);
          default:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(isEdit ? 'تعديل النقص' : 'نقص جديد')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // **The catalogue first, and only on a create.** Picking a product is what makes
                // the shortage stockable — the goods have a shelf to land on when somebody buys
                // them — and it fills the two boxes under it rather than asking for what the
                // picker has just shown.
                if (!isEdit) ...[
                  _PickerRow(
                    label: 'المنتج',
                    value: _picked == null
                        ? 'بدون منتج — نقص يدوي'
                        : '${_picked!.product.name} — ${_picked!.variant.label}',
                    // The unit, where it is a consequence rather than a question: «بالقطعة»
                    // under the row that decided it.
                    hint: _picked == null ? null : _unit.label,
                    onTap: _pickProduct,
                    onClear: _picked == null
                        ? null
                        : () => setState(() {
                            _picked = null;
                            // The name it filled in stays — somebody may have gone on to edit
                            // it — but the unit becomes a question again, so it opens on the
                            // catalogue's answer rather than on nothing.
                          }),
                  ),
                  SizedBox(height: 12.h),
                ],
                AppTextField(
                  controller: _name,
                  label: 'ما النقص؟',
                  errorText: state.nameError,
                  validator: (value) => (value ?? '').trim().isEmpty ? 'اكتب اسم النقص' : null,
                ),
                SizedBox(height: 12.h),
                AppTextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  label: 'الكمية المطلوبة',
                  // The refusal that catches people on an edit — «أقل مما تم توفيره فعلاً» — is
                  // about a figure already in the ledger, so it lands under the box rather than
                  // in a toast that scrolls away.
                  errorText: state.quantityError,
                  validator: (value) {
                    final typed = double.tryParse(Validators.toWesternDigits(value ?? ''));

                    return typed == null || typed <= 0 ? 'أدخل كمية' : null;
                  },
                ),
                SizedBox(height: 12.h),
                // **Asked only when nobody can answer it for you.** A shortage that names a
                // product takes that product's unit — the same rule a shortage born of an order
                // follows, where the line's unit is copied onto it — so putting the question on
                // screen would be asking somebody to retype what the catalogue already says, and
                // giving them the chance to disagree with it. It is printed beside the product
                // instead. Free text has no catalogue to read, so there the picker stands.
                if (_picked == null) ...[
                  AppDropdown<PricingUnit>(
                    value: _unit,
                    items: PricingUnit.choices,
                    labelOf: (unit) => unit.label,
                    label: 'الوحدة',
                    errorText: state.unitError,
                    onChanged: (unit) => setState(() => _unit = unit ?? _unit),
                  ),
                  SizedBox(height: 12.h),
                ],
                _PickerRow(
                  label: 'الموظف المسؤول',
                  value: _assigneeName ?? 'غير مُسنَد',
                  onTap: _pickAssignee,
                  onClear: _assignedToUserId == null
                      ? null
                      : () => setState(() {
                          _assignedToUserId = null;
                          _assigneeName = null;
                        }),
                ),
                SizedBox(height: 12.h),
                AppTextField(controller: _description, label: 'وصف', maxLines: 3),
                SizedBox(height: 24.h),
                AppButton(
                  label: isEdit ? 'حفظ' : 'إضافة',
                  onPressed: state.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A row that opens a picker — the catalogue's, or the employees'.
///
/// Not an [AppDropdown]: both lists are paginated and searched on the server, so neither fits in
/// a dropdown's fixed set. The value is written where a field's value would be, and «مسح» is
/// offered only once there is something to clear.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.onClear,
  });

  final String label;
  final String value;

  /// A consequence of the choice, drawn under it — the unit a picked product brings with it.
  final String? hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        // **The same box every other field on this form wears.** It defaulted to the underline
        // decoration and sat between two filled, rounded boxes looking like a different kind of
        // control — which it is not: it asks one question and holds one answer, exactly as
        // `AppTextField` does. Copied from that widget's own decoration so the two cannot drift.
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          suffixIcon: onClear == null
              ? const Icon(Icons.expand_more_rounded)
              : IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
  }
}
