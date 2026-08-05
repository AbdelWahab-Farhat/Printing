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
  printed('printed'),
  general('general'),

  /// A category this build has never heard of. Reached through [fromWire], never sent anywhere.
  unknown('');

  const ProductCategory(this.wire);

  /// Exactly the string the API sends in `category`.
  final String wire;

  static ProductCategory fromWire(String wire) =>
      values.firstWhere((category) => category.wire == wire, orElse: () => unknown);
}

/// What the catalogue can be narrowed to: everything, the printed bags, or the plain ones.
///
/// **The one place the app spells the category's Arabic.** Everywhere else the server's own
/// `category_label` is displayed, precisely so no translation table has to be kept in step. A
/// filter cannot work that way: the chips have to exist *before* any product is loaded, and a
/// category that happens to be absent from page one would otherwise be unfilterable.
///
/// It replaced a filter on the pricing *unit* — بالقطعة / بالكيلوغرام. Both narrow the same list,
/// but "plain or printed" is the question a customer actually opens with, and how the bag is
/// billed is something read off the card once the bag has been found.
enum ProductCategoryFilter {
  all(null, 'الكل'),
  printed(ProductCategory.printed, 'مطبوعة'),
  plain(ProductCategory.general, 'سادة');

  const ProductCategoryFilter(this.category, this.label);

  /// `null` for [all], which is what makes the parameter absent rather than empty.
  final ProductCategory? category;

  /// What the chip says.
  final String label;

  /// What the API is sent. Omitted entirely for [all] — an empty string would filter on one.
  String? get value => category?.wire;
}
