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

/// What kind of thing is short — the first question the form asks, and the one that decides
/// which of the others are worth asking.
///
/// **The two halves want genuinely different forms.** A catalogue row arrives carrying its own
/// name and its own unit, so neither is a question and «نوع النقص» is not one either — the
/// product *is* the category. A consumable has no catalogue row to read anything off, so its
/// category is asked and stands in for the name.
///
/// Before this fork the form asked everything of everybody: a product picker that could be left
/// on «بدون منتج», a free-text name beside it repeating what the picker had just filled in, and
/// a category dropdown that meant nothing once a product was chosen.
enum _ShortageKind {
  /// «كيس شحن — 25*35» — something the shop sells, short on the shelf.
  product('منتج'),

  /// «حبر», «ورق طباعة», «شريط لاصق عريض» — what keeps the press running rather than what it
  /// prints.
  supplies('مستلزمات');

  const _ShortageKind(this.label);

  final String label;
}

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

  /// Asked of «أخرى» alone — see [_composedName].
  late final TextEditingController _name = TextEditingController(text: widget.shortage?.name);
  late final TextEditingController _quantity = TextEditingController(
    // The figure as the column holds it, trimmed of its padding: a box opening on «30.000» is a
    // box asking to be cleared before it can be agreed with.
    text: widget.shortage == null ? null : trimDecimals(widget.shortage!.requiredQuantity),
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.shortage?.description,
  );

  /// Which form this is.
  ///
  /// **Read off the row when correcting one**, so a shortage that names a product opens on the
  /// product side and one that does not opens on the other — nobody is asked to say again what
  /// the row already says. A new one opens on «منتج», which is what the shop is short of most
  /// of the time.
  late _ShortageKind _kind = switch (widget.shortage) {
    null => _ShortageKind.product,
    Shortage(:final productId) => productId == null
        ? _ShortageKind.supplies
        : _ShortageKind.product,
  };

  /// **The server requires it on a create** — «الوحدة مطلوبة». Under «منتج» it is the catalogue's
  /// answer and is never asked; under «مستلزمات» there is nothing to read it off, and paper is
  /// bought by the kilo where a blade is bought by the piece.
  ///
  /// `PricingUnit` is the app's own enum for the one screen that has to name the units before
  /// there is anything to read them off, which is exactly this one.
  late PricingUnit _unit = PricingUnit.fromWire(widget.shortage?.unit);

  /// What kind of consumable is short — «ورق طباعة» rather than «حبر».
  ///
  /// **Opens on «أخرى», which is the server's default too.** What gets written down by hand is
  /// often what no list anticipated, and a form that forced a category would have somebody pick
  /// the nearest wrong one to get past the field.
  ///
  /// «نقص طلبية» is never among the choices: the server stamps that on rows it mirrors from an
  /// order line and refuses it here, so offering it would be building a 422. A shortage already
  /// carrying it cannot reach this form at all — an order-born row is not editable.
  late ShortageType _type = switch (widget.shortage?.type) {
    final type? when ShortageType.selectableByHand.contains(type) => type,
    _ => ShortageType.other,
  };

  /// The catalogue row behind it, held as the three fields the endpoint takes rather than as a
  /// [PickedProduct]: a shortage being corrected carries its product as two ids and a pair of
  /// names, and no amount of that reconstitutes the full `Product` the picker hands back.
  late int? _productId = widget.shortage?.productId;
  late int? _productVariantId = widget.shortage?.productVariantId;
  late String? _productLabel = _seededProductLabel();

  /// «اختر المنتج», painted under the picker when «منتج» was promised and nothing chosen. The
  /// row is an `InputDecorator` rather than a `FormField`, so the refusal is held here instead
  /// of coming back out of `_formKey.currentState.validate()`.
  String? _productError;

  /// What to write on the picker when the form opens on an existing shortage.
  ///
  /// The nested product and variant are `whenLoaded` on the server, so on a payload that carries
  /// only the ids the shortage's own name is the honest fallback — it was built from exactly
  /// those two rows when it was written.
  String? _seededProductLabel() {
    final shortage = widget.shortage;

    if (shortage == null || shortage.productId == null) return null;

    return switch ((shortage.product, shortage.variant)) {
      (final product?, final variant?) => '${product.name} — ${variant.label}',
      _ => shortage.name,
    };
  }

  /// Who is chasing it. Optional, and «غير مُسنَد» is an ordinary answer — it is the queue a
  /// supervisor works from.
  late int? _assignedToUserId = widget.shortage?.assignedToUserId;
  late String? _assigneeName = widget.shortage?.assignee?.name;

  /// What the row will be called, which nobody types except in the one case where nothing else
  /// can say it.
  ///
  /// **The name is a consequence of the two questions above it, not a third question.** A
  /// product names itself; a category names itself — «حبر» is the whole of what that row is
  /// called, and a box asking for it again invites «حبر» typed a second time, differently.
  /// «أخرى» names nothing, so there the box stands.
  String get _composedName => switch (_kind) {
    _ShortageKind.product => _productLabel ?? '',
    _ShortageKind.supplies when _type == ShortageType.other => _name.text.trim(),
    _ShortageKind.supplies => _type.label,
  };

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
      _productId = picked.product.id;
      _productVariantId = picked.variant.id;
      _productLabel = '${picked.product.name} — ${picked.variant.label}';
      // The catalogue's own unit, so the figure below is counted the way the product is sold.
      _unit = PricingUnit.fromWire(picked.product.pricingUnit);
      _productError = null;
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
    final isValid = _formKey.currentState?.validate() ?? false;
    // Not a `validator`, because the control it belongs to is not a `FormField` — see
    // [_productError]. Evaluated whether or not the rest of the form passed, so somebody who
    // left two things out is told about both at once.
    final needsProduct = _kind == _ShortageKind.product && _productId == null;

    setState(() => _productError = needsProduct ? 'اختر المنتج' : null);

    if (!isValid || needsProduct) return;

    final isProduct = _kind == _ShortageKind.product;

    context.read<SaveShortageCubit>().submit(
      id: widget.shortage?.id,
      name: _composedName,
      quantity: Validators.toWesternDigits(_quantity.text.trim()),
      unit: _unit.wire,
      // **Omitted when it is «أخرى», sent otherwise, and the two sides of the fork need no
      // separate rule.** Under «مستلزمات» «أخرى» is what somebody chose and the server's own
      // default, so leaving it out says the same thing in one place rather than two. Under
      // «منتج» nothing on screen asks the category at all — but `_type` still holds whatever
      // the row was filed under, so a shortage already marked «ورق طباعة» keeps that through a
      // correction instead of falling back the first time its quantity is fixed.
      type: _type == ShortageType.other ? null : _type.wire,
      productId: isProduct ? _productId : null,
      productVariantId: isProduct ? _productVariantId : null,
      assignedToUserId: _assignedToUserId,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shortage != null;
    final isProduct = _kind == _ShortageKind.product;

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
                // **The fork, and it is first because everything under it depends on the
                // answer.** Two segments rather than a dropdown: there are exactly two, and the
                // choice is read before the form is, not opened to be read.
                SegmentedButton<_ShortageKind>(
                  segments: [
                    for (final kind in _ShortageKind.values)
                      ButtonSegment<_ShortageKind>(value: kind, label: Text(kind.label)),
                  ],
                  selected: {_kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (choice) => setState(() {
                    _kind = choice.first;
                    // The complaint belonged to the side that is no longer on screen.
                    _productError = null;
                  }),
                ),
                SizedBox(height: 12.h),
                if (isProduct) ...[
                  _PickerRow(
                    label: 'المنتج',
                    value: _productLabel ?? 'اختيار المنتج',
                    // The unit, where it is a consequence rather than a question: «بالقطعة»
                    // under the row that decided it.
                    hint: _productLabel == null ? null : _unit.label,
                    // Three refusals, one slot. The name and the unit are both the product's
                    // doing on this side of the fork, so the server's complaint about either
                    // belongs under the row that answered it.
                    errorText: _productError ?? state.nameError ?? state.unitError,
                    onTap: _pickProduct,
                  ),
                  SizedBox(height: 12.h),
                ] else ...[
                  AppDropdown<ShortageType>(
                    value: _type,
                    items: ShortageType.selectableByHand,
                    labelOf: (type) => type.label,
                    label: 'نوع النقص',
                    // It names the row, so a refusal about the name lands here.
                    errorText: state.nameError,
                    onChanged: (type) => setState(() => _type = type ?? _type),
                  ),
                  SizedBox(height: 12.h),
                  // **The one box «أخرى» cannot do without.** Every other category is the whole
                  // of what the row is called; «أخرى» says only that no list had it.
                  if (_type == ShortageType.other) ...[
                    AppTextField(
                      controller: _name,
                      label: 'ما النقص؟',
                      validator: (value) => (value ?? '').trim().isEmpty ? 'اكتب اسم النقص' : null,
                    ),
                    SizedBox(height: 12.h),
                  ],
                ],
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
                // instead.
                if (!isProduct) ...[
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
    this.errorText,
    this.onClear,
  });

  final String label;
  final String value;

  /// A consequence of the choice, drawn under it — the unit a picked product brings with it.
  final String? hint;

  /// A refusal about the answer this row holds — the form's own, or the server's.
  final String? errorText;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final borderColour = errorText == null ? scheme.outlineVariant : scheme.error;

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
          errorText: errorText,
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: borderColour),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: borderColour),
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
