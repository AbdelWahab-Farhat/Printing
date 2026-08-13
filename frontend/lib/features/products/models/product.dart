import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/products/models/product_category.dart';

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

    /// What a person says out loud — `P7`. The server allocates it and it never changes, so it
    /// is the one thing on the card safe to read down a phone line.
    required String code,

    required String slug,
    required String name,
    String? description,
    @Default(<String>[]) List<String> features,

    /// «النوع» — مطبوعة/سادة, as a machine value for logic that must switch on it. The wire
    /// key kept the name it was born with; see `ProductType` and PRODUCT-CATEGORIES.md.
    required String category,

    /// The Arabic label for it, sent by the server so the app keeps no translation table.
    @JsonKey(name: 'category_label') required String categoryLabel,

    /// «التصنيف» — the catalogue heading this product sits under. Null only for a product
    /// recorded before categories existed and not edited since; the form refuses to save one.
    ///
    /// The API sends `{id, name}` here rather than the whole row — every other field on
    /// [ProductCategory] has a default, so the same model parses both shapes and the app keeps
    /// one type for one idea.
    @JsonKey(name: 'product_category') ProductCategory? productCategory,

    @JsonKey(name: 'product_category_id') int? productCategoryId,

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

    /// When the bag entered the catalogue, and when it was last touched. Absent from nothing —
    /// the API sends both on every product — but nullable because a `DateTime` this app failed
    /// to parse should leave a line off a screen rather than take the whole screen down.
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
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
  String get minOrderQuantityLabel => groupedDecimal(minOrderQuantity);

  bool get hasDescription => description != null && description!.trim().isNotEmpty;

  bool get hasFeatures => features.isNotEmpty;

  /// The sizes that can actually be ordered today.
  ///
  /// Kept apart from [variants] rather than filtering it away: a stopped size still has to be
  /// *shown* — it is what a past order was priced at — so the detail screen lists all of them
  /// and marks these. Only a count of what is on offer uses this.
  List<ProductVariant> get activeVariants =>
      variants.where((variant) => variant.isActive).toList(growable: false);

  /// Whether any size at all is priced. `false` for a bag quoted by hand, and also for one
  /// somebody added without filling the grid in — two different situations that both mean
  /// «there is no number to show».
  bool get hasAnyPrice => startingPrice != null;
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

  /// `'25 × 35 سم'`, or `null` for a size recorded as a name only.
  ///
  /// Built here rather than assumed equal to [label]: the two are not always the same thing —
  /// a shop may call a size «كبير» and still have measured it — which is exactly why the API
  /// sends both.
  String? get dimensionsLabel =>
      widthCm != null && heightCm != null ? '$widthCm × $heightCm سم' : null;

  bool get hasPrices => priceTiers.isNotEmpty;

  /// The tiers cheapest-last, which is the order somebody reads a price ladder in: «١٠٠ فأكثر،
  /// ٣٠٠ فأكثر، ١٠٠٠ فأكثر». `num.parse` only ever *orders* them; every value shown is the
  /// server's own text.
  List<ProductPriceTier> get tiersByQuantity {
    final sorted = [...priceTiers]
      ..sort((a, b) => num.parse(a.minQuantity).compareTo(num.parse(b.minQuantity)));

    return sorted;
  }
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

  String get minQuantityLabel => groupedDecimal(minQuantity);
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

    /// What the file actually is. The API has sent these since the media layer landed; nothing
    /// read them until a screen existed with room to say what it is showing.
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'width_px') int? widthPx,
    @JsonKey(name: 'height_px') int? heightPx,
  }) = _ProductImage;

  const ProductImage._();

  factory ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);

  /// `'1200 × 800'`, or `null` for a file whose dimensions were never measured.
  String? get dimensionsLabel =>
      widthPx != null && heightPx != null ? '$widthPx × $heightPx' : null;

  /// `'٢٤٠ ك.ب'`. Kilobytes to three digits, then megabytes — a photograph is never small
  /// enough for bytes to be the useful unit, and never large enough for gigabytes.
  String? get sizeLabel {
    final bytes = sizeBytes;
    if (bytes == null) return null;

    if (bytes < 1024) return '$bytes بايت';

    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(0)} ك.ب';

    return '${(kilobytes / 1024).toStringAsFixed(1)} م.ب';
  }
}

