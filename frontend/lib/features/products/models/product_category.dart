import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.freezed.dart';
part 'product_category.g.dart';

/// التصنيف — a heading in the catalogue: أكياس, علب وكراتين التغليف, ستيكرات ومطبوعات أخرى,
/// مطبوعة, سادة.
///
/// Reference data the business curates from its own screen, exactly as `BusinessField` is.
/// Nothing in the app branches on a particular category, and nothing should: the list is the
/// shop's to shape, and code that knows «أكياس» by name would break the first time somebody
/// renames it.
///
/// **The only thing that classifies a product.** «النوع» — مطبوعة/سادة — was a second field
/// asking nearly the same question; it fed no calculation anywhere, so it became the last two
/// names on this list and its column was dropped. See PRODUCT-CATEGORIES.md.
@freezed
abstract class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required int id,
    required String name,

    /// The line the catalogue prints under the heading. Null until somebody writes one.
    String? description,

    /// Whether it is still offered when recording a product. A stopped category stays on the
    /// products already under it — it leaves the picker, it does not retract anything.
    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// Where it sits in the catalogue. The business's own order, not alphabetical.
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,

    /// How goods under this heading come to exist — مطبوعة، سادة، أو وسيط.
    ///
    /// **This row's own answer, not the effective one.** A subheading that inherits its parent's
    /// mode reads `in_house` here, because this is the value the edit sheet puts back: showing
    /// the inherited answer would save a mode onto a child that never asked for one. What a
    /// particular *order* does is the server's to decide from its lines — see `ResolveOrderFlow`
    /// — and never this app's. The one place the *effective* answer arrives is the
    /// `product_category` object nested on a product, and the product form reads it from there.
    ///
    /// `in_house` by default, so a heading nobody has thought about sends its orders down the
    /// road every order took before this field existed.
    @JsonKey(name: 'production_mode', unknownEnumValue: ProductionMode.unknown)
    @Default(ProductionMode.inHouse)
    ProductionMode productionMode,

    /// The server's own Arabic for [productionMode] — «وسيط — لدى مورد خارجي». Drawn as sent
    /// where it arrives, so a mode this build has never heard of still reads right on a card.
    @JsonKey(name: 'production_mode_label') String? productionModeLabel,

    /// Whether a deal may be opened against the shelves under this heading.
    ///
    /// **Three answers, and null is one of them**: «حسب الرئيسي». A subheading left at null
    /// takes its parent's answer, which is what lets one be kept out of an investable family
    /// — `false` — rather than merely never asked about. A heading nobody has decided about is
    /// not investable: nothing may be funded until somebody says so.
    ///
    /// **This row's own answer, not the effective one**, exactly as [productionMode] is: it is
    /// the value the edit sheet puts back, and the inherited one would be saved onto a
    /// subheading that never gave it.
    ///
    /// The flag opens *headings*, and a deal is opened against a *shelf*: the server accepts one
    /// only when every active product standing on it is under a heading marked here. So the
    /// answer to «لماذا رُفضت هذه المادة؟» is a product name, and it comes in the 422.
    @JsonKey(name: 'is_investable') bool? isInvestable,

    /// **Deprecated, and still sent by the server for this build.** True for سادة *and* for وسيط
    /// — neither is printed here — so it can no longer tell them apart. Read [productionMode];
    /// this app stopped writing it the day the sheet learned the three-way answer, and it goes
    /// the release after. See OUTSOURCED-PRODUCTS.md §8.
    @JsonKey(name: 'skips_production') @Default(false) bool skipsProduction,

    /// The heading this one sits under, or null when it is one in its own right.
    ///
    /// The tree is one level deep and this app does not manage it yet — the field exists so a
    /// child arriving from the API is not silently drawn as a root.
    @JsonKey(name: 'parent_id') int? parentId,

    /// Products filed directly on this heading. Zero for a parent by construction: a heading
    /// with subheadings is a heading, not a slot.
    @JsonKey(name: 'products_count') int? productsCount,

    /// How many subheadings it holds. What says this row is a heading rather than something a
    /// product can be filed under.
    @JsonKey(name: 'children_count') int? childrenCount,

    /// Everything under it, subheadings included. **This is the number the card shows** — and
    /// the same one that decides whether a delete will be refused, so the screen can explain
    /// that before the button is pressed.
    @JsonKey(name: 'total_products_count') int? totalProductsCount,

    /// The picture the catalogue prints above the heading. Built by the server per request and
    /// never stored: on a private disk it is a signed link that expires, so a screen holding
    /// one for an hour must reload rather than reuse it.
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'image_width_px') int? imageWidthPx,
    @JsonKey(name: 'image_height_px') int? imageHeightPx,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProductCategory;

  const ProductCategory._();

  factory ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);

  /// Whether anything points at this category — a product, directly or through a subheading.
  ///
  /// `null` — the counts were not asked for — reads as "assume it is in use", because refusing
  /// a delete wrongly is recoverable and the opposite is a confusing 422 the user cannot act on.
  bool get isInUse => (totalProductsCount ?? productsCount ?? 1) > 0;

  /// Whether it holds subheadings, and is therefore a heading rather than a slot.
  bool get hasChildren => (childrenCount ?? 0) > 0;

  /// Whether a product may be filed under it. The server refuses the rest with a 422 naming the
  /// way out — «اختر أحد فروعه» — so this only keeps an impossible choice off a picker.
  bool get isFileable => !hasChildren;

  /// What a screen counts: everything under the heading, subheadings included.
  int? get shownProductsCount => totalProductsCount ?? productsCount;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  /// The word a card prints for the mode — the server's when it came, this app's otherwise.
  String get productionModeCaption => productionModeLabel ?? productionMode.label;
}
