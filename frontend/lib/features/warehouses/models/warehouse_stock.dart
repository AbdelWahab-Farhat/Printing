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
  String get quantityLabel => trimDecimals(quantity);

  String? get thresholdLabel =>
      lowStockThreshold == null ? null : trimDecimals(lowStockThreshold!);

  /// «أكياس شحن · 25*35», or just the size when the row came without its product.
  String get title => variant == null
      ? 'مقاس #$productVariantId'
      : '${variant!.productName} · ${variant!.label}';
}

/// The size a balance line is about, flattened by the server because it is only ever met here.
@freezed
abstract class StockVariant with _$StockVariant {
  const factory StockVariant({
    required int id,
    required String label,
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_name') required String productName,
  }) = _StockVariant;

  factory StockVariant.fromJson(Map<String, dynamic> json) => _$StockVariantFromJson(json);
}

/// `'100.000'` → `'100'`, `'0.850'` → `'0.85'`.
///
/// String surgery, not `double.parse().toString()`: the decimals the server chose to send are
/// the decimals it means, and round-tripping them through a float loses that.
String trimDecimals(String value) {
  if (!value.contains('.')) return value;

  final trimmed = value.replaceFirst(RegExp(r'0+$'), '');

  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}
