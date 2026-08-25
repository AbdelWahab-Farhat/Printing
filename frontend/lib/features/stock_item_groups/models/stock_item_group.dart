// The one type this module borrows from its neighbour, named rather than taken wholesale: the
// same library also declares `StockItemGroupRef`, a three-field echo of the class below, and two
// things called almost the same thing in one file is how the wrong one gets used.
//
// The direction is one-way — `stock_items` never imports this module — and it is forced by the
// API rather than chosen: `items[]` on a group's `show` **is** a list of StockItemResource, so a
// group model that would not name a stock item could not model the response.
import 'package:dayaa/features/stock_items/models/stock_item.dart' show StockItem;
// `StockUnit` is declared over there for the same reason: a material's `default_unit` and a
// shelf's `unit` are one server enum, and a second Dart spelling of it is a second place «متر»
// would have to be added to.
import 'package:dayaa/features/stock_items/models/stock_unit.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_item_group.freezed.dart';
part 'stock_item_group.g.dart';

/// مجموعة أصناف — the material, and **nothing else**.
///
/// It holds no balance, no cost layer and no size. It is not a shelf and it is not a parent
/// shelf: «كيس شحن» is the paper, «كيس شحن 25*35» is the pile you can count. That separation is
/// a table of its own on the server rather than a `parent_id` on `stock_items`, so a picker
/// cannot accidentally offer a material where a shelf was meant — the type simply cannot hold
/// stock.
///
/// **What it is for is saving somebody from pointing every product size at a shelf by hand.**
/// Naming the material once on a product files each of that product's sizes automatically, at
/// the size it already has, and two products at one size land on one pile instead of two heaps
/// nobody can reconcile. One wrong tap in a shelf picker used to be how a material got split.
///
/// Two consequences the screens have to state out loud, both from the server's own actions:
///
///   * **Renaming renames every size under it**, in one transaction — a grouped item carries
///     its material's name, and that is what keeps `(name, width, height)` naming one shelf.
///     See [renamesItems].
///   * **Changing [defaultUnit] touches no existing shelf.** It decides what a size created
///     *later* starts out counted in; an existing shelf's unit is snapshotted onto every
///     balance and cost layer that ever touched it and moves only through
///     `PATCH /stock-items/{id}/unit`, which empties it.
@freezed
abstract class StockItemGroup with _$StockItemGroup {
  const factory StockItemGroup({
    required int id,

    /// «G3» — allocated by the server from the id and never settable. Shown because it is what
    /// a storekeeper reads out over a phone.
    required String code,

    /// Uniquely indexed on the server, and that is not tidiness: a size under this material
    /// carries this name, so two materials sharing one would fight over the same shelf.
    required String name,

    @JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown)
    required StockUnit defaultUnit,

    /// The server's Arabic for [defaultUnit], so the app keeps no translation table. Rendered
    /// as sent; [StockUnit.label] is only for naming a unit nothing has been loaded for yet.
    @JsonKey(name: 'default_unit_label') required String defaultUnitLabel,

    String? description,

    @JsonKey(name: 'is_active') required bool isActive,

    @JsonKey(name: 'sort_order') required int sortOrder,

    /// How many sizes are filed under it. **Nullable because the key is absent** on a create or
    /// an edit's answer — `whenCounted` omits it rather than sending zero — and `0` and «لم
    /// يُحسب» are different enough to decide a delete button on. See [renamesItems].
    @JsonKey(name: 'items_count') int? itemsCount,

    /// How many products name it as their material. Absent on the same two responses.
    @JsonKey(name: 'products_count') int? productsCount,

    /// The sizes themselves, smallest first — **only ever on `show`**, so an empty list here
    /// means «this came from the list endpoint», not «this material has no sizes». Nothing
    /// counts them; [itemsCount] is what answers that.
    @Default(<StockItem>[]) List<StockItem> items,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _StockItemGroup;

  const StockItemGroup._();

  factory StockItemGroup.fromJson(Map<String, dynamic> json) =>
      _$StockItemGroupFromJson(json);

  /// Whether saving a new name here would rename shelves along with it.
  ///
  /// **Fail-closed on an unknown count.** The answer to a save carries no `items_count`, and a
  /// silent cascade across every shelf of a material is the one outcome on this screen nobody
  /// would notice until an order failed. Asking once too often costs a tap.
  bool get renamesItems => (itemsCount ?? 1) > 0;

  /// Whether the server will refuse to delete it. Fail-closed for the same reason: a bin that
  /// appears and then 422s teaches people to ignore the message it prints.
  bool get isInUse => (itemsCount ?? 1) > 0 || (productsCount ?? 1) > 0;

}
