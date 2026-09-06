import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the sheet came back with: the new price, how much of the layer it applies to, and why.
///
/// [quantity] null is «كل المتبقي» — the absent key the API reads as the whole layer. Normalising
/// the digits belongs beside the call, in `RevalueStockBatch`; this is a form, and a form's
/// answer is what the person entered.
typedef RevaluationDraft = ({String unitCost, String? quantity, String reason});

/// Correcting what a quantity of stock is carried at — **the only write a cost layer accepts**.
///
/// **The sheet exists for its warning, not for its price box.** Two consequences are invisible
/// from the shelf and both are irreversible in the ordinary sense: what has already been issued
/// off this layer keeps the cost it left at, so the orders that took it keep the profit they were
/// closed with; and repricing part of a layer *splits* it, leaving a second layer behind at the
/// old price. Neither can be undone by editing anything — only by another correction, which
/// leaves its own row in the record.
///
/// So the sheet says what will happen, in the layer's own numbers, before the button is tapped.
///
/// Returns the draft, or null when it was dismissed. Sending it is the caller's job — what to do
/// about a refusal belongs to the screen that has somewhere to show it.
Future<RevaluationDraft?> showRevalueBatchSheet({
  required BuildContext context,
  required StockBatch batch,
}) {
  return showModalBottomSheet<RevaluationDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RevalueBatchSheet(batch: batch),
  );
}

class _RevalueBatchSheet extends StatefulWidget {
  const _RevalueBatchSheet({required this.batch});

  final StockBatch batch;

  @override
  State<_RevalueBatchSheet> createState() => _RevalueBatchSheetState();
}

class _RevalueBatchSheetState extends State<_RevalueBatchSheet> {
  final _formKey = GlobalKey<FormState>();

  /// Prefilled with the price it carries — **except on a layer nobody ever priced**, where the
  /// stored `0.000` is not a figure anybody chose and offering it back would invite a person to
  /// confirm it by mistake.
  late final TextEditingController _cost = TextEditingController(
    text: widget.batch.isUncosted ? '' : widget.batch.unitCostLabel,
  );
  final _quantity = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _cost.dispose();
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final quantity = _quantity.text.trim();

    Navigator.of(context).pop((
      unitCost: _cost.text.trim(),
      quantity: quantity.isEmpty ? null : quantity,
      reason: _reason.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final batch = widget.batch;

    return Padding(
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
                  'تصحيح تكلفة الدفعة',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12.h),

                // Which layer this is, in the words the row above it used.
                Text(
                  [batch.sourceTypeLabel, ?batch.receivedAt?.dayLabel].join(' · '),
                  style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.h),
                Text(
                  batch.isUncosted
                      ? 'متبقي ${batch.remainingLabel} ${batch.unitLabel} · بلا تكلفة'
                      : 'متبقي ${batch.remainingLabel} ${batch.unitLabel} · '
                            '${batch.unitCostLabel} د.ل/${batch.unitLabel}',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 20.h),

                AppTextField(
                  key: const Key('revalue-cost'),
                  controller: _cost,
                  label: 'التكلفة الجديدة (د.ل/${batch.unitLabel})',
                  prefixIcon: AppIcons.payment,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  // The digits an Arabic keyboard actually produces, «٫» included. A comma is
                  // deliberately not typeable: it reads as a thousands mark to most people and a
                  // decimal to some, and nothing downstream can tell which.
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.٫]'))],
                  validator: _validateCost,
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 16.h),

                AppTextField(
                  key: const Key('revalue-quantity'),
                  controller: _quantity,
                  label: 'الكمية المراد تصحيحها (اتركها فارغة لكل المتبقي)',
                  prefixIcon: AppIcons.warehouse,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.٫]'))],
                  validator: Validators.optional(Validators.decimal(allowZero: false, min: 0)),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 16.h),

                AppTextField(
                  key: const Key('revalue-reason'),
                  controller: _reason,
                  label: 'سبب التصحيح',
                  hint: 'فاتورة المورد وصلت بسعر مختلف',
                  prefixIcon: AppIcons.edit,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: _validateReason,
                ),
                SizedBox(height: 20.h),

                _WhatWillHappen(batch: batch, unitCost: _cost.text, quantity: _quantity.text),

                SizedBox(height: 24.h),
                AppButton(label: 'تصحيح التكلفة', icon: AppIcons.activate, onPressed: _submit),
                SizedBox(height: 8.h),
                AppButton.outlined(label: 'إلغاء', onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shape only, and **zero is allowed**: correcting a layer down to nothing — stock that turned
  /// out to be a supplier's sample — is a decision the API accepts and somebody may need to
  /// record.
  String? _validateCost(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'تكلفة الوحدة مطلوبة';

    final cost = double.tryParse(Validators.toWesternDigits(text).replaceAll(',', '.'));

    if (cost == null) return 'تكلفة الوحدة يجب أن تكون رقماً';
    if (cost < 0) return 'تكلفة الوحدة يجب ألا تكون سالبة';

    return null;
  }

  /// The API's own three characters, one round trip earlier. **Nothing here is compared against
  /// what is left on the layer** — an order going to print a second ago moves that number, and
  /// the server refuses with both figures in the sentence.
  String? _validateReason(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'سبب التصحيح مطلوب';
    if (text.length < 3) return 'سبب التصحيح قصير جداً';
    if (text.length > 1000) return 'سبب التصحيح طويل جداً';

    return null;
  }
}

/// The consequences, in the layer's own numbers, live as the boxes are filled in.
///
/// Not prose about how costing works: every line here is arithmetic on figures already on the
/// screen, and each one is a thing that will be different afterwards.
class _WhatWillHappen extends StatelessWidget {
  const _WhatWillHappen({required this.batch, required this.unitCost, required this.quantity});

  final StockBatch batch;
  final String unitCost;
  final String quantity;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final lines = _lines();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, line) in lines.indexed) ...[
            if (index > 0) SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  line.warns ? AppIcons.error : AppIcons.activate,
                  size: 16.sp,
                  color: line.warns ? scheme.warn : scheme.onSurfaceVariant,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    line.text,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: line.warns ? scheme.warn : scheme.onSurface,
                      fontWeight: line.warns ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// What is about to change, then what is not.
  List<({String text, bool warns})> _lines() {
    final unit = batch.unitLabel;
    final remaining = batch.quantityRemaining;
    final price = _number(unitCost);
    final asked = _number(quantity);

    // A quantity larger than the layer holds is read as «كل المتبقي» here rather than drawn as a
    // negative remainder: the server refuses it under the lock, with both figures in the
    // sentence, and a preview cannot know what is left better than the row it was read from.
    final repriced = asked == null || thousandths(asked) >= thousandths(remaining)
        ? remaining
        : asked;
    final leftBehind = subtractDecimals(remaining, repriced);
    final splits = thousandths(leftBehind) > BigInt.zero;

    return [
      if (price != null)
        (
          text: splits
              ? 'سيُصحَّح ${groupedDecimal(repriced)} $unit إلى ${groupedDecimal(price)} د.ل — '
                    'قيمتها ${groupedDecimal(multiplyToMoney(repriced, price))} د.ل'
              : 'سيُصحَّح كل المتبقي ${groupedDecimal(remaining)} $unit إلى '
                    '${groupedDecimal(price)} د.ل — قيمته '
                    '${groupedDecimal(multiplyToMoney(remaining, price))} د.ل',
          warns: false,
        ),
      if (splits)
        (
          text: 'ويبقى ${groupedDecimal(leftBehind)} $unit بسعرها القديم في دفعة منفصلة — '
              'المصحَّحة تُصرف أولاً',
          warns: true,
        ),
      if (batch.isPartlyConsumed)
        (
          text: 'صُرف منها ${groupedDecimal(batch.quantityConsumed)} $unit بتكلفتها القديمة، '
              'ولا تتغيّر تكلفة الطلبيات التي أخذتها',
          warns: true,
        ),
      if (batch.purchaseOrderId case final orderId?)
        (text: 'الدفعة من أمر شراء #$orderId — قد تخالفها فاتورة المورد', warns: true),
    ];
  }

  /// The box's text as a figure, or null while it is empty or half-typed.
  static String? _number(String input) {
    final text = Validators.toWesternDigits(input.trim()).replaceAll(',', '.');
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);

    return parsed == null || parsed < 0 ? null : text;
  }
}
