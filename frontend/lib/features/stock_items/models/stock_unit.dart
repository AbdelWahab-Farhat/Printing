import 'package:freezed_annotation/freezed_annotation.dart';

/// What a pile is counted in — «قطعة» or «كيلوغرام».
///
/// **Deliberately not `features/products/models/pricing_unit.dart`, though the wire values
/// match.** That enum answers a different question in different words: it is what the *customer
/// is charged by*, and its Arabic reads «بالقطعة» — "billed by the piece". A shelf's unit is a
/// noun somebody counts in, and the server sends it as «قطعة». Borrowing the pricing wording
/// would print «بالكيلوغرام» in a confirm dialog two lines under the same server field rendered
/// as «كيلوغرام», and the two would be read as two different facts.
///
/// The backend drew the same line the hard way: `products.stock_unit` was **dropped** and
/// `stock_items.unit` replaced it, because «كيس شحن سادة» and «كيس شحن مطبوع» share one pile and
/// cannot be allowed to disagree about how it is counted. `pricing_unit` stayed exactly where it
/// was — a thing bought in by weight and sold by the piece needs the two to differ.
///
/// **A shelf's unit is not free to change.** `PATCH /stock-items/{id}/unit` does not convert the
/// balance, it discards it — see `showStockUnitSheet`, which is the only control in this app
/// allowed to send one.
///
/// Mirrors `PricingUnit.php`, whose `label()` is exactly the Arabic below.
enum StockUnit {
  @JsonValue('piece')
  piece('piece', 'قطعة'),

  @JsonValue('kilogram')
  kilogram('kilogram', 'كيلوغرام'),

  /// A unit the server grew after this build shipped. `unknown` rather than a throw: nothing
  /// branches on a case — every row draws its own `unit_label`, which arrives with it — so a
  /// shelf counted in something this app cannot name still reads correctly on every screen.
  unknown('', '');

  const StockUnit(this.wire, this.label);

  /// The API's own value. **`unknown`'s empty string never travels**: the one control that sends
  /// a unit offers [choices], and the one that reads a unit off a row sends the row's own.
  final String wire;

  /// The Arabic to write when there is no row to quote a `unit_label` from — the form creating
  /// the first shelf of a material has nothing to read one off yet. Everywhere a stock item is
  /// in hand, `stockItem.unitLabel` is what gets drawn instead.
  final String label;

  /// What a picker offers. [unknown] is not one of them: a unit this build cannot name is a unit
  /// it must not ask somebody to choose.
  static List<StockUnit> get choices =>
      values.where((unit) => unit != unknown).toList(growable: false);

  /// Falls back to [piece] rather than to [unknown]: this is read to *open a form*, and a unit
  /// this build has never heard of must not leave the choice row with nothing selected — the
  /// person would save having silently changed it.
  static StockUnit fromWire(String? wire) =>
      values.firstWhere((unit) => unit.wire == wire, orElse: () => piece);
}
