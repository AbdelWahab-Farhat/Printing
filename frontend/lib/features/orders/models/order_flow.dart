import 'package:freezed_annotation/freezed_annotation.dart';

/// Which road an order walks — stamped by the server off the lines' categories at intake.
///
/// Mirrors `OrderFlow.php`. **Not a copy of the rules**: the transitions and the progress bar
/// arrive already resolved. It is carried for the one question the edit screen has to answer
/// before the server does — which bench the lines already on the order belong to — because an
/// order line does not carry its product's category. See [isOrderedAlone].
enum OrderFlow {
  /// The press runs — «المسار المعتاد».
  @JsonValue('standard')
  standard,

  /// Goods already made, picked off our shelf — «بلا تصميم وطباعة».
  @JsonValue('no_production')
  noProduction,

  /// An outside vendor makes it — «مسار الوسيط».
  @JsonValue('outsourced')
  outsourced,

  /// A road this build has never heard of. Treated as ours, the road that asks more of the shop.
  unknown;

  /// Whether the lines on an order walking this road go in an order of their own — the order's
  /// half of [ProductionMode.isOrderedAlone].
  ///
  /// **The stamped road, so it can lag a heading re-filed after the order was taken.** That
  /// costs a warning shown late or early on the edit screen, never a wrong order: the server
  /// reads the lines themselves and has the last word.
  bool get isOrderedAlone => this == OrderFlow.outsourced;
}
