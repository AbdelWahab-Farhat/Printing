import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/design_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/shipping_company_picker_sheet.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/warehouse_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One field of a move, drawn from the description the server sent with it.
///
/// **A widget per kind, and nothing per field.** Adding «رقم التتبع» to «جاري التوصيل» is a line
/// on the backend: it arrives as a `text` field and lands here already knowing its own label,
/// whether it is required and what to say underneath. Only a *kind* nobody has drawn yet needs
/// a change in this file — and until it lands, [_Unsupported] says so out loud rather than
/// leaving a gap the user cannot fill.
class TransitionFieldInput extends StatelessWidget {
  const TransitionFieldInput({
    required this.field,
    required this.value,
    required this.customerId,
    required this.onChanged,
    super.key,
  });

  final TransitionField field;

  /// Whatever this kind of field holds — a `String`, a `List<CustomerDesign>`, or null.
  final Object? value;

  /// Whose library the artwork is picked from. Only the design kinds use it.
  final int customerId;

  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (field.type) {
      TransitionFieldType.text => _Text(
        field: field,
        value: value is String ? value! as String : '',
        onChanged: onChanged,
      ),
      TransitionFieldType.number => _Number(
        field: field,
        value: value is String ? value! as String : '',
        onChanged: onChanged,
      ),
      TransitionFieldType.customerDesigns => _Designs(
        field: field,
        customerId: customerId,
        chosen: value is List<CustomerDesign> ? value! as List<CustomerDesign> : const [],
        onChanged: onChanged,
      ),
      TransitionFieldType.shippingCompany => _Carrier(
        field: field,
        chosen: value is ShippingCompany ? value! as ShippingCompany : null,
        onChanged: onChanged,
      ),
      TransitionFieldType.file => _File(
        field: field,
        picked: value is PickedFile ? value! as PickedFile : null,
        onChanged: onChanged,
      ),
      TransitionFieldType.paymentMethod => _Method(
        field: field,
        chosen: value is String ? value! as String : null,
        onChanged: onChanged,
      ),
      TransitionFieldType.warehouse => _Store(
        field: field,
        chosen: value is Warehouse ? value! as Warehouse : null,
        onChanged: onChanged,
      ),
      TransitionFieldType.unknown => _Unsupported(field: field),
    };
  }
}

/// A document or a photograph the move carries — «الواصل», today.
///
/// **The same three sources a design arrives through**, and for the same reason the payments
/// screen offers them: the receipt that actually turns up is a banking-app screenshot or a
/// photograph sent over WhatsApp, which on iOS lands in the photo library — a place the Files
/// app cannot see at all.
///
/// **Nothing here knows what a receipt is.** The label, the sentence under it, what may be
/// attached and how big it may be all arrive with the field, so a second file field on some
/// other move needs no Dart.
class _File extends StatelessWidget {
  const _File({required this.field, required this.picked, required this.onChanged});

  final TransitionField field;
  final PickedFile? picked;
  final ValueChanged<Object?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final source = await showAttachmentSheet(context: context, title: 'إرفاق ${field.label}');

    if (source == null || !context.mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);

    if (!context.mounted || files.isEmpty) return;

    final file = files.first;

    // The picker's own filters are a courtesy and this is money: a file the endpoint would
    // refuse is refused here, in its words, rather than after an upload somebody waited through.
    final refusal = field.rejectFile(file.name, file.sizeBytes);

    if (refusal != null) {
      context.showError(refusal);

      return;
    }

    onChanged(file);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final file = picked;

    // Which glyph sits beside the name: the photo one for a picked image, the PDF one for a
    // document or for the empty slot. The name is only the client's claim — but so is the file
    // itself at this point, and the server sniffs the bytes either way.
    final isImage = file != null && !file.name.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.isRequired ? field.label : '${field.label} (اختياري)',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (field.hint case final hint?) ...[
          SizedBox(height: 4.h),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
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
                tooltip: 'إزالة ${field.label}',
                onPressed: () => onChanged(null),
              ),
            ],
          ),
          SizedBox(height: 8.h),
        ],
        AppButton.tonal(
          label: file == null ? 'اختيار ${field.label}' : 'تغيير ${field.label}',
          icon: AppIcons.document,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

/// How the money just taken was handed over.
///
/// **Chips, not a picker sheet.** The carrier and the warehouse are chosen from lists of dozens
/// that this app fetches; the methods are three, they arrive with the field, and three things
/// that fit on one line should cost one tap rather than a sheet, a scroll and a dismissal.
///
/// **Nothing here knows what a payment method is.** The wire value and the Arabic both come from
/// the server — see [TransitionFieldType.paymentMethod] — so the day a fourth is usable at a
/// counter it appears with no release, and the day «حوالة» stops needing a receipt it appears
/// too. What is reported back is [TransitionFieldOption.value], never the label.
class _Method extends StatelessWidget {
  const _Method({required this.field, required this.chosen, required this.onChanged});

  final TransitionField field;
  final String? chosen;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (field.hint case final hint?) ...[
          SizedBox(height: 4.h),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final option in field.options)
              ChoiceChip(
                label: Text(option.label),
                selected: option.value == chosen,
                // **Never unselectable.** A method is obligatory the moment an amount is typed,
                // so a tap that cleared the choice would only ever produce a refusal — and the
                // server fills one in already, so there is no empty state to return to.
                onSelected: (_) => onChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// Which shelf the run empties.
///
/// Holds the whole warehouse rather than its id for the same reason [_Carrier] holds the whole
/// company: the button has to say the name that was picked, and the cubit turns it into an id on
/// the way out.
///
/// **A dismissal leaves the field as it was**, and on the second pass that is the right answer
/// rather than a gap: a reprint has already taken its stock, so the server offers the picker
/// without requiring it and does nothing with a second reply.
class _Store extends StatelessWidget {
  const _Store({required this.field, required this.chosen, required this.onChanged});

  final TransitionField field;
  final Warehouse? chosen;
  final ValueChanged<Object?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showWarehousePicker(context: context);

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.isRequired ? field.label : '${field.label} (اختياري)',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (field.hint case final hint?) ...[
          SizedBox(height: 4.h),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        SizedBox(height: 10.h),
        AppButton.tonal(
          label: chosen?.name ?? 'اختيار المخزن',
          icon: AppIcons.warehouse,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

/// Who takes the parcel.
///
/// Holds the whole company rather than its id, so the button can say the name that was picked;
/// the cubit turns it into an id on the way out, exactly as it does for the artwork.
class _Carrier extends StatelessWidget {
  const _Carrier({required this.field, required this.chosen, required this.onChanged});

  final TransitionField field;
  final ShippingCompany? chosen;
  final ValueChanged<Object?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showShippingCompanyPicker(context: context, selected: chosen);

    // Null is a dismissal and changes nothing — there is no "clear" here, because a parcel
    // that has left has a carrier.
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.isRequired ? field.label : '${field.label} (اختياري)',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (field.hint case final hint?) ...[
          SizedBox(height: 4.h),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        SizedBox(height: 10.h),
        AppButton.tonal(
          label: chosen?.name ?? 'اختيار شركة التوصيل',
          icon: AppIcons.warehouse,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

class _Text extends StatefulWidget {
  const _Text({required this.field, required this.value, required this.onChanged});

  final TransitionField field;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Text> createState() => _TextState();
}

class _TextState extends State<_Text> {
  // Held here rather than rebuilt from the state on every keystroke: a controller recreated
  // mid-typing puts the caret back at the start, which is the classic way an Arabic form
  // becomes unusable.
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.field.isRequired ? widget.field.label : '${widget.field.label} (اختياري)',
      helperText: widget.field.hint,
      maxLines: widget.field.multiline ? 3 : 1,
      textInputAction: widget.field.multiline
          ? TextInputAction.newline
          : TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}

/// A quantity: a weight off a scale, a count off a press.
///
/// Sent as the string that was typed, like every other field — the server parses it, and a
/// half-typed «12.» is not a number this app should be deciding about mid-keystroke.
class _Number extends StatefulWidget {
  const _Number({required this.field, required this.value, required this.onChanged});

  final TransitionField field;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_Number> createState() => _NumberState();
}

class _NumberState extends State<_Number> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.field.isRequired
          ? widget.field.label
          : '${widget.field.label} (اختياري)',
      helperText: widget.field.hint,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // Arabic-Indic digits are what the keyboard produces, so they are allowed through and
      // normalised on the way out — the same rule the invoice editor follows.
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
      ],
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}

/// The artwork field: what has been chosen, and the one way to change it.
class _Designs extends StatelessWidget {
  const _Designs({
    required this.field,
    required this.customerId,
    required this.chosen,
    required this.onChanged,
  });

  final TransitionField field;
  final int customerId;
  final List<CustomerDesign> chosen;
  final ValueChanged<Object?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDesignPicker(
      context: context,
      customerId: customerId,
      selected: chosen,
    );

    // Null is a dismissal and changes nothing. An empty list is an answer: they cleared it.
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.isRequired ? field.label : '${field.label} (اختياري)',
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (field.hint case final hint?) ...[
          SizedBox(height: 4.h),
          Text(
            hint,
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        SizedBox(height: 10.h),
        for (final design in chosen)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  // What was picked, shown as itself — the same square the picker offered it in.
                  DesignThumbnail(design: design, size: 40),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      design.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppButton.tonal(
          label: chosen.isEmpty ? 'اختيار التصاميم' : 'تعديل الاختيار (${chosen.length})',
          icon: AppIcons.designs,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }
}

/// A kind this build has no control for.
///
/// Said rather than skipped: a required field the screen never showed is a form that cannot be
/// submitted, and «حدّث التطبيق» is an answer somebody can act on.
class _Unsupported extends StatelessWidget {
  const _Unsupported({required this.field});

  final TransitionField field;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        '«${field.label}» يحتاج نسخة أحدث من التطبيق',
        style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
