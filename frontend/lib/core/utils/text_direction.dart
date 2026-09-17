/// Which way one sentence runs — decided by the sentence, not by the app.
///
/// This app is Arabic and every screen in it is laid out right-to-left, which is right for
/// labels, buttons and headings: they are all ours and they are all Arabic. **A message box is
/// the one place that stops being true.** What a person types there is whatever they type — «ok»,
/// a file name, an English brief from a customer — and a Latin sentence rendered right-to-left
/// comes out with its full stop at the wrong end and its brackets mirrored. It is legible, and it
/// is visibly not what was typed.
///
/// **The rule is Unicode's own first-strong heuristic**, which is what every messaging app on
/// these phones already uses: the first letter that belongs to a direction decides for the whole
/// run. Digits, spaces and punctuation are not letters and are skipped, so «5% discount» leads
/// with `d` and «٥٪ خصم» leads with «خ».
///
/// **Null when there is no letter at all** — an empty box, a phone number, a lone emoji. Null is
/// not «left to right»: it means *this text has no opinion*, and whatever draws it keeps the
/// app's own direction rather than flipping a number into English.
///
/// Not `intl`'s `Bidi`: that one answers a bool, so «no strong letter» and «left to right» come
/// back as the same answer — and telling those two apart is the whole reason this exists.
library;

import 'dart:ui' show TextDirection;

/// The Arabic blocks in the order a reader meets them, then Hebrew: the letters themselves, the
/// two supplements, and the presentation forms that arrive pasted out of a PDF — see
/// `ArabicPresentationForms`, which folds those back into the letters behind them.
const String _rightToLeft =
    r'֐-׿؀-ۿ܀-ݏݐ-ݿࢠ-ࣿ'
    r'יִ-﷿ﹰ-﻿';

/// Latin, and the alphabets that read the same way: accented Latin, Greek, Cyrillic.
const String _leftToRight = r'A-Za-zÀ-ɏͰ-ϿЀ-ӿ';

final RegExp _firstLetter = RegExp('[$_rightToLeft$_leftToRight]');
final RegExp _readsRightToLeft = RegExp('[$_rightToLeft]');

extension ReadingDirection on String {
  /// Which way this text runs, or null when nothing in it is a letter.
  TextDirection? get readingDirection {
    final letter = _firstLetter.firstMatch(this)?[0];
    if (letter == null) return null;

    return _readsRightToLeft.hasMatch(letter) ? TextDirection.rtl : TextDirection.ltr;
  }
}
