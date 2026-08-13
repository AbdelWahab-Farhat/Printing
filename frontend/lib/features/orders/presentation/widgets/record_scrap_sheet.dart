import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_text_field.dart';
import 'package:printing/features/orders/models/order.dart';

/// What the sheet came back with: how many were spoiled, and why.
///
/// Both exactly as they were typed. Cleaning the digits belongs beside the API call — see
/// `RecordScrapLoss` — because this is a form, and a form's answer is what the person entered.
typedef ScrapDraft = ({String quantity, String notes});

/// Writing off bags that were ruined producing a line.
///
/// **There is no price on this form, and that is the design.** The storekeeper counts what went
/// in the bin; the server draws those bags off the shelf and reads what they cost out of the
/// batches they came from. A unit-cost box here would invite somebody to type a number the
/// batches already know better than they do.
///
/// **Nor does anything on the order move.** The line keeps the cost of what it actually
/// fulfilled — `total_cogs` and the profit beside it read the same afterwards — so the sheet says
/// what really changes, which is the warehouse balance. Telling somebody this will be added to
/// the order's cost would be telling them something that does not happen.
///
/// **The reason is required and asks for a sentence.** A scrap row is a quantity that left a
/// shelf with nothing to show for it; without the why, the person reading the ledger a month
/// later has a hole and no one to ask about it.
///
/// Returns the draft, or null when it was dismissed. Sending it is the caller's job — what to do
/// about a refusal belongs to the screen that has somewhere to show it.
Future<ScrapDraft?> showRecordScrapSheet({
  required BuildContext context,
  required OrderItem item,
}) {
  return showModalBottomSheet<ScrapDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RecordScrapSheet(item: item),
  );
}

class _RecordScrapSheet extends StatefulWidget {
  const _RecordScrapSheet({required this.item});

  final OrderItem item;

  @override
  State<_RecordScrapSheet> createState() => _RecordScrapSheetState();
}

class _RecordScrapSheetState extends State<_RecordScrapSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop((quantity: _quantity.text, notes: _notes.text));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final item = widget.item;

    return Padding(
      // The keyboard's height, so the button is never underneath it — this is filled in standing
      // at a machine with one hand.
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
                  'تسجيل تلف',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  'الكمية التالفة تُخصم من مخزن الطلبية، وتكلفتها تُقرأ من دفعات الشراء — '
                  'لا تُدخل سعراً. تكلفة البند وسعر الطلبية لا يتغيّران.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                Text(
                  '${item.productName} — ${item.variantLabel}',
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 10.h),

                AppTextField(
                  controller: _quantity,
                  // **The shelf's unit, not the invoice's.** The server draws this number
                  // straight out of `warehouse_stocks` — the very balance `DeductOrderStock`
                  // reduced by `warehouse_quantity ?? quantity` — so on a line that was weighed
                  // onto the shelf, «قطعة» is the wrong word and «١٠ قطع تالفة» would take ten
                  // kilos off the floor. The app is never told the shelf's unit by name for a
                  // line, so it says which basis it means and anchors on the number that
                  // actually left.
                  label: item.warehouseQuantity == null
                      ? 'الكمية التالفة (${item.pricingUnitLabel})'
                      : 'الكمية التالفة (بوحدة المخزن)',
                  prefixIcon: AppIcons.warehouse,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // Arabic-Indic and Persian digits are what the keyboards produce, and «٫» is
                  // the decimal mark on them. A comma is deliberately not typeable: it reads as
                  // a thousands mark to most people and a decimal to some, and nothing
                  // downstream can tell which — the same rule `record_payment_sheet.dart`
                  // states beside its own box.
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.٫]'))],
                  helperText: item.warehouseQuantity == null
                      ? 'كمية البند ${item.quantity.grouped} ${item.pricingUnitLabel}'
                      : 'خرج من المخزن لهذا البند ${item.warehouseQuantity!.grouped} — والتلف يُخصم بنفس الوحدة',
                  validator: _validateQuantity,
                ),
                SizedBox(height: 16.h),

                AppTextField(
                  controller: _notes,
                  label: 'سبب التلف',
                  hint: 'انحراف في طباعة الشعار',
                  prefixIcon: AppIcons.edit,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  helperText: 'يُقرأ بعد شهر من كتابته — اكتب ما يكفي ليُفهم وحده',
                  validator: _validateNotes,
                ),

                SizedBox(height: 24.h),
                AppButton(label: 'تسجيل التلف', icon: AppIcons.delete, onPressed: _submit),
                SizedBox(height: 8.h),
                AppButton.outlined(
                  label: 'إلغاء',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Only the shape is checked here.
  ///
  /// **Nothing is compared against the line's quantity, and nothing blocks a decimal.** Whether
  /// there is enough on the shelf is the server's answer — it counts the warehouse, not the
  /// order, and a colleague may have moved stock a second ago — and whether this product may be
  /// spoiled by the half-kilo is the server's too: bags sold by the piece refuse a fraction, and
  /// anything sold by weight does not. Both refusals arrive in Arabic, saying both numbers.
  String? _validateQuantity(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'الكمية مطلوبة';

    final quantity = double.tryParse(_westernDigits(text));

    if (quantity == null) return 'الكمية يجب أن تكون رقماً';
    if (quantity <= 0) return 'الكمية يجب أن تكون أكبر من صفر';

    return null;
  }

  /// The same three characters the API asks for, one round trip earlier.
  String? _validateNotes(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'سبب التلف مطلوب';
    if (text.length < 3) return 'سبب التلف قصير جداً';
    if (text.length > 1000) return 'سبب التلف طويل جداً';

    return null;
  }

  /// Enough of a conversion to *validate* the shape, and none of it written here.
  ///
  /// **The box and the validator have to agree on what a number is.** A hand-rolled copy of this
  /// read Arabic-Indic digits only, while the formatter beside it admitted Persian ones too — so
  /// «۱۰», which the box let a person type, was refused as «الكمية يجب أن تكون رقماً» by the
  /// validator underneath it. {@see Validators.toWesternDigits} is what every other numeric
  /// field in this app measures itself against, and it reads both alphabets and «٫».
  ///
  /// It only ever *reads* the text. The field itself is never rewritten — a validator that
  /// changed a number under somebody's finger is a different bug — and the real conversion on
  /// the way to the API still happens beside the call, in `RecordScrapLoss`.
  String _westernDigits(String input) => Validators.toWesternDigits(input);
}
