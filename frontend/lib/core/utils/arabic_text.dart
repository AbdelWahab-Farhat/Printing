/// Arabic that arrived already shaped, folded back into the letters it is made of.
///
/// **Two ways of writing the same word.** «شركة» is normally four letters from the Arabic block
/// (`U+0621`–`U+064A`), and whatever draws it decides how each one joins to its neighbour. But
/// text keyed on some Windows layouts, pasted out of a PDF, or copied from an older system
/// arrives pre-joined instead — «ﺷﺮﻛﺔ», four codepoints from the **Arabic Presentation Forms**
/// block (`U+FE70`–`U+FEFC`), one per shape. On a screen the two are indistinguishable: the
/// system font carries both.
///
/// **A PDF is where the difference stops being invisible.** Almarai — like most modern Arabic
/// faces — has no glyphs for the presentation block, because the shaping is the renderer's job.
/// An invoice built from such text either draws the wrong letters or, when the font subsetter
/// cannot find anything to substitute, throws and takes the whole document with it: «تعذّر إنشاء
/// ملف الفاتورة» on order 1228 was one `ﻱ` (`U+FEF1`) in the order's own text.
///
/// So the letters are folded back before they are drawn. This is not normalisation in general —
/// no `NFKC`, no dependency — it is the one block that breaks the invoice, mapped to the letters
/// it stands for.
library;

extension ArabicPresentationForms on String {
  /// The same text with every pre-shaped letter written as the letter itself.
  ///
  /// Returns the string it was given — the same object — when there is nothing to fold, which is
  /// every ordinary Arabic string the app holds. The rare case pays; the common one does not.
  String get deshaped {
    if (!_carriesForm) return this;

    final buffer = StringBuffer();

    for (final rune in runes) {
      if (rune < _first || rune > _last) {
        buffer.writeCharCode(rune);
        continue;
      }

      // A form outside the table is a shape with no letter behind it — kept rather than
      // guessed at, so nothing is silently dropped that a reader would have missed.
      buffer.write(_letters[rune] ?? String.fromCharCode(rune));
    }

    return buffer.toString();
  }

  bool get _carriesForm {
    for (final rune in runes) {
      if (rune >= _first && rune <= _last) return true;
    }

    return false;
  }
}

const int _first = 0xFE70;
const int _last = 0xFEFC;

/// Every codepoint in the block, against the letters it was drawn from.
///
/// **Ranges rather than 140 lines**, because the block is laid out by letter: two forms for a
/// letter that never joins to its left (ا، د، ر، و), four for one that does — isolated, final,
/// initial, medial, in that order. The last four entries are the lam-alef ligatures, which are
/// one codepoint standing for two letters and the reason this returns strings and not runes.
const List<(int, int, String)> _folds = [
  (0xFE70, 0xFE71, 'ً'), // ً  — the tatweel the second form carries is a stretch, not a mark
  (0xFE72, 0xFE72, 'ٌ'), // ٌ
  (0xFE73, 0xFE73, ''), // the tail fragment: a piece of a shape, standing for no letter at all
  (0xFE74, 0xFE74, 'ٍ'), // ٍ
  (0xFE76, 0xFE77, 'َ'), // َ
  (0xFE78, 0xFE79, 'ُ'), // ُ
  (0xFE7A, 0xFE7B, 'ِ'), // ِ
  (0xFE7C, 0xFE7D, 'ّ'), // ّ
  (0xFE7E, 0xFE7F, 'ْ'), // ْ
  (0xFE80, 0xFE80, 'ء'), // ء
  (0xFE81, 0xFE82, 'آ'), // آ
  (0xFE83, 0xFE84, 'أ'), // أ
  (0xFE85, 0xFE86, 'ؤ'), // ؤ
  (0xFE87, 0xFE88, 'إ'), // إ
  (0xFE89, 0xFE8C, 'ئ'), // ئ
  (0xFE8D, 0xFE8E, 'ا'), // ا
  (0xFE8F, 0xFE92, 'ب'), // ب
  (0xFE93, 0xFE94, 'ة'), // ة
  (0xFE95, 0xFE98, 'ت'), // ت
  (0xFE99, 0xFE9C, 'ث'), // ث
  (0xFE9D, 0xFEA0, 'ج'), // ج
  (0xFEA1, 0xFEA4, 'ح'), // ح
  (0xFEA5, 0xFEA8, 'خ'), // خ
  (0xFEA9, 0xFEAA, 'د'), // د
  (0xFEAB, 0xFEAC, 'ذ'), // ذ
  (0xFEAD, 0xFEAE, 'ر'), // ر
  (0xFEAF, 0xFEB0, 'ز'), // ز
  (0xFEB1, 0xFEB4, 'س'), // س
  (0xFEB5, 0xFEB8, 'ش'), // ش
  (0xFEB9, 0xFEBC, 'ص'), // ص
  (0xFEBD, 0xFEC0, 'ض'), // ض
  (0xFEC1, 0xFEC4, 'ط'), // ط
  (0xFEC5, 0xFEC8, 'ظ'), // ظ
  (0xFEC9, 0xFECC, 'ع'), // ع
  (0xFECD, 0xFED0, 'غ'), // غ
  (0xFED1, 0xFED4, 'ف'), // ف
  (0xFED5, 0xFED8, 'ق'), // ق
  (0xFED9, 0xFEDC, 'ك'), // ك
  (0xFEDD, 0xFEE0, 'ل'), // ل
  (0xFEE1, 0xFEE4, 'م'), // م
  (0xFEE5, 0xFEE8, 'ن'), // ن
  (0xFEE9, 0xFEEC, 'ه'), // ه
  (0xFEED, 0xFEEE, 'و'), // و
  (0xFEEF, 0xFEF0, 'ى'), // ى
  (0xFEF1, 0xFEF4, 'ي'), // ي — the one that took order 1228's invoice down
  (0xFEF5, 0xFEF6, 'لآ'), // لآ
  (0xFEF7, 0xFEF8, 'لأ'), // لأ
  (0xFEF9, 0xFEFA, 'لإ'), // لإ
  (0xFEFB, 0xFEFC, 'لا'), // لا
];

/// The ranges spread one entry per codepoint, built once at first use.
final Map<int, String> _letters = {
  for (final (first, last, letter) in _folds)
    for (var rune = first; rune <= last; rune++) rune: letter,
};
