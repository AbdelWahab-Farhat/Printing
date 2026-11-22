part of 'price_calculator_cubit.dart';

/// Everything the calculator holds: the lines, in the order they were added.
///
/// **A record of lines rather than a union of screen states.** Nothing here loads as a whole —
/// each line asks for its own price and fails on its own — so the loading and the refusals live
/// on the line ([CalculatorLine.quote]), each one already a closed union.
@freezed
abstract class PriceCalculatorState with _$PriceCalculatorState {
  const factory PriceCalculatorState({@Default(<CalculatorLine>[]) List<CalculatorLine> lines}) =
      _PriceCalculatorState;

  const PriceCalculatorState._();

  bool get isEmpty => lines.isEmpty;

  /// Whether every line has what the message needs: a price from the catalogue, or a quantity
  /// on a line the catalogue does not price. Until then the total and the message stay shut —
  /// a sum that leaves out a line still being typed is a number somebody reads down a phone.
  bool get isComplete => lines.isNotEmpty && lines.every((line) => line.isReady);

  Set<int> get variantIds => {for (final line in lines) line.variant.id};

  List<EstimateEntry> get entries => [
    for (final line in lines)
      if (line.isReady) line.entry,
  ];

  /// Null until [isComplete], and while nothing on the list carries a price.
  String? get total => isComplete ? estimateTotal(entries) : null;

  String get message => priceEstimateMessage(entries);

  CalculatorLine? lineOf(int key) {
    for (final line in lines) {
      if (line.key == key) return line;
    }

    return null;
  }
}

/// One size of one product on the calculator.
@freezed
abstract class CalculatorLine with _$CalculatorLine {
  const factory CalculatorLine({
    /// The calculator's own handle on the line. Not the variant id: the size of a line can be
    /// changed in place, and the line must stay the same line while it is.
    required int key,
    required Product product,
    required ProductVariant variant,

    /// As typed, digits and all — Arabic-Indic included. [GetPriceQuote] normalises on the way
    /// out, and the box keeps showing what the clerk typed.
    @Default('') String quantity,
    @Default(LineQuoteState.idle()) LineQuoteState quote,

    /// The clerk's price for one unit, as typed — only on a line the catalogue does not price.
    /// Optional: left empty, the line goes out as «السعر حسب الطلب».
    @Default('') String unitPrice,
  }) = _CalculatorLine;

  const CalculatorLine._();

  bool get isPricedByHand => !product.hasListedPrices;

  String get westernQuantity => Validators.toWesternDigits(quantity.trim()).replaceAll(',', '.');

  /// The typed price made into money, or null — empty, or not an amount ([parseHandPrice]).
  String? get handUnitPrice =>
      isPricedByHand ? parseHandPrice(Validators.toWesternDigits(unitPrice)) : null;

  /// Something was typed in the price box that is not a price.
  bool get hasInvalidUnitPrice => unitPrice.trim().isNotEmpty && handUnitPrice == null;

  String get unitLabel => quote.quote?.unitLabel ?? product.pricingUnitLabel;

  bool get isReady => switch (quote) {
    LineQuotePriced() => true,
    LineQuoteByHand() => westernQuantity.isNotEmpty,
    _ => false,
  };

  EstimateEntry get entry => EstimateEntry(
    productName: product.name,
    sizeLabel: variant.label,
    quantity: westernQuantity,
    unitLabel: unitLabel,
    quote: quote.quote,
    handUnitPrice: handUnitPrice,
  );
}
