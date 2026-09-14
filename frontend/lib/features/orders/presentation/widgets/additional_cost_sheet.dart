import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the clerk typed: an amount, the category it goes under, and the words beside it.
///
/// The sheet answers and the caller sends — the same split every other form on the order screen
/// follows. What to do about a refusal belongs to the screen that has somewhere to show it.
///
/// **It is also what the sheet opens on**, which is what lets one sheet serve both screens: on
/// «تعديل الطلبية» the draft is read off an order that exists, and on «طلبية جديدة» it is the
/// answer to the last time the sheet was opened — because there is no order to read yet.
@immutable
class AdditionalCostDraft {
  const AdditionalCostDraft({required this.amount, this.reason, this.note});

  /// What an order already carries, so correcting «١٠» to «١٥» is one keystroke — and a charge
  /// of nothing opens on an empty box rather than on a `0.00` to be cleared first.
  ///
  /// **Never [AdditionalCostReason.unknown]:** a category this build does not know cannot be
  /// re-picked from five chips that do not include it, and re-sending it would be this app
  /// claiming a code it cannot name.
  factory AdditionalCostDraft.of(Order order) => AdditionalCostDraft(
    amount: order.hasAdditionalCost ? trimDecimals(order.additionalCost) : '',
    reason: switch (order.additionalCostReason) {
      final reason? when reason != AdditionalCostReason.unknown => reason,
      _ => null,
    },
    note: order.additionalCostNote,
  );

  /// As typed, Arabic-Indic digits and all: normalising is [UpdateOrderInvoice]'s job — and
  /// [TakeOrder]'s — in one place, for every numeric field on this feature.
  final String amount;

  final AdditionalCostReason? reason;
  final String? note;

  /// The amount in ASCII digits — `'٢٥٫٥'` as typed becomes `'25.5'`.
  ///
  /// **For drawing it, not for sending it.** The shop reads Latin digits on a phone held at
  /// arm's length, which is why nothing in this app renders Arabic-Indic ones — see `digits.dart`.
  /// What goes down the wire is still normalised in one place on the way out, by [TakeOrder] or
  /// [UpdateOrderInvoice], from [amount] as it was typed.
  String get normalisedAmount =>
      Validators.toWesternDigits(amount.trim()).replaceAll(',', '.');

  /// Whether there is money here at all. The sheet's own rule — a category without an amount is
  /// not a charge — read back by the screens that draw what was answered.
  bool get isCharging => (double.tryParse(normalisedAmount) ?? 0) > 0;

  /// The charge as one line, in the words the invoice will use for it — «نقل — للفرع».
  ///
  /// Null when nothing is being charged. The category's Arabic is the enum's here and the
  /// server's on an order that exists; the rule joining it to the note is the same one, so the
  /// form and the invoice say the sentence the same way. See [AdditionalCostReason.caption].
  String? get caption => isCharging
      ? AdditionalCostReason.caption(
          label: reason?.label,
          needsNote: reason?.needsNote ?? false,
          note: note,
        )
      : null;
}

/// Charging the customer for something no line on the order describes — «تغليف خاص»، «نقل».
///
/// **A sheet rather than three more boxes on a form**, because the charge is agreed in one
/// moment — a box asked for at the counter, a run to a second address — and it is answered in
/// that moment. **The same sheet on both screens**, so the five categories and the two rules
/// are one vocabulary rather than two copies of one that drift.
///
/// What differs is the sending, and it belongs to the caller: «تعديل الطلبية» sends the answer
/// on its own the moment the sheet closes, because the order exists; «طلبية جديدة» holds it
/// until «إنشاء الطلبية», because there is nothing yet to send it against.
///
/// **The five chips are the whole vocabulary, and they are not this app's.** They mirror
/// `AdditionalCostReason.php` because the figure is read along that axis afterwards — «كم حصّلنا
/// مقابل التغليف هذا الربع؟» — and a free-text box answers that question with four spellings of
/// one word.
///
/// **Two rules are checked here as well as on the server**, and neither is invented: a reason is
/// required as soon as there is an amount, and «أخرى» needs words of its own. Checking locally
/// only makes the refusal instant; the server still owns both, and its Arabic is what a
/// disagreement shows.
///
/// Returns null when dismissed — backing out of a form is an ordinary ending.
Future<AdditionalCostDraft?> showAdditionalCostSheet({
  required BuildContext context,

  /// What the sheet opens on — the order's charge, or the last answer given on a form whose
  /// order does not exist yet. Null opens it empty.
  AdditionalCostDraft? initial,
}) {
  return showModalBottomSheet<AdditionalCostDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => _AdditionalCostSheet(initial: initial),
  );
}

class _AdditionalCostSheet extends StatefulWidget {
  const _AdditionalCostSheet({this.initial});

  final AdditionalCostDraft? initial;

  @override
  State<_AdditionalCostSheet> createState() => _AdditionalCostSheetState();
}

class _AdditionalCostSheetState extends State<_AdditionalCostSheet> {
  final _formKey = GlobalKey<FormState>();

  /// Opened on what was already agreed — see [AdditionalCostDraft.of] for where an order's own
  /// charge is turned into one of these.
  late final TextEditingController _amount = TextEditingController(
    text: widget.initial?.amount ?? '',
  );

  late final TextEditingController _note = TextEditingController(
    text: widget.initial?.note ?? '',
  );

  late AdditionalCostReason? _reason = widget.initial?.reason;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Whether the box holds a real charge — which is what makes the reason required.
  bool get _isCharging {
    final typed = Validators.toWesternDigits(_amount.text.trim()).replaceAll(',', '.');

    return (double.tryParse(typed) ?? 0) > 0;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      AdditionalCostDraft(
        amount: _amount.text,
        reason: _isCharging ? _reason : null,
        note: _isCharging ? _note.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final needsNote = _reason?.needsNote ?? false;

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
                  'التكلفة الإضافية',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  // What it does to the invoice, said before it is typed rather than discovered
                  // on a total afterwards.
                  'تُضاف إلى إجمالي الطلبية ويُطلب من الزبون دفعها. أفرغ الحقل لإلغائها.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                AppTextField(
                  controller: _amount,
                  label: 'المبلغ',
                  prefixIcon: AppIcons.payment,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  // Arabic-Indic digits are what the keyboard produces, so they are allowed
                  // through and normalised on the way out — the rule every other amount on this
                  // feature follows.
                  //
                  // **«٫» is in the set, and it has to be.** It is the decimal separator an
                  // Arabic keyboard offers, `Validators.toWesternDigits` already turns it into a
                  // point — and a formatter that strips it as it is typed turns «١٠٫٥» into
                  // «١٠٥» on its way to a money field, with nothing on screen to show for it.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,٫]')),
                  ],
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;

                    final amount = double.tryParse(
                      Validators.toWesternDigits(text).replaceAll(',', '.'),
                    );

                    if (amount == null) return 'أدخل رقماً';
                    if (amount < 0) return 'التكلفة الإضافية لا تكون سالبة';

                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 18.h),

                Text(
                  'السبب',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 10.h),
                // Chips rather than a `SegmentedButton`: five Arabic labels do not fit one row
                // at 430 wide, and a segment squeezed to three characters names nothing.
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final reason in AdditionalCostReason.choices)
                      FilterOptionChip(
                        label: reason.label,
                        isSelected: _reason == reason,
                        // Tapping the picked one clears it, so a category chosen by mistake on
                        // an order that is not being charged can be taken back.
                        onTap: () => setState(
                          () => _reason = _reason == reason ? null : reason,
                        ),
                      ),
                  ],
                ),
                // The server's own rule, said where it can be acted on rather than as a 422
                // about a field the clerk thought they had filled in.
                if (_isCharging && _reason == null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'اختر سبب التكلفة الإضافية',
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                SizedBox(height: 18.h),

                AppTextField(
                  controller: _note,
                  label: needsNote ? 'السبب' : 'ملاحظة (اختياري)',
                  prefixIcon: AppIcons.notes,
                  maxLines: 2,
                  validator: (value) {
                    if (!_isCharging || !needsNote) return null;

                    return (value?.trim().isEmpty ?? true)
                        ? 'اكتب سبب التكلفة الإضافية عند اختيار «أخرى»'
                        : null;
                  },
                ),
                SizedBox(height: 20.h),

                AppButton(
                  label: 'حفظ',
                  icon: AppIcons.settled,
                  // Disabled rather than refused: the one rule a person can see the answer to
                  // from here is «سبب بلا مبلغ», and a button that argues back on tap is worse
                  // than one that waits.
                  onPressed: _isCharging && _reason == null ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
