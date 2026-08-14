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
}
