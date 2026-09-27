/// Arabic folded to the letters a person searching for it would actually type.
///
/// Nobody types «سعر البيع» the way it is stored. They type «اسعار» for «أسعار», «ه» for «ة»,
/// «ي» for «ى», and they never type the vowel marks. A search that compares the stored text to
/// the typed text letter for letter answers «لا نتائج» to all of them, which reads as «this does
/// not exist» rather than «you spelled it the other way».
///
/// So both sides are folded the same way before they are compared: hamza seats onto a bare alef,
/// the tied ta onto ha, alef maqsura onto ya, marks and the tatweel dropped, Latin lower-cased,
/// and anything pre-shaped written as its letters first (see [ArabicPresentationForms]).
library;

import 'package:dayaa/core/utils/arabic_text.dart';

extension ArabicSearch on String {
  /// This text as a search compares it.
  String get searchFolded {
    final buffer = StringBuffer();

    for (final rune in deshaped.toLowerCase().runes) {
      if (_dropped(rune)) continue;
      buffer.writeCharCode(_folds[rune] ?? rune);
    }

    return buffer.toString().trim();
  }

  /// Whether every word of [query] appears somewhere in this text, in any order.
  ///
  /// Words rather than the whole phrase, and anywhere rather than at the start: «بيع سعر» and
  /// «البيع» should both find «سعر البيع». An empty query matches everything — a box with
  /// nothing typed in it is not a search yet.
  bool matchesSearch(String query) {
    final haystack = searchFolded;

    return query.searchFolded
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(haystack.contains);
  }
}

/// The harakat, the superscript alef and the tatweel — nothing anybody types into a search box.
bool _dropped(int rune) => (rune >= 0x064B && rune <= 0x0652) || rune == 0x0670 || rune == 0x0640;

const Map<int, int> _folds = {
  0x0623: 0x0627, // أ → ا
  0x0625: 0x0627, // إ → ا
  0x0622: 0x0627, // آ → ا
  0x0671: 0x0627, // ٱ → ا
  0x0629: 0x0647, // ة → ه
  0x0649: 0x064A, // ى → ي
};
