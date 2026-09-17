import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// A catalogue heading, as a filter chip.
@freezed
abstract class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required int id,
    required String name,
    @JsonKey(name: 'parent_id') int? parentId,
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _ProductCategory;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);
}

/// A quantity break: order this many, pay this per unit.
///
/// **Both numbers are decimal strings, never doubles.** `1.10` has no exact float
/// representation, and a price that arrives as `1.1000000000000001` is not the price the
/// catalogue printed. Every amount in this app follows the same rule.
@freezed
abstract class PriceTier with _$PriceTier {
  const factory PriceTier({
    required int id,
    @JsonKey(name: 'min_quantity') required String minQuantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
  }) = _PriceTier;

  factory PriceTier.fromJson(Map<String, dynamic> json) => _$PriceTierFromJson(json);
}

/// One size of a product.
///
/// **No cost price, and none is coming.** What the shop pays is guarded on the staff side by
/// `products.view_cost`; the customer resource has never heard of the field. See
/// Docs/customer-app/CUSTOMER-APP-DESIGN.md §٤ — what a customer sees is a field list, not a
/// permission check.
@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required int id,

    /// «25*35» — what the customer picks from.
    required String label,

    @JsonKey(name: 'width_cm') num? widthCm,
    @JsonKey(name: 'height_cm') num? heightCm,
    @JsonKey(name: 'price_tiers') @Default(<PriceTier>[]) List<PriceTier> priceTiers,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}

/// A product photo. Public, unlike a customer's design — this is the business's own marketing.
@freezed
abstract class ProductImage with _$ProductImage {
  const factory ProductImage({
    required int id,
    required String url,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'alt_text') String? altText,
  }) = _ProductImage;

  factory ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);
}

/// Something the shop sells.
///
/// Roughly half of what the staff app reads. Absent by design: the material and the shelf it
/// draws from, whether it is made in our press or at a vendor's bench, whose money bought the
/// stock, and the catalogue's own housekeeping — the customer is only ever sent the live
/// catalogue, in its order.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required int id,
    required String name,

    /// «P7» — what a person says out loud when they ring about it.
    String? code,
    String? slug,
    String? description,
    @Default(<String>[]) List<String> features,

    @JsonKey(name: 'product_category') ProductCategory? category,
    @JsonKey(name: 'product_category_id') int? categoryId,

    /// What the customer is charged by — piece, kilogram — with its Arabic beside it, so this
    /// app keeps no translation table of its own.
    @JsonKey(name: 'pricing_unit') String? pricingUnit,
    @JsonKey(name: 'pricing_unit_label') String? pricingUnitLabel,

    /// **Draw a price, or draw «اطلب عرض سعر».** The decided answer rather than the pricing mode
    /// behind it — this app never learns what the modes are.
    /// Which products this one may share an order with — **a token, not a reason.**
    ///
    /// The server sends two of these and never says what they mean: «what the category means for
    /// production is not on this side of the wall» — see `ClientProductResource`. Two products
    /// may go in one basket when their tokens match, and this app never learns why they do.
    ///
    /// Defaulted rather than required so an older server, or a product resource that omits it,
    /// leaves every product in one basket instead of splitting the catalogue in two by accident.
    /// The refusal that matters is the server's: `CreateOrder` throws
    /// `OutsourcedLineCannotShareAnOrder` whatever any client believes.
    @JsonKey(name: 'order_group') @Default('shared') String orderGroup,

    @JsonKey(name: 'has_listed_prices') @Default(true) bool hasListedPrices,

    @JsonKey(name: 'min_order_quantity') String? minOrderQuantity,

    @Default(<ProductVariant>[]) List<ProductVariant> variants,
    @Default(<ProductImage>[]) List<ProductImage> images,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

extension ProductX on Product {
  /// The picture the grid draws: the primary one, or the first there is.
  String? get primaryImageUrl {
    if (images.isEmpty) return null;

    for (final image in images) {
      if (image.isPrimary) return image.url;
    }

    return images.first.url;
  }

  /// «٤ مقاسات» — how many sizes this product comes in.
  int get variantCount => variants.length;

  /// «٢٥×٣٥ … ٤٥×٦٠ سم» — the smallest size and the largest, which is what a grid card can say
  /// about a product without listing every one.
  ///
  /// **Ordered by area, not by width.** A 25×35 and a 30×20 cannot be compared on one edge, and
  /// the pair this returns has to be the genuinely smallest and largest or the range is a lie.
  /// Null when the server sent no dimensions — some products are sold by weight, and those have
  /// a `label` but no centimetres.
  String? get sizeRange {
    final sized =
        variants
            .where((variant) => variant.widthCm != null && variant.heightCm != null)
            .toList()
          ..sort(
            (a, b) => (a.widthCm! * a.heightCm!).compareTo(b.widthCm! * b.heightCm!),
          );

    if (sized.isEmpty) return null;

    String dimensions(ProductVariant variant) =>
        '${_trim(variant.widthCm!)}×${_trim(variant.heightCm!)}';

    // One size is a size, not a range — «٢٥×٣٥ … ٢٥×٣٥» reads as a mistake.
    if (sized.length == 1) return '${dimensions(sized.first)} سم';

    return '${dimensions(sized.first)} … ${dimensions(sized.last)} سم';
  }

  /// `25` rather than `25.0`: the dimensions arrive as numbers and whole centimetres are the
  /// common case, so the decimal point would be noise on every card.
  static String _trim(num value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toString();

  /// The cheapest unit price across every size — what «من ٠٫٨٥ د.ل» on the grid means.
  ///
  /// **Compared as numbers and returned as the original string.** Parsing is only ever used to
  /// order them; the value handed back is the decimal the server sent, so nothing is rounded on
  /// the way to the screen.
  String? get lowestUnitPrice {
    String? best;
    double? bestValue;

    for (final variant in variants) {
      for (final tier in variant.priceTiers) {
        final value = double.tryParse(tier.unitPrice);
        if (value == null) continue;

        if (bestValue == null || value < bestValue) {
          bestValue = value;
          best = tier.unitPrice;
        }
      }
    }

    return best;
  }
}

/// What a quantity costs — answered by the server so that the number shown and the number
/// written to the order come from the same code.
@freezed
abstract class PriceQuote with _$PriceQuote {
  const factory PriceQuote({
    required String quantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
    required String total,
    String? unit,
    @JsonKey(name: 'unit_label') String? unitLabel,
    @JsonKey(name: 'applied_tier_min_quantity') String? appliedTierMinQuantity,

    /// The saving still on the table, so the screen can say «اطلب ٤٧ أكثر وينزل سعر الوحدة».
    /// Null when the customer is already on the best rate.
    @JsonKey(name: 'next_tier') NextTier? nextTier,
  }) = _PriceQuote;

  factory PriceQuote.fromJson(Map<String, dynamic> json) => _$PriceQuoteFromJson(json);
}

@freezed
abstract class NextTier with _$NextTier {
  const factory NextTier({
    @JsonKey(name: 'min_quantity') required String minQuantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'quantity_to_reach') String? quantityToReach,
  }) = _NextTier;

  factory NextTier.fromJson(Map<String, dynamic> json) => _$NextTierFromJson(json);
}
