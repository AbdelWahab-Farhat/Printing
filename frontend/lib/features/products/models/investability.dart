/// The answers a catalogue heading can give to «هل هو قابل للاستثمار؟».
///
/// `ProductCategory.isInvestable` travels as a nullable boolean, and **null is an answer** —
/// «حسب الرئيسي» — not a missing one. This is that same answer in one word, so the sheet's
/// picker has a type to stand on and the third state stays visible: a switch has two positions
/// and would quietly turn «اسأل الأب» into «لا» the first time somebody saved a subheading.
///
/// A vocabulary for the screen, not for the wire. What goes out is [value].
enum Investability {
  /// Take the parent heading's answer.
  ///
  /// Offered only where there is a parent to ask — see [choicesFor]. A root holding null is not
  /// investable, which is what [no] says out loud.
  inherit(null, 'حسب الرئيسي'),

  yes(true, 'نعم'),

  no(false, 'لا');

  const Investability(this.value, this.label);

  /// What the API holds: null, true or false, exactly as the column does.
  final bool? value;

  final String label;

  /// The answer a stored value stands for.
  ///
  /// [hasParent] is what null means on screen: a subheading is inheriting, while a root has
  /// nobody to inherit from and is simply not investable — and drawing «حسب الرئيسي» there
  /// would light a segment that points at nothing.
  static Investability of(bool? value, {required bool hasParent}) => switch (value) {
    true => Investability.yes,
    false => Investability.no,
    null => hasParent ? Investability.inherit : Investability.no,
  };

  /// What a heading may be asked: three answers for a subheading, two for a root.
  static List<Investability> choicesFor({required bool hasParent}) =>
      hasParent ? values : const [yes, no];
}
