/// What a catalogue can be narrowed to: everything, the things sold by the piece, or the things
/// sold by weight.
///
/// **The one place the app spells a backend value.** Everywhere else the server's own
/// `pricing_unit_label` is displayed, precisely so no translation table has to be kept in step.
/// A filter cannot work that way: the chips have to exist *before* any product is loaded, and a
/// unit that happens to be absent from page one would otherwise be unfilterable.
///
/// It is safe here because [PricingUnit] on the backend is a closed enum of exactly these two —
/// a bag is priced per piece or per kilo, and there is no third way to sell one. If a third ever
/// appears, this file is where it lands, and [value] is what has to match.
enum PricingUnitFilter {
  all(value: null, label: 'الكل'),
  piece(value: 'piece', label: 'بالقطعة'),
  kilogram(value: 'kilogram', label: 'بالكيلوغرام');

  const PricingUnitFilter({required this.value, required this.label});

  /// What the API is sent. `null` for [all] — the parameter is omitted entirely rather than
  /// sent empty, which would filter on an empty string.
  final String? value;

  /// What the chip says.
  final String label;
}
