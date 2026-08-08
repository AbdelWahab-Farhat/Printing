/// What kind of bag this is: printed with the customer's design, or plain.
///
/// **The app parses this for the badge's glyph and colour; it never uses it for the words on
/// screen.** Every product carries `category_label` from the server, and that is what is
/// rendered — so a category added to the backend tomorrow still shows the right Arabic, with a
/// neutral badge, instead of the app inventing a translation for it. Same split as
/// `OrderStatus`, for the same reason.
///
/// Mirrors `ProductCategory.php`.
enum ProductCategory {
  printed('printed', 'مطبوعة'),
  general('general', 'سادة'),

  /// A category this build has never heard of. Reached through [fromWire], never sent anywhere.
  unknown('', '');

  const ProductCategory(this.wire, this.label);

  /// Exactly the string the API sends in `category`.
  final String wire;

  /// **Only for naming a category the server has not named yet.**
  ///
  /// A *product* is labelled from its own `category_label`, always — that is the split at the
  /// top of this file and it does not move. But a filter chip and a form's choice row both have
  /// to say «مطبوعة» before any product exists to say it for them, and those two used to spell
  /// it separately: one in [ProductCategoryFilter], one in a private enum inside the product
  /// form. Two lists of the same two words is one list too many.
  final String label;

  /// Everything a person may actually choose. [unknown] is what the app *reads*, never what it
  /// offers — a form listing it would let somebody save a category the server cannot parse.
  static List<ProductCategory> get choices =>
      values.where((category) => category != unknown).toList(growable: false);

  static ProductCategory fromWire(String? wire) => values.firstWhere(
    (category) => category.wire == wire,
    orElse: () => unknown,
  );
}

/// How a bag is billed: by the piece, or by the kilo.
///
/// The same split as [ProductCategory] — a product shows its own `pricing_unit_label`, and this
/// exists for the one screen that has to name the units *before* there is a product: the form
/// where somebody picks one.
///
/// Mirrors `PricingUnit.php`.
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

/// What the catalogue can be narrowed to: everything, the printed bags, or the plain ones.
///
/// **A filter cannot use the server's words.** Everywhere a *product* is shown, its own
/// `category_label` is displayed, precisely so no translation table has to be kept in step. The
/// chips have to exist *before* any product is loaded, though, and a category absent from page
/// one would otherwise be unfilterable — so the Arabic comes from [ProductCategory.label],
/// which is the one place in this app that spells it.
///
/// It replaced a filter on the pricing *unit* — بالقطعة / بالكيلوغرام. Both narrow the same list,
/// but "plain or printed" is the question a customer actually opens with, and how the bag is
/// billed is something read off the card once the bag has been found.
enum ProductCategoryFilter {
  all(null, 'الكل'),
  printed(ProductCategory.printed),
  plain(ProductCategory.general);

  const ProductCategoryFilter(this.category, [this.ownLabel]);

  /// `null` for [all], which is what makes the parameter absent rather than empty.
  final ProductCategory? category;

  /// Only [all] has a word of its own — it stands for no category at all.
  final String? ownLabel;

  /// What the chip says. Read from the category itself, so «مطبوعة» is spelled once.
  String get label => ownLabel ?? category!.label;

  /// What the API is sent. Omitted entirely for [all] — an empty string would filter on one.
  String? get value => category?.wire;
}
