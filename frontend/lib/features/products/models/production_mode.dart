import 'package:freezed_annotation/freezed_annotation.dart';

/// How goods under a heading come to exist — the lever an order's road is decided by.
///
/// Mirrors `ProductionMode.php`. It replaced a boolean (`skips_production`) the day «وسيط»
/// arrived, because the shop has three kinds of work and a boolean can hold two.
///
/// [unknown] for the same reason every other enum here has one: a fourth mode added on the server
/// must not turn a whole category list into a parse failure. Never send it.
///
/// The Arabic here is for a picker that must name a mode nothing is currently set to; wherever a
/// row arrives with `production_mode_label`, that is the word drawn — the same split
/// `OrderStatus` makes between its `label` and the server's `status_label`.
enum ProductionMode {
  /// مطبوعة — we design it and we print it. What every heading is until somebody says otherwise.
  @JsonValue('in_house')
  inHouse('in_house', 'تصميم وطباعة لدينا'),

  /// سادة — already made, picked off our shelf and counted.
  @JsonValue('none')
  none('none', 'بلا تصميم وطباعة'),

  /// وسيط — an outside vendor makes it. The only mode that carries a cost price, needs a vendor
  /// on the order, and deducts nothing from a warehouse.
  @JsonValue('outsourced')
  outsourced('outsourced', 'وسيط — لدى مورد خارجي'),

  unknown('unknown', 'غير معروفة');

  const ProductionMode(this.wire, this.label);

  /// Exactly the string the API sends and accepts.
  final String wire;

  /// The Arabic the sheet's picker prints. Never used for a row that came with its own label.
  final String label;

  /// The three a person may choose between — [unknown] is this app's own and is never sent.
  static List<ProductionMode> get choices =>
      values.where((mode) => mode != ProductionMode.unknown).toList(growable: false);

  /// Whether a size filed under this heading may carry «سعر التكلفة» at all. The server refuses
  /// one anywhere else with a 422, so this decides whether the box is drawn.
  bool get hasCostPrice => this == ProductionMode.outsourced;

  /// Whether an order made only of these goods must name the vendor executing it.
  bool get needsAVendor => this == ProductionMode.outsourced;
}
