import 'dart:async';

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/line_quote_cubit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One line of an order being taken, as the form holds it.
///
/// The two text controllers and the Cubit are widget-lifecycle resources — they belong to the
/// screen's `State`, which is what disposes them. Held together in one object so a line is
/// added and removed as a unit rather than as three parallel lists that can fall out of step.
class OrderLineDraft {
  OrderLineDraft({required this.product, required this.variant, required this.quote}) {
    // A bag the catalogue prices «حسب الطلب» has no answer to fetch — asking would only ever
    // produce `ProductRequiresManualQuote`. The line says so from the moment it is added.
    if (isPricedByHand) quote.priceByHand();
  }

  final Product product;
  final ProductVariant variant;

  /// This line's own price, re-asked as the quantity is typed. One per line, not one per screen.
  final LineQuoteCubit quote;

  final TextEditingController quantity = TextEditingController();

  /// Only ever filled for [isPricedByHand]. For everything else the catalogue's rate wins and
  /// a number typed here would be ignored by the server anyway.
  final TextEditingController unitPrice = TextEditingController();

  /// What actually comes off the shelf for this line, when that is not the quantity sold.
  ///
  /// Left empty on nearly every line — see [isWeighedOffTheShelf].
  final TextEditingController warehouseQuantity = TextEditingController();

  /// Whether a person names the price on this line.
  ///
  /// `has_listed_prices` is the server's own answer about the product, not a rule re-derived
  /// here from the pricing mode.
  bool get isPricedByHand => !product.hasListedPrices;

  /// Whether this line may leave the warehouse in a unit other than the one it is sold in.
  ///
  /// **Only a line sold by the piece.** A run priced by the kilo is already counted the way the
  /// shelf counts it, so the ordered quantity is exactly what leaves — there is nothing to
  /// convert and nothing to ask. Bags sold by the piece are the case the scale exists for: forty
  /// of them are weighed together, and no per-piece factor would give the same answer.
  bool get isWeighedOffTheShelf => product.pricingUnit == 'piece';

  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
    warehouseQuantity.dispose();
    unawaited(quote.close());
  }
}

/// One line on the form: what it is, how many, and what that costs.
///
/// **The price under the box is the server's.** Every change of quantity asks the catalogue
/// again — after a pause, so a three-digit number is one request rather than three — and what
/// comes back is shown as sent, including a refusal: «أقل كمية لهذا المنتج هي ١٠٠ قطعة» is a
/// useful thing to read while typing, and far better than a blank.
class OrderLineRow extends StatefulWidget {
  const OrderLineRow({
    required this.line,
    required this.onChanged,
    required this.onRemove,
    this.quantityError,
    this.unitPriceError,
    this.warehouseQuantityError,
    super.key,
  });

  final OrderLineDraft line;

  /// Fired on every keystroke, so the screen above can re-evaluate whether the form is complete
  /// and clear a stale refusal from the last submit.
  final VoidCallback onChanged;

  final VoidCallback onRemove;

  /// The server's complaint about this line, if the last submit produced one.
  final String? quantityError;
  final String? unitPriceError;
  final String? warehouseQuantityError;

  @override
  State<OrderLineRow> createState() => _OrderLineRowState();
}

class _OrderLineRowState extends State<OrderLineRow> {
  Timer? _debounce;

  /// Long enough that typing «300» is one request, short enough that the price appears while
  /// the clerk is still looking at the box.
  static const Duration _pause = Duration(milliseconds: 400);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuantity(String value) {
    widget.onChanged();

    if (widget.line.isPricedByHand) return;

    _debounce?.cancel();
    _debounce = Timer(_pause, () {
      if (!mounted) return;

      widget.line.quote.quote(
        productId: widget.line.product.id,
        variantId: widget.line.variant.id,
        quantity: value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final line = widget.line;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: scheme.outlineVariant),
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
                      line.product.name,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      line.variant.label,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(AppIcons.delete, size: 20.r),
                tooltip: 'حذف البند',
                color: scheme.error,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AppTextField(
            controller: line.quantity,
            label: 'الكمية',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
            errorText: widget.quantityError,
            onChanged: _onQuantity,
          ),
          if (line.isPricedByHand) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: line.unitPrice,
              label: 'سعر الوحدة',
              // Said here rather than in a note under the section: this box exists for this
              // product and no other, and the reason belongs beside it.
              helperText: 'هذا المنتج يُسعَّر حسب الطلب',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
              errorText: widget.unitPriceError,
              onChanged: (_) => widget.onChanged(),
            ),
          ],
          if (line.isWeighedOffTheShelf) ...[
            SizedBox(height: 8.h),
            AppTextField(
              controller: line.warehouseQuantity,
              label: 'الكمية المخصومة من المخزن (اختياري)',
              // Beside the box, like the manual price above it, because the reason is about
              // this line and nothing else on the screen.
              helperText: 'اتركه فارغاً إن كان المخزن يُنقص بنفس الكمية المباعة',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[-+ ]'))],
              errorText: widget.warehouseQuantityError,
              onChanged: (_) => widget.onChanged(),
            ),
          ],
          SizedBox(height: 8.h),
          BlocBuilder<LineQuoteCubit, LineQuoteState>(
            bloc: line.quote,
            builder: (context, state) => _Price(state: state),
          ),
        ],
      ),
    );
  }
}

/// What the catalogue said about this line — or why it said nothing.
class _Price extends StatelessWidget {
  const _Price({required this.state});

  final LineQuoteState state;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final small = context.textTheme.bodySmall;

    return switch (state) {
      LineQuoteIdle() => Text(
        'أدخل الكمية ليُحسب السعر',
        style: small?.copyWith(color: scheme.onSurfaceVariant),
      ),
      LineQuoteByHand() => Text(
        'السعر من عندك — الكتالوج لا يسعّر هذا المنتج',
        style: small?.copyWith(color: scheme.onSurfaceVariant),
      ),
      LineQuoteLoading() => Row(
        children: [
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8.w),
          Text('جارٍ التسعير…', style: small?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
      // The server's sentence, shown as sent: «أقل كمية…», «لا يوجد سعر لهذه الكمية».
      LineQuoteFailure(:final failure) => Text(
        failure.message,
        style: small?.copyWith(color: scheme.error),
      ),
      LineQuotePriced(:final quote) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${quote.unitPriceLabel} د.ل × ${quote.quantityLabel} '
            '${quote.unitLabel} = ${quote.totalLabel} د.ل',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          if (quote.nextTier case final next?)
            Text(
              // The saving still on the table, which is the one thing a clerk can act on while
              // the customer is still on the phone.
              'أضف ${next.quantityToReachLabel} ليصبح السعر ${next.unitPriceLabel} د.ل',
              style: small?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    };
  }
}
