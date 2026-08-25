import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_stock.freezed.dart';
part 'warehouse_stock.g.dart';

/// One shelf: how much of one **صنف مخزني** sits in one warehouse.
///
/// **A shelf holds a material at a size, not a product's size.** «كيس شحن سادة 25*35» and «كيس شحن
/// مطبوع 25*35» are two catalogue rows and one pile of bags — what separates them is printing,
/// which is a cost rate rather than a different material — so both draw on this one row. Before
/// that was true each kept a private balance over stock bought once, and an order for 300 of one
/// and 400 of the other passed two checks against two shelves of 500, then came up short on the
/// floor.
///
/// **The quantity is a `String`.** It is a decimal the server sent — `'250.000'` — and parsing
/// it into a `double` to hold it is the first step towards arithmetic this app has no business
/// doing: a balance moves because a *movement* explains it, never because a client computed a
/// new number. There is deliberately no endpoint that writes one.
@freezed
abstract class WarehouseStock with _$WarehouseStock {
  const factory WarehouseStock({
    required int id,
    @JsonKey(name: 'warehouse_id') required int warehouseId,
    @JsonKey(name: 'stock_item_id') required int stockItemId,

    required String quantity,

    /// What this balance is counted in, snapshotted when the shelf was first stocked and never
    /// re-derived — so a unit chosen for the item later cannot silently restate a number that
    /// was counted the old way. Re-declaring the item's unit does not relabel this either: the
    /// server empties every shelf through a recorded adjustment first, and the shelf comes back
    /// at zero in the new unit.
    required String unit,

    /// The server's Arabic for [unit], kept as a label rather than a translation table here —
    /// the same treatment `pricing_unit_label` gets everywhere else in this app.
    @JsonKey(name: 'unit_label') required String unitLabel,

    /// The level at which this shelf starts asking to be refilled, or null for one nobody set.
    @JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,

    /// The server's answer, not a comparison this app re-derives — `null` threshold means "no
    /// alert", which is not the same as a threshold of zero.
    @JsonKey(name: 'is_low_stock') @Default(false) bool isLowStock,

    @JsonKey(name: 'stock_item') StockItemRef? item,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _WarehouseStock;

  const WarehouseStock._();

  factory WarehouseStock.fromJson(Map<String, dynamic> json) => _$WarehouseStockFromJson(json);

  /// `'250.000'` reads as a quantity to a database and as noise to a storekeeper: `'250'`.
  /// `'12450.000'` reads as neither: `'12,450'`.
  ///
  /// Only ever drawn. What prefills the sheets is [thresholdLabel], which groups nothing — a
  /// text field with a comma in it is a number the server will refuse.
  String get quantityLabel => groupedDecimal(quantity);

  /// Nothing on the shelf.
  ///
  /// **Not the same question as [isLowStock]**, which the server answers and which is silent
  /// about a size nobody set an alert level for. Such a line at zero used to render exactly like
  /// a healthy one, so the emptiest row on the screen was also the calmest.
  ///
  /// `num.tryParse` only ever compares here — the string is what gets displayed — and a value it
  /// cannot read is treated as "not empty", because inventing «نافد» for a shelf that has
  /// something on it is the worse mistake.
  bool get isOutOfStock => (num.tryParse(quantity) ?? 1) <= 0;

  /// «250 كيلوغرام» — the balance together with what it is counted in.
  ///
  /// A bare number is ambiguous on a floor that holds both bags and kilos, and the unit is the
  /// difference between a shelf that is nearly empty and one that is nearly full.
  String get quantityWithUnit => '$quantityLabel $unitLabel';

  /// The alert level with its padding zeros gone — and **without separators**, because this is
  /// what prefills «حد التنبيه» in the sheet. Whoever draws it groups it there.
  String? get thresholdLabel => lowStockThreshold == null ? null : trimDecimals(lowStockThreshold!);

  /// «كيس شحن 25*35» — the server's own composition, drawn as sent.
  ///
  /// **Never rebuilt from [StockItemRef.name] and the two dimensions here.** The shortfall an
  /// order is refused with quotes this exact string, and a second implementation in Dart would
  /// drift from it — the first screen to notice would be one comparing a refusal to a list.
  String get title => item?.displayName ?? 'مادة #$stockItemId';

  /// `S7` — what a storekeeper reads down a phone line, and **what replaced the thumbnail** on
  /// this row. Null only for a payload that arrived without its item.
  String? get code => item?.code;

  /// «25*35» — the size alone, for a line drawn under a heading that already named the material.
  ///
  /// Falls back to the whole [title] for a shelf counted without dimensions: there is no size to
  /// show there, and a blank line under a heading says less than a repeated name.
  String get sizeLabel => item?.sizeLabel ?? title;

  /// The material this shelf is a size of — what several shelves of one thing have in common,
  /// and therefore what groups them on the screen. The whole [title] when the item did not
  /// arrive, so an ungrouped line still stands under something it is named after.
  String get materialName => item?.name ?? title;
}

/// The shelf's own identity on a balance line: the material, the size, and the code that names
/// the pile. Six fields, flattened by the server because they are only ever met here.
///
/// **No product, deliberately** — the server's own comment on the resource, and the whole point
/// of the change. «كيس شحن سادة» and «كيس شحن مطبوع» both draw on this row, so naming or
/// picturing either of them here would be picking one arbitrarily and telling the storekeeper the
/// wrong thing. That is why this shape carries no `product_name`, no `product_id` and no
/// `image_url` — and why the row that used to lead with a photograph now leads with [code].
///
/// **`StockItemRef`, not `StockItem`.** `features/stock_items` owns the full model and this is
/// not it: that one requires `unit`, `unit_label`, `is_active` and `sort_order`, none of which
/// the server nests here, so parsing this six-key object with it would throw on the first shelf.
/// Naming the two apart also lets one file import both, which the recording sheet does — the
/// same reason `StockItemGroupRef` exists beside `StockItemGroup`.
///
/// **No unit here either**, and that is not an omission: the unit lives on the balance line
/// above, where it was snapshotted when the shelf was first stocked. Reading it off the item
/// would restate an old count in a new unit.
@freezed
abstract class StockItemRef with _$StockItemRef {
  const factory StockItemRef({
    required int id,

    /// `S7` — server-allocated, never settable.
    required String code,

    /// The material's name, without the size. [displayName] is what gets drawn.
    required String name,

    /// Null for something counted without dimensions — a roll, an ink. The two travel together:
    /// the server refuses a width with no height.
    @JsonKey(name: 'width_cm') int? widthCm,
    @JsonKey(name: 'height_cm') int? heightCm,

    /// «كيس شحن 25*35», composed server-side. Rendered as sent, never rebuilt.
    @JsonKey(name: 'display_name') required String displayName,
  }) = _StockItemRef;

  const StockItemRef._();

  factory StockItemRef.fromJson(Map<String, dynamic> json) => _$StockItemRefFromJson(json);

  bool get hasSize => widthCm != null && heightCm != null;

  /// «25*35» — the same separator the server composes [displayName] with, so the two read as one
  /// fact when a card puts the material above and the size below. Null for an unsized item,
  /// which has nothing to say here.
  String? get sizeLabel => hasSize ? '$widthCm*$heightCm' : null;
}
