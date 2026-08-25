import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_item.freezed.dart';
part 'stock_item.g.dart';

/// «الصنف المخزني» — the shelf itself: a material at a size.
///
/// **This is what a warehouse holds, and it is not a product's size.** «كيس شحن سادة 25*35» and
/// «كيس شحن مطبوع 25*35» are two catalogue rows and one pile of bags; what separates them is the
/// printing, which is a manufacturing cost rate, not a different material. So both product sizes
/// point here, draw down one balance and consume one FIFO stack. Before this existed each kept a
/// private balance over stock that was bought once, and an order for 300 of one and 400 of the
/// other passed two checks against two shelves of 500 — then came up short on the floor.
///
/// **Sharing runs across products at one size and never across sizes.** 25*35 and 35*40 are two
/// stock items, two balances and two prices, so per-size costing is fully intact.
///
/// Identity is `(name, width_cm, height_cm)`, which is also why a grouped item carries its
/// material's name: rename the material and every size of it is renamed in the same transaction,
/// or two materials would end up fighting over one shelf.
@freezed
abstract class StockItem with _$StockItem {
  const factory StockItem({
    required int id,

    /// `S7` — server-allocated and never settable. **What replaces the product thumbnail on a
    /// stock row**: a pile is not one product's, so a picture of either of the two products
    /// sharing it would be picking one arbitrarily and telling the storekeeper the wrong thing.
    /// A code reads well on a row and is the one thing safe to read down a phone line.
    required String code,

    /// The material's name, without the size. [displayName] is what gets drawn.
    required String name,

    /// Null for something counted without dimensions — a roll, an ink. **The two travel
    /// together**: half a size is not a size, and the server refuses a width with no height.
    @JsonKey(name: 'width_cm') int? widthCm,
    @JsonKey(name: 'height_cm') int? heightCm,

    /// The material this is a size of, or null for a standalone shelf. **Always present** — a
    /// plain column, not a relation — so it answers even where [group] does not.
    @JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,

    /// The material itself, when a caller asked for it.
    ///
    /// **Absent from every response the API sends today**, and modelled all the same: it is
    /// `whenLoaded('stockItemGroup')` on the resource and no query eager-loads it on a stock
    /// item. Null therefore means «لم يُطلب», not «لا مادة له» — [stockItemGroupId] is the field
    /// that answers that. Anything needing the material's name today reads it from the group's
    /// own endpoint.
    @JsonKey(name: 'stock_item_group') StockItemGroupRef? group,

    /// «كيس شحن 25*35» — composed **server-side** from the name and the size.
    ///
    /// **Rendered as sent, never rebuilt here.** The separator is a bare `*` with no spaces, an
    /// unsized item's display name is just its name, and the shortfall message an order is
    /// refused with quotes this exact string. A second implementation in Dart would drift from
    /// it, and the first screen to notice would be one comparing a refusal to a list.
    @JsonKey(name: 'display_name') required String displayName,

    /// What **this** shelf is counted in — independent of any product's `pricing_unit`.
    @JsonKey(unknownEnumValue: StockUnit.unknown) required StockUnit unit,

    /// The server's Arabic for [unit]. Drawn as sent, so a unit added to the backend tomorrow
    /// still reads right without this app being rebuilt.
    @JsonKey(name: 'unit_label') required String unitLabel,

    String? description,

    @JsonKey(name: 'is_active') required bool isActive,

    @JsonKey(name: 'sort_order') required int sortOrder,

    /// How many product sizes draw on this shelf — **the number that makes the sharing
    /// visible**, and the one that says whether deleting will be refused.
    ///
    /// Nullable because it is `whenCounted('variants')`: the list and the show endpoint carry it,
    /// and create, update, set-unit and the sizes nested inside a group's payload do not. Null is
    /// «لم يُحسب», never zero — see [sharedByLabel], which draws nothing rather than «لا مقاس».
    @JsonKey(name: 'variants_count') int? variantsCount,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _StockItem;

  const StockItem._();

  factory StockItem.fromJson(Map<String, dynamic> json) => _$StockItemFromJson(json);

  /// Whether this shelf is a *size* of something, rather than a thing counted without dimensions.
  bool get hasSize => widthCm != null && heightCm != null;

  /// Whether the material decides this item's name and unit. A grouped size cannot be renamed
  /// alone, and cannot be re-filed under another material at all — both are set at creation.
  bool get belongsToGroup => stockItemGroupId != null;

  /// Whether more than one product size draws on this pile — the thing the whole change exists
  /// to make possible, and worth saying on the row so nobody "tidies up" a shared shelf.
  bool get isShared => (variantsCount ?? 0) > 1;

  /// Whether **any** product size draws on it. The server refuses a delete while one does, and
  /// this is what lets the screen say so before the button is pressed rather than after a 422.
  ///
  /// A row that arrived without the count answers `false`: refusing to offer a delete because a
  /// number was not asked for would be inventing a rule the server does not have.
  bool get isDrawnFrom => (variantsCount ?? 0) > 0;

  /// «٣ مقاسات تسحب منه» — how many product sizes share this pile, in Arabic that counts.
  ///
  /// Null when the endpoint did not count them, so the row draws nothing instead of claiming
  /// «لا مقاس يسحب منه» about a shelf four products are using.
  String? get sharedByLabel => switch (variantsCount) {
    null => null,
    0 => 'لا مقاس يسحب منه',
    1 => 'مقاس واحد يسحب منه',
    2 => 'مقاسان يسحبان منه',
    final count when count <= 10 => '$count مقاسات تسحب منه',
    final count => '$count مقاساً يسحب منه',
  };
}

/// The material a stock item is filed under, flattened by the server because it is only ever met
/// here — three fields, no unit and no counts.
///
/// **`StockItemGroupRef`, not `StockItemGroup`.** The material has a feature module of its own
/// with a full model in it; naming this the same thing would make the two impossible to import
/// into one file, which is exactly what a screen showing a shelf under its material has to do.
@freezed
abstract class StockItemGroupRef with _$StockItemGroupRef {
  const factory StockItemGroupRef({
    required int id,

    /// `G3` — server-allocated, like a stock item's own.
    required String code,

    required String name,
  }) = _StockItemGroupRef;

  factory StockItemGroupRef.fromJson(Map<String, dynamic> json) =>
      _$StockItemGroupRefFromJson(json);
}

/// The material a **new** shelf is being filed under, as little of it as the form needs.
///
/// A record rather than the group module's model, so this feature never imports one: the two
/// modules are built side by side, and a compile-time dependency between them would make either
/// one impossible to change alone. Whoever opens the form from a material's own screen builds
/// this in a line.
///
/// It carries `defaultUnit` because the server takes the unit from the material when a group is
/// named — the form has to show which one that is, read-only, rather than let somebody choose a
/// unit that will be overruled.
typedef StockItemGroupChoice = ({int id, String name, StockUnit defaultUnit});
