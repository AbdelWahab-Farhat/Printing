import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// A bag type in the catalogue.
///
/// **Money stays a `String`.** `'0.850'` is what the server sent and what is shown; parsing it
/// into a `double` to hold it would be the first step towards adding prices in binary floating
/// point, which does not add money correctly. The only place a number is derived from one of
/// these is [startingPrice], and there it is a *comparison* — never arithmetic.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required int id,
    required String slug,
    required String name,
    String? description,
    @Default(<String>[]) List<String> features,

    /// The machine value, for logic that must switch on a category.
    required String category,

    /// The Arabic label for it, sent by the server so the app keeps no translation table.
    @JsonKey(name: 'category_label') required String categoryLabel,

    @JsonKey(name: 'pricing_unit') required String pricingUnit,
    @JsonKey(name: 'pricing_unit_label') required String pricingUnitLabel,
    @JsonKey(name: 'pricing_mode') required String pricingMode,
    @JsonKey(name: 'pricing_mode_label') required String pricingModeLabel,

    /// Whether to render a price or "السعر حسب الطلب" — the server's answer, not a rule the app
    /// re-derives from [pricingMode].
    @JsonKey(name: 'has_listed_prices') @Default(false) bool hasListedPrices,

    /// A decimal string like `'100.000'`: a quantity in [pricingUnit], not a count of rows.
    @JsonKey(name: 'min_order_quantity') required String minOrderQuantity,

    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,

    @Default(<ProductVariant>[]) List<ProductVariant> variants,
    @Default(<ProductImage>[]) List<ProductImage> images,
  }) = _Product;

  const Product._();

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  /// The picture to show in a list — the primary one, or the first there is.
  ProductImage? get primaryImage {
    if (images.isEmpty) return null;

    return images.firstWhere((image) => image.isPrimary, orElse: () => images.first);
  }

  /// The cheapest listed unit price across every variant, as the string the server sent.
  ///
  /// `num.parse` only ever *orders* the tiers here; the value handed back is the original text,
  /// so nothing downstream can end up displaying `0.8500000000000001`.
  String? get startingPrice {
    final prices = <String>[
      for (final variant in variants)
        for (final tier in variant.priceTiers) tier.unitPrice,
    ];

    if (prices.isEmpty) return null;

    return prices.reduce((a, b) => num.parse(a) <= num.parse(b) ? a : b);
  }

  /// `'100.000'` reads as a quantity to a database and as noise to a person: `'100'`.
  String get minOrderQuantityLabel => _trimDecimals(minOrderQuantity);
}

/// One size of a product, with its own price breaks.
@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required int id,

    /// What the shop calls this size — `'25*35'`. Shown as sent, never rebuilt from the
    /// dimensions, because the two are not always the same thing.
    required String label,

    @JsonKey(name: 'width_cm') int? widthCm,
    @JsonKey(name: 'height_cm') int? heightCm,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'price_tiers') @Default(<ProductPriceTier>[]) List<ProductPriceTier> priceTiers,
  }) = _ProductVariant;

  const ProductVariant._();

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);
}

/// "This many or more, at this price."
@freezed
abstract class ProductPriceTier with _$ProductPriceTier {
  const factory ProductPriceTier({
    required int id,
    @JsonKey(name: 'min_quantity') required String minQuantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
  }) = _ProductPriceTier;

  const ProductPriceTier._();

  factory ProductPriceTier.fromJson(Map<String, dynamic> json) =>
      _$ProductPriceTierFromJson(json);

  String get minQuantityLabel => _trimDecimals(minQuantity);
}

/// A photo of the product. The URL is generated per request by the server, so it is used and
/// never stored.
@freezed
abstract class ProductImage with _$ProductImage {
  const factory ProductImage({
    required int id,
    required String url,
    @JsonKey(name: 'alt_text') String? altText,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _ProductImage;

  factory ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);
}

/// `'100.000'` → `'100'`, `'0.850'` → `'0.85'`.
///
/// String surgery, not `double.parse().toString()`: the decimals the server chose to send are
/// the decimals it means, and round-tripping them through a float is how `0.850` becomes
/// something else entirely.
String _trimDecimals(String value) {
  if (!value.contains('.')) return value;

  final trimmed = value.replaceFirst(RegExp(r'0+$'), '');

  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}
