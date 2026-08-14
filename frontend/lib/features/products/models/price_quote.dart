import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_quote.freezed.dart';
part 'price_quote.g.dart';

/// What a quantity of one size costs, and why.
///
/// **The app never works this out.** `QuoteProductPrice` on the server is the single place a
/// price is decided, and an order's line is written from the same code — so a number shown to a
/// customer and the number on their invoice cannot disagree. This model carries that answer and
/// adds nothing to it.
///
/// Every value is a decimal `String`, as everywhere else money is held in this app: `1.100` is
/// what the catalogue printed, and a `double` would render it `1.1` and turn 1.1 × 300 into
/// 330.00000000000006.
@freezed
abstract class PriceQuote with _$PriceQuote {
  const factory PriceQuote({
    required String quantity,

    /// `piece` or `kilogram`, and the Arabic word for it — sent by the server so the app keeps
    /// no translation table.
    required String unit,
    @JsonKey(name: 'unit_label') required String unitLabel,

    @JsonKey(name: 'unit_price') required String unitPrice,
    required String total,

    /// Which quantity break produced this rate — «أنت على سعر ١٠٠ فأكثر».
    @JsonKey(name: 'applied_tier_min_quantity') required String appliedTierMinQuantity,

    /// The saving still on the table. Null when this quantity is already on the best rate.
    @JsonKey(name: 'next_tier') NextPriceTier? nextTier,
  }) = _PriceQuote;

  const PriceQuote._();

  factory PriceQuote.fromJson(Map<String, dynamic> json) => _$PriceQuoteFromJson(json);

  String get quantityLabel => groupedDecimal(quantity);

  String get unitPriceLabel => groupedDecimal(unitPrice);

  String get totalLabel => groupedDecimal(total);

  String get appliedTierLabel => groupedDecimal(appliedTierMinQuantity);
}

/// «اطلب ٧٠٠ أكثر ينزل السعر إلى ٠٫٩٥٠».
///
/// Sent by the server rather than derived here from the tier list: the rule for which break
/// comes next belongs beside the rule that picked the current one.
@freezed
abstract class NextPriceTier with _$NextPriceTier {
  const factory NextPriceTier({
    @JsonKey(name: 'min_quantity') required String minQuantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'quantity_to_reach') required String quantityToReach,
  }) = _NextPriceTier;

  const NextPriceTier._();

  factory NextPriceTier.fromJson(Map<String, dynamic> json) => _$NextPriceTierFromJson(json);

  String get minQuantityLabel => groupedDecimal(minQuantity);

  String get unitPriceLabel => groupedDecimal(unitPrice);

  String get quantityToReachLabel => groupedDecimal(quantityToReach);
}

