import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/price_calculator_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of the calculator opened up: its size, its quantity, and the price breaks that
/// decide what one piece costs.
Future<void> showPriceLineSheet({
  required BuildContext context,
  required PriceCalculatorCubit cubit,
  required int lineKey,
  bool autofocus = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
    builder: (_) => BlocProvider<PriceCalculatorCubit>.value(
      value: cubit,
      child: _PriceLineSheet(lineKey: lineKey, autofocus: autofocus),
    ),
  );
}

class _PriceLineSheet extends StatefulWidget {
  const _PriceLineSheet({required this.lineKey, required this.autofocus});

  final int lineKey;
  final bool autofocus;

  @override
  State<_PriceLineSheet> createState() => _PriceLineSheetState();
}

class _PriceLineSheetState extends State<_PriceLineSheet> {
  late final TextEditingController _quantity = TextEditingController(
    text: context.read<PriceCalculatorCubit>().state.lineOf(widget.lineKey)?.quantity ?? '',
  );
  late final TextEditingController _unitPrice = TextEditingController(
    text: context.read<PriceCalculatorCubit>().state.lineOf(widget.lineKey)?.unitPrice ?? '',
  );

  @override
  void dispose() {
    _quantity.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  PriceCalculatorCubit get _cubit => context.read<PriceCalculatorCubit>();

  /// Writes a quantity from a button into the box, then tells the calculator — the same path a
  /// typed one takes.
  void _setQuantity(String value) {
    _quantity.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _cubit.setQuantity(widget.lineKey, value);
  }

  void _step(CalculatorLine line, int direction) {
    final step = line.product.pricingUnit == 'piece' ? 100 : 1;
    final current = num.tryParse(line.westernQuantity) ?? 0;
    final next = current + direction * step;

    _setQuantity(next <= 0 ? '' : trimDecimals(next.toString()));
  }

  void _remove() {
    Navigator.of(context).pop();
    _cubit.remove(widget.lineKey);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceCalculatorCubit, PriceCalculatorState>(
      builder: (context, state) {
        final line = state.lineOf(widget.lineKey);
        // Removed or cleared under the sheet: nothing left to edit.
        if (line == null) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(line: line, onRemove: _remove),
                if (line.product.variants.length > 1) ...[
                  SizedBox(height: 14.h),
                  _SizePicker(
                    line: line,
                    taken: state.variantIds,
                    onPick: (variant) => _cubit.changeVariant(line.key, variant),
                  ),
                ],
                SizedBox(height: 14.h),
                _QuantityInput(
                  controller: _quantity,
                  autofocus: widget.autofocus,
                  unitLabel: line.unitLabel,
                  onChanged: (value) => _cubit.setQuantity(line.key, value),
                  onIncrease: () => _step(line, 1),
                  onDecrease: () => _step(line, -1),
                ),
                if (line.isPricedByHand) ...[
                  SizedBox(height: 12.h),
                  _HandPriceInput(
                    controller: _unitPrice,
                    unitLabel: line.unitLabel,
                    invalid: line.hasInvalidUnitPrice,
                    onChanged: (value) => _cubit.setUnitPrice(line.key, value),
                  ),
                ],
                if (!line.isPricedByHand && line.variant.hasPrices) ...[
                  SizedBox(height: 8.h),
                  _TierShortcuts(variant: line.variant, onPick: _setQuantity),
                  SizedBox(height: 14.h),
                  _TierLadder(line: line),
                ],
                SizedBox(height: 16.h),
                _Footer(line: line, onDone: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.line, required this.onRemove});

  final CalculatorLine line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final product = line.product;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                line.isPricedByHand
                    ? 'يُسعَّر حسب الطلب'
                    : 'يُسعَّر بال${product.pricingUnitLabel} · أقل كمية '
                          '${product.minOrderQuantityLabel}',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onRemove,
          icon: Icon(AppIcons.delete, size: 18.r),
          label: const Text('حذف'),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
        ),
      ],
    );
  }
}

/// Every size of the product. One already on the calculator under another line is shown but
/// shut — two lines of one size would be priced apart, never as the sum the customer buys.
class _SizePicker extends StatelessWidget {
  const _SizePicker({required this.line, required this.taken, required this.onPick});

  final CalculatorLine line;
  final Set<int> taken;
  final ValueChanged<ProductVariant> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المقاس', style: _label(context)),
        SizedBox(height: 6.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final variant in line.product.activeVariants)
              Builder(
                builder: (context) {
                  final selected = variant.id == line.variant.id;
                  final elsewhere = !selected && taken.contains(variant.id);

                  return ChoiceChip(
                    label: Text(elsewhere ? '${variant.label} · مضاف' : variant.label),
                    selected: selected,
                    onSelected: elsewhere ? null : (_) => onPick(variant),
                    showCheckmark: false,
                    selectedColor: scheme.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onPrimary : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _QuantityInput extends StatelessWidget {
  const _QuantityInput({
    required this.controller,
    required this.autofocus,
    required this.unitLabel,
    required this.onChanged,
    required this.onIncrease,
    required this.onDecrease,
  });

  final TextEditingController controller;
  final bool autofocus;
  final String unitLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.outlined(
          onPressed: onIncrease,
          icon: Icon(AppIcons.add),
          tooltip: 'زيادة',
          constraints: BoxConstraints.tight(Size(52.r, 52.r)),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: AppTextField(
            controller: controller,
            label: 'الكمية ($unitLabel)',
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 8.w),
        IconButton.outlined(
          onPressed: onDecrease,
          icon: Icon(AppIcons.remove),
          tooltip: 'إنقاص',
          constraints: BoxConstraints.tight(Size(52.r, 52.r)),
        ),
      ],
    );
  }
}

/// The clerk's own price for a product the catalogue prices «حسب الطلب». Optional on purpose:
/// left empty, the line goes to the customer as «السعر حسب الطلب» and stays out of the total.
class _HandPriceInput extends StatelessWidget {
  const _HandPriceInput({
    required this.controller,
    required this.unitLabel,
    required this.invalid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String unitLabel;
  final bool invalid;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'سعر ال$unitLabel (اختياري)',
      hint: 'مثال: 1.5',
      suffix: const Text('د.ل'),
      helperText: invalid ? null : 'اتركه فارغاً ليظهر «السعر حسب الطلب»',
      errorText: invalid ? 'اكتب سعراً صحيحاً، مثل 1.5' : null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
      onChanged: onChanged,
    );
  }
}

/// One tap to each price break: the quantities where the price of a piece actually changes,
/// which are the numbers worth offering a customer who is deciding how many to take.
class _TierShortcuts extends StatelessWidget {
  const _TierShortcuts({required this.variant, required this.onPick});

  final ProductVariant variant;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final breaks = [
      for (final tier in variant.tiersByQuantity)
        if ((num.tryParse(tier.minQuantity) ?? 0) > 1) trimDecimals(tier.minQuantity),
    ];
    if (breaks.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.w,
      runSpacing: 6.h,
      children: [
        for (final quantity in breaks)
          ActionChip(label: Text(groupedDecimal(quantity)), onPressed: () => onPick(quantity)),
      ],
    );
  }
}

/// The size's price breaks, with the one this quantity falls in marked — so «why is it 0.95
/// and not 0.85» is answered on the screen rather than by the clerk from memory.
class _TierLadder extends StatelessWidget {
  const _TierLadder({required this.line});

  final CalculatorLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quote = line.quote.quote;
    final applied = num.tryParse(quote?.appliedTierMinQuantity ?? '');
    final quantity = num.tryParse(line.westernQuantity);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.surfaceContainerLow,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            child: Text('شرائح السعر لهذا المقاس', style: _label(context)),
          ),
          for (final tier in line.variant.tiersByQuantity)
            Builder(
              builder: (context) {
                final min = num.tryParse(tier.minQuantity) ?? 0;
                final isApplied = applied != null && min == applied;
                final missing = quantity != null && min > quantity ? min - quantity : null;
                final style = context.textTheme.bodyMedium?.copyWith(
                  fontWeight: isApplied ? FontWeight.w800 : FontWeight.w500,
                  color: isApplied ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                );

                return Container(
                  color: isApplied ? scheme.primaryContainer : null,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            'من ${tier.minQuantityLabel} ${line.product.pricingUnitLabel}',
                            if (isApplied) 'سعرك الحالي',
                            if (missing != null)
                              'ينقصك ${groupedDecimal(trimDecimals(missing.toString()))}',
                          ].join(' · '),
                          style: style,
                        ),
                      ),
                      Text('${groupedDecimal(tier.unitPrice)} د.ل', style: style),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.line, required this.onDone});

  final CalculatorLine line;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (caption, amount, color) = switch (line.quote) {
      LineQuotePriced(:final quote) => (
        '${quote.quantityLabel} × ${quote.unitPriceLabel}',
        '${quote.totalLabel} د.ل',
        scheme.primary,
      ),
      LineQuoteFailure(:final failure) => (failure.message, '—', scheme.error),
      LineQuoteLoading() => ('جارٍ التسعير…', '…', scheme.onSurfaceVariant),
      LineQuoteByHand() => switch ((line.entry.unitPrice, line.entry.total)) {
        (final price?, final total?) => (
          '${line.entry.quantityLabel} × ${groupedDecimal(price)} · سعر يدوي',
          '${groupedDecimal(total)} د.ل',
          scheme.primary,
        ),
        _ => ('السعر حسب الطلب', '—', scheme.onSurfaceVariant),
      },
      LineQuoteIdle() => ('أدخل الكمية ليُحسب السعر', '—', scheme.onSurfaceVariant),
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: context.textTheme.bodySmall?.copyWith(
                  color: line.quote is LineQuoteFailure ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
              Text(
                amount,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        AppButton(label: 'تم', onPressed: onDone, expands: false),
      ],
    );
  }
}

TextStyle? _label(BuildContext context) => context.textTheme.labelMedium?.copyWith(
  color: context.colorScheme.onSurfaceVariant,
  fontWeight: FontWeight.w700,
);
