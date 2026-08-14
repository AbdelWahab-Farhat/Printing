/// How a bag is billed: by the piece, or by the kilo.
///
/// **A product shows its own `pricing_unit_label`**, always — so a unit added to the backend
/// tomorrow still reads in the right Arabic without this app being rebuilt. This enum exists for
/// the one screen that has to name the units *before* there is a product to read them off: the
/// form where somebody picks one.
///
/// It used to share this file with `ProductType` — مطبوعة/سادة — which is gone: that split never
/// fed a calculation and is a heading in the categories table now. See PRODUCT-CATEGORIES.md.
///
/// Mirrors `PricingUnit.php`.
library;

enum PricingUnit {
  piece('piece', 'بالقطعة'),
  kilogram('kilogram', 'بالكيلوغرام'),

  unknown('', '');

  const PricingUnit(this.wire, this.label);

  final String wire;
  final String label;

  static List<PricingUnit> get choices =>
      values.where((unit) => unit != unknown).toList(growable: false);

  /// Falls back to the commonest rather than to [unknown]: this is read to *open a form* on an
  /// existing product, and a unit this build has never heard of must not leave the choice row
  /// with nothing selected — the user would save the product having silently changed it.
  static PricingUnit fromWire(String? wire) =>
      values.firstWhere((unit) => unit.wire == wire, orElse: () => piece);
}
