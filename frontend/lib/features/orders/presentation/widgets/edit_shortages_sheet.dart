import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/line_shortage_entry.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Correcting what is missing from an order — and with it, what the customer pays.
///
/// **Every line is here, short or not.** The set is replaced wholesale on the way out, so a line
/// the sheet did not show could not be cleared; and «أي بند نقص؟» is a question about the order,
/// which means the answer has to be able to move from one line to another. Emptying a box is the
/// gesture for «وصلت الكمية», and it is the one that puts the money back.
///
/// **The arithmetic is on screen as it is typed.** A shortage is not a note any more — it is
/// subtracted from the invoice — so each row says what that line will be charged before anybody
/// presses save. Finding out afterwards, on a total, is finding out from the wrong number.
///
/// **A line the warehouse counts differently is asked twice.** «ناقص ٣٠ قطعة» off a pile weighed
/// in kilograms is also a gap of some weight, and nothing converts the one into the other — bags
/// weighed together have no per-bag weight. The first box is what comes off the invoice; the
/// second is what «النواقص» will chase, buy and shelve. Where the units agree, one box answers
/// both and the second never appears.
///
/// Returns line id → what is missing, in both units, or null when it was dismissed. Sending it is
/// the caller's job: this is a form, and a form's answer is what the person entered.
Future<Map<int, LineShortageEntry>?> showEditShortagesSheet({
  required BuildContext context,
  required List<OrderItem> items,
}) {
  return showModalBottomSheet<Map<int, LineShortageEntry>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EditShortagesSheet(items: items),
  );
}

class _EditShortagesSheet extends StatefulWidget {
  const _EditShortagesSheet({required this.items});

  final List<OrderItem> items;

  @override
  State<_EditShortagesSheet> createState() => _EditShortagesSheetState();
}

class _EditShortagesSheetState extends State<_EditShortagesSheet> {
  final _formKey = GlobalKey<FormState>();

  /// One controller per line, opened on whatever is recorded against it today.
  late final Map<int, TextEditingController> _missing = {
    for (final item in widget.items)
      // `trimDecimals`, not `grouped`: the padding zeros are noise in a box a thumb is about to
      // edit, but a separator typed back in comes through `toWesternDigits` as a decimal point.
      item.id: TextEditingController(
        text: item.hasShortage ? trimDecimals(item.shortageQuantity!) : '',
      ),
  };

  /// The second box, opened only on the lines that get one — see [showEditShortagesSheet].
  late final Map<int, TextEditingController> _weighed = {
    for (final item in widget.items)
      if (item.needsAWarehouseShortage)
        item.id: TextEditingController(
          text: item.shortageWarehouseQuantity == null
              ? ''
              : trimDecimals(item.shortageWarehouseQuantity!),
        ),
  };

  @override
  void dispose() {
    for (final controller in _missing.values) {
      controller.dispose();
    }
    for (final controller in _weighed.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop({
      for (final entry in _missing.entries)
        entry.key: LineShortageEntry(
          quantity: entry.value.text,
          // **Null for anything but a weight somebody actually typed.**
          //
          // Omitted on a cleared line and on a same-unit one — a weight beside no shortage is a
          // measurement of nothing, and the server's CHECK refuses the pairing outright. Omitted
          // too when the box was simply left empty, which is the ordinary case: the missing bags
          // cannot be weighed, so «not stated yet» is the honest answer and null is how it
          // travels. An empty string here would reach the server as a value.
          warehouseQuantity: entry.value.text.trim().isEmpty
              ? null
              : _blankToNull(_weighed[entry.key]?.text),
        ),
    });
  }

  /// Blank is «لم يُحدَّد بعد», and that is a different thing from a number.
  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      // The keyboard's height, so the save button is never underneath it.
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
                  'تعديل النواقص',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'الناقص لا يُحاسَب عليه العميل. أفرغ الحقل إذا وصلت الكمية، فيرجع المبلغ.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                for (final item in widget.items) ...[
                  _LineField(
                    item: item,
                    controller: _missing[item.id]!,
                    warehouseController: _weighed[item.id],
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16.h),
                ],

                AppButton(label: 'حفظ', icon: AppIcons.settled, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One line: what was ordered, how much of it is missing, and what that leaves to pay.
class _LineField extends StatelessWidget {
  const _LineField({
    required this.item,
    required this.controller,
    required this.warehouseController,
    required this.onChanged,
  });

  final OrderItem item;
  final TextEditingController controller;

  /// Null on the lines the warehouse counts the way the invoice does, which is most of them.
  final TextEditingController? warehouseController;

  final ValueChanged<String> onChanged;

  /// What the line will be charged for, given what is in the box right now.
  ///
  /// Null while the box holds something that is not a number — the validator is what says so,
  /// and a red total under a half-typed figure would be shouting at somebody mid-keystroke.
  String? get _billable {
    final ordered = double.tryParse(item.quantity);
    if (ordered == null) return null;

    final text = controller.text.trim();
    final missing = text.isEmpty ? 0.0 : double.tryParse(text);
    if (missing == null || missing < 0 || missing > ordered) return null;

    return (ordered - missing).toStringAsFixed(3);
  }

  /// Whether this line is being taken back to «لا ينقص منها شيء».
  ///
  /// The gesture is emptying the first box, and it has to hide the second: the server refuses a
  /// weight with no shortage behind it, and a validator shouting for a number on a line the user
  /// has just cleared would be the sheet arguing with the thing it was told.
  bool get _isCleared => controller.text.trim().isEmpty;

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final missing = double.tryParse(text);
    if (missing == null) return 'أدخل رقماً';
    if (missing < 0) return 'الناقص لا يكون سالباً';

    final ordered = double.tryParse(item.quantity);
    if (ordered != null && missing > ordered) {
      return 'الناقص أكبر من المطلوب (${item.quantity.grouped})';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final billable = _billable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${item.productName} — ${item.variantLabel}',
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6.h),
        AppTextField(
          controller: controller,
          label: 'الناقص (${item.pricingUnitLabel})',
          prefixIcon: AppIcons.error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Arabic-Indic digits are what the keyboard produces, so they are allowed through and
          // the server normalises them — the same rule every other quantity here follows.
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]'))],
          helperText: 'المطلوب ${item.quantity.grouped} — اتركه فارغاً إذا لم ينقص شيء',
          validator: _validate,
          onChanged: onChanged,
        ),
        if (billable != null) ...[
          SizedBox(height: 6.h),
          Text(
            'يُحاسَب على ${billable.grouped} ${item.pricingUnitLabel} × ${item.unitPriceOrZero.grouped}',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],

        // **The second unit, on the lines that have one.** The box above is the invoice's — it is
        // what the customer stops paying for. This is what will actually be bought and put on the
        // shelf, and no factor in the catalogue turns one into the other, so it is stated rather
        // than converted. Hidden entirely once the line is no longer short: a weight beside no
        // shortage is a measurement of nothing.
        if (warehouseController case final weighed? when !_isCleared) ...[
          SizedBox(height: 10.h),
          AppTextField(
            controller: weighed,
            label: 'الناقص من المخزن (${item.stockUnitLabel ?? ''})',
            prefixIcon: AppIcons.error,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]'))],
            helperText:
                'يُباع بـ${item.pricingUnitLabel} ويُخزَّن بـ${item.stockUnitLabel ?? ''}'
                ' — اتركه فارغاً إن لم يُعرف الوزن بعد، ويُحدَّد قبل تسجيل الشراء',
            validator: (value) {
              final text = value?.trim() ?? '';

              // **Empty is a legitimate answer, and usually the honest one.** The bags are
              // missing, so at the moment somebody declares the shortage there is nothing to put
              // on a scale and no factor that converts the count. Demanding a figure here would
              // ask for a measurement of goods that do not exist. What the gap blocks is
              // recording a *purchase* against the shortage — the server refuses that until the
              // weight is known — not declaring the shortage in the first place.
              if (text.isEmpty) return null;

              final weight = double.tryParse(text);
              if (weight == null) return 'أدخل رقماً';
              if (weight <= 0) return 'الكمية يجب أن تكون أكبر من صفر';

              // No ceiling, deliberately: the ordered figure is in the *other* unit, and
              // measuring a weight against it would be the conversion this box exists because
              // nobody can make.
              return null;
            },
          ),
        ],
      ],
    );
  }
}
