import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_stock.freezed.dart';
part 'warehouse_stock.g.dart';

/// One shelf: how much of one size sits in one warehouse.
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
    @JsonKey(name: 'product_variant_id') required int productVariantId,

    required String quantity,

    /// What this balance is counted in, snapshotted when the shelf was first stocked and never
    /// re-derived — so a product whose pricing unit changes later cannot silently restate a
    /// balance that was counted the old way.
    required String unit,

    /// The server's Arabic for [unit], kept as a label rather than a translation table here —
    /// the same treatment `pricing_unit_label` gets everywhere else in this app.
    @JsonKey(name: 'unit_label') required String unitLabel,

    /// The level at which this shelf starts asking to be refilled, or null for one nobody set.
    @JsonKey(name: 'low_stock_threshold') String? lowStockThreshold,

    /// The server's answer, not a comparison this app re-derives — `null` threshold means "no
    /// alert", which is not the same as a threshold of zero.
    @JsonKey(name: 'is_low_stock') @Default(false) bool isLowStock,

    @JsonKey(name: 'product_variant') StockVariant? variant,

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

  /// «25*35» — the size alone, for a line drawn under a heading that already named the bag.
  String get sizeLabel => variant?.label ?? 'مقاس #$productVariantId';

  /// «أكياس شحن · 25*35», or just the size when the row came without its product.
  String get title => variant == null ? sizeLabel : '${variant!.productName} · ${variant!.label}';
}

/// The size a balance line is about, flattened by the server because it is only ever met here.
@freezed
abstract class StockVariant with _$StockVariant {
  const factory StockVariant({
    required int id,
    required String label,
    @JsonKey(name: 'product_id') required int productId,

    /// `P7` — what staff say out loud, and the one thing on a shelf row safe to read down a
    /// phone line. Nullable for a payload minted before the server started sending it.
    @JsonKey(name: 'product_code') String? productCode,

    @JsonKey(name: 'product_name') required String productName,

    /// The product's own photograph — there are none at size level, so every size of «أكياس
    /// الشحن» shares one. Null for a product nobody has photographed, and for a payload minted
    /// before the server started sending it.
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _StockVariant;

  factory StockVariant.fromJson(Map<String, dynamic> json) => _$StockVariantFromJson(json);
}
