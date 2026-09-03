import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/products/models/product_category.dart';
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

    /// What a person says out loud — `P7`. The server allocates it and it never changes, so it
    /// is the one thing on the card safe to read down a phone line.
    required String code,

    required String slug,
    required String name,
    String? description,
    @Default(<String>[]) List<String> features,

    /// «التصنيف» — the catalogue heading this product sits under. Null only for a product
    /// recorded before categories existed and not edited since; the form refuses to save one.
    ///
    /// The API sends `{id, name}` here rather than the whole row — every other field on
    /// [ProductCategory] has a default, so the same model parses both shapes and the app keeps
    /// one type for one idea.
    @JsonKey(name: 'product_category') ProductCategory? productCategory,

    @JsonKey(name: 'product_category_id') int? productCategoryId,

    /// «المادة» — what this product is cut from, and **the one field that files every size of it
    /// onto a shelf**.
    ///
    /// Naming the material once is the whole feature: on every save the server walks the sizes
    /// and, for each one without a shelf of its own, finds this material's «صنف مخزني» at that
    /// size — creating it if the material has not reached that size yet, with the material's own
    /// name and default unit. Before it existed each size had to be pointed at a pile by hand,
    /// and one wrong tap split «كيس شحن 25*35» into two heaps nobody could reconcile.
    ///
    /// Null for a product whose material nobody has named — a quote-only bag, or one whose sizes
    /// come from several materials and are linked one by one. **It cannot be cleared through
    /// `PUT /products`**: omitting the key leaves the current material alone, and there is
    /// deliberately no way to say «none», because doing so would detach every size from its
    /// shelf on that very save.
    @JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,

    /// The material itself. `whenLoaded` on the resource, but eager-loaded on every product path
    /// the API has — index, show, store, update, activation — so `null` here really does mean
    /// «بلا مادة» rather than «لم يُطلب». [stockItemGroupId] is the field to trust when in doubt.
    @JsonKey(name: 'stock_item_group') ProductMaterial? stockItemGroup,

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

  /// Whether somebody has said what this bag is cut from.
  ///
  /// Read off the id rather than off [stockItemGroup]: the id is a plain column and always on
  /// the wire, so this stays true for a response that carried the relation and one that did not.
  bool get hasMaterial => stockItemGroupId != null;

  /// The sizes that draw on no shelf at all.
  ///
  /// **Worth a screen saying out loud**, because nothing else will until an order is refused at
  /// «جاهزة»: every stock path refuses an unlinked size by name rather than inventing a pile for
  /// it. Empty is the ordinary answer for a product with a material — the server files each size
  /// on save — and for a quote-only bag it is the correct answer too, which is why this is
  /// reported and never treated as a fault.
  List<ProductVariant> get unlinkedVariants =>
      variants.where((variant) => !variant.isStocked).toList(growable: false);

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

    /// «الصنف المخزني» this size draws from — the pile, not the size.
    ///
    /// **Two products at one size share one of these**, and that is the point: «كيس شحن سادة
    /// 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows and one heap of bags. What
    /// separates them is the printing, which is a manufacturing cost rate keyed per variant, not
    /// a different material.
    ///
    /// Null for a size that is never stocked. Set by hand only as an escape hatch — a 25*35 bag
    /// deliberately cut from a wider sheet — because with the product's material named the server
    /// resolves it on every save.
    ///
    /// ⚠️ **On `PUT /products` the whole variant set is replaced, so a size sent without this key
    /// loses whatever it was pointed at.** See `NewProductVariant.stockItemId` for what this app
    /// does about that.
    @JsonKey(name: 'stock_item_id') int? stockItemId,

    /// The shelf itself, for showing what a size draws on without a second request. Loaded on
    /// every product-returning path, so `null` alongside a non-null [stockItemId] does not happen
    /// in practice.
    @JsonKey(name: 'stock_item') VariantStockItem? stockItem,

    /// What this size costs us when a vendor makes it — «سعر التكلفة».
    ///
    /// **Absent from the payload, not null, for anybody without `products.view_cost`** — so
    /// `null` here means one of two things and the screen must not claim it means «بلا تكلفة».
    /// Gate the row on the permission, not on the value.
    ///
    /// A decimal string, never a `double`: it is multiplied by a quantity on the server and
    /// compared against a price that is also a string.
    ///
    /// ⚠️ **Replaced along with the rest of the size on `PUT /products`** — a size sent without
    /// it is saved with none. See `NewProductVariant.costPrice`.
    @JsonKey(name: 'cost_price') String? costPrice,

    @JsonKey(name: 'price_tiers') @Default(<ProductPriceTier>[]) List<ProductPriceTier> priceTiers,
  }) = _ProductVariant;

  const ProductVariant._();

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

  /// Whether this size has a pile behind it. `false` means every stock movement against it is
  /// refused by name — «غير مرتبط بصنف مخزني» — rather than silently doing nothing.
  bool get isStocked => stockItemId != null;

  /// «كيس شحن 25*35» — the shelf's name as the **server** composed it, or null when there is no
  /// shelf. Never rebuilt from the parts here: the sentence an order is refused with quotes this
  /// exact string, and a second spelling of it is a second thing for somebody to reconcile.
  String? get shelfLabel => stockItem?.displayName;

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

/// «المادة» as a **product** carries it — five fields, flattened by the server.
///
/// **Named `ProductMaterial` rather than `StockItemGroup`, and that is not squeamishness.** The
/// material has a feature module of its own with a full model in it, and `features/stock_items/`
/// declares a three-field echo called `StockItemGroupRef`. This is a third shape again — the two
/// `default_unit` fields the ref has no room for — and any screen that shows a product beside a
/// material picker has to import two of the three into one file. Three distinct names is the only
/// arrangement in which the wrong one cannot be reached for.
///
/// [defaultUnit] is here because it answers the question the product form is actually asked:
/// «المقاسات الجديدة ستُحسب بأي وحدة؟». A shelf minted for one of this product's sizes takes the
/// material's unit and **never** the product's `pricing_unit` — a thing bought in by weight and
/// sold by the piece needs the two to differ.
@freezed
abstract class ProductMaterial with _$ProductMaterial {
  const factory ProductMaterial({
    required int id,

    /// `G3` — server-allocated from the id and never settable.
    required String code,

    required String name,

    /// What a size created under this material starts out counted in. Changing it on the material
    /// disturbs no existing shelf; it only decides what the next one is minted with.
    @JsonKey(name: 'default_unit') required String defaultUnit,

    /// The server's Arabic for [defaultUnit] — «قطعة», «كيلوغرام» — drawn as sent, so a unit the
    /// backend grows tomorrow still reads right without this app being rebuilt.
    @JsonKey(name: 'default_unit_label') required String defaultUnitLabel,
  }) = _ProductMaterial;

  factory ProductMaterial.fromJson(Map<String, dynamic> json) => _$ProductMaterialFromJson(json);
}

/// The shelf a size draws from, as it arrives **nested on a variant**: eight fields, no counts
/// and no timestamps.
///
/// **Not `features/stock_items/`'s `StockItem`, and it cannot be.** That model requires
/// `is_active` and `sort_order`, which this nested shape does not carry — parsing one into it
/// would throw on every product the catalogue draws. Borrowing it and defaulting those two would
/// be worse: the row would claim a shelf is active when nothing said so.
///
/// It carries `unit` and `unit_label`, which the same nested object on a warehouse balance or a
/// movement does not — there the unit is a snapshot on the balance itself.
@freezed
abstract class VariantStockItem with _$VariantStockItem {
  const factory VariantStockItem({
    required int id,

    /// `S7`. **What stands where a product thumbnail used to**: a pile is not one product's, so
    /// a picture of either of the two products sharing it would be telling the storekeeper the
    /// wrong thing. A code reads well on a row and is safe to say down a phone line.
    required String code,

    /// The material's name without the size. [displayName] is what gets drawn.
    required String name,

    @JsonKey(name: 'width_cm') int? widthCm,
    @JsonKey(name: 'height_cm') int? heightCm,

    /// «كيس شحن 25*35» — composed server-side, a bare `*` with no spaces, and **rendered as
    /// sent**. The shortfall message an order is refused with quotes this exact string.
    @JsonKey(name: 'display_name') required String displayName,

    /// What this shelf is counted in — independent of the product's `pricing_unit`, which is what
    /// the customer is charged by. The two differ on anything bought by weight and sold by count.
    required String unit,

    @JsonKey(name: 'unit_label') required String unitLabel,
  }) = _VariantStockItem;

  factory VariantStockItem.fromJson(Map<String, dynamic> json) =>
      _$VariantStockItemFromJson(json);
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

