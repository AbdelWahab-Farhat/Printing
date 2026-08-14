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

    /// How many products sit under this heading.
    ///
    /// It is also what says whether deleting will be refused — the server allows a delete only
    /// while this is zero — so the screen can explain that before the button is pressed.
    @JsonKey(name: 'products_count') int? productsCount,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ProductCategory;

  const ProductCategory._();

  factory ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);

  /// Whether any product points at this category. `null` — the count was not asked for — reads
  /// as "assume it is in use", because refusing a delete wrongly is recoverable and the
  /// opposite is a confusing 422 the user cannot act on.
  bool get isInUse => (productsCount ?? 1) > 0;
}
