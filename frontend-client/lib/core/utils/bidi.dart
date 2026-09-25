/// «٢٥×٣٥» drawn as «٢٥×٣٥», and not as «٣٥×٢٥».
///
/// **A measurement written inside an Arabic sentence comes out backwards, and nothing warns
/// you.** The Unicode bidirectional algorithm reads `25×35` in a right-to-left paragraph as
/// three pieces: two European numbers, and a `×` between them. Rule N1 says a neutral character
/// flanked by numbers takes the paragraph's own direction — so the `×` becomes right-to-left,
/// the two numbers sit inside it as left-to-right islands, and the run is reordered. The reader
/// is shown **`35×25`**: a real size, for a bag we do not sell, in place of the one they asked
/// for.
///
/// It is invisible in a test — the string is correct, and `expect(text, '25×35')` passes — and
/// invisible in code review, because the bug is in the renderer's reading of a string nobody
/// wrote wrong. It shows up only on a screen, to somebody who knows what size they ordered.
///
/// The fix is an **isolate**, `U+2066 LEFT-TO-RIGHT ISOLATE` … `U+2069 POP DIRECTIONAL ISOLATE`.
/// Isolate rather than embedding (`U+202A`): an isolate also stops the run from influencing the
/// neutrals *around* it, so the Arabic either side keeps its own ordering. Nothing is added to
/// the text itself — these are formatting characters, invisible and zero-width.
///
/// Applied at the point of drawing, never at the point of parsing: a model carrying invisible
/// control characters would compare unequal to the same value read back from the server, and
/// would carry them into a search box, a log line and an order note.
library;

extension BidiIsolation on String {
  /// The same text with every run of digits and separators pinned to left-to-right.
  ///
  /// A run is digits — Western or Arabic-Indic — plus the characters that hold a measurement or
  /// a number together: `× x . , / : -` and a space between two of them. Arabic letters end a
  /// run, so «٥٬٠٠٠ كيس · بشعارك» isolates the quantity and leaves the words alone.
  ///
  /// Returns the same object when there is nothing to isolate, which is most strings.
  String get bidiSafe {
    if (!_hasDigit) return this;

    final buffer = StringBuffer();
    var start = -1;

    void closeRun(int end) {
      if (start < 0) return;

      // Trim separators off the ends: an isolate around «25×35 » would pin a trailing space
      // left-to-right and open a gap where the Arabic resumes.
      final from = start;
      var to = end;

      while (to > from && !_isDigit(codeUnitAt(to - 1))) {
        to--;
      }

      if (to > from) {
        buffer
          ..writeCharCode(_lri)
          ..write(substring(from, to))
          ..writeCharCode(_pdi);
      }

      buffer.write(substring(to, end));
      start = -1;
    }

    for (var index = 0; index < length; index++) {
      final unit = codeUnitAt(index);

      if (_isDigit(unit)) {
        if (start < 0) start = index;
        continue;
      }

      if (start >= 0 && _isJoiner(unit)) continue;

      if (start >= 0) {
        closeRun(index);
      }

      buffer.writeCharCode(unit);
    }

    closeRun(length);

    return buffer.toString();
  }

  /// النصّ كلّه معزولاً من اليسار إلى اليمين — «#1304» داخل عنوانٍ عربي.
  ///
  /// **[bidiSafe] لا يكفي هنا، لأن «#» ليست من الرقم عنده.** قبل الرمز كلمةٌ عربية، فتجعل
  /// القاعدة W2 الأرقامَ بعدها أرقاماً عربية، و«#» التي كانت ستلتصق بها تصير محايدةً تأخذ
  /// اتجاه السطر — فتنزل على يمين الرقم ويُقرأ العنوان «1304#». العزل هنا للرمز كلّه.
  String get ltrIsolated => '${String.fromCharCode(_lri)}$this${String.fromCharCode(_pdi)}';

  bool get _hasDigit {
    for (var index = 0; index < length; index++) {
      if (_isDigit(codeUnitAt(index))) return true;
    }

    return false;
  }
}

const int _lri = 0x2066;
const int _pdi = 0x2069;

/// Western `0-9` and Arabic-Indic `٠-٩`, so the helper keeps working the day the app stops
/// leaving numerals Latin.
bool _isDigit(int unit) =>
    (unit >= 0x30 && unit <= 0x39) || (unit >= 0x0660 && unit <= 0x0669);

/// What may sit *inside* a number without ending it. `×` and `x` are the ones that matter —
/// they are the neutral that flips a measurement — and the rest are here because a run broken in
/// the middle is isolated as two runs and reorders between them.
bool _isJoiner(int unit) => switch (unit) {
  0x00D7 || // ×
      0x0078 || // x
      0x002E || // .
      0x002C || // ,
      0x066B || // ٫ Arabic decimal separator
      0x066C || // ٬ Arabic thousands separator
      0x002F || // /
      0x003A || // :
      0x002D || // -
      0x0020 => true, // space, between two parts of one number
  _ => false,
};
