import 'package:dayaa/core/utils/arabic_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arabic that arrived already shaped, folded back into the letters it is made of.
///
/// **This is not cosmetic.** Text typed on some Windows keyboards, pasted out of a PDF or copied
/// from an old system arrives in the Arabic Presentation Forms block — «ﻱ» (U+FEF1) instead of
/// «ي» (U+064A). It looks identical on the screen, because the system font draws both; it took an
/// invoice down, because Almarai has no glyph for the shaped forms and the PDF's font subsetter
/// throws rather than skipping the character. See ORDER-INVOICE-MESSAGE.md.
///
/// Arrange - Act - Assert throughout.
void main() {
  test('a shaped yeh is the same letter as a plain one', () {
    // Arrange — U+FEF1, the character that stopped order 1228's invoice.
    const shaped = 'ﻱ';

    // Act
    final folded = shaped.deshaped;

    // Assert
    expect(folded, 'ي');
    expect(folded.codeUnitAt(0), 0x064A);
  });

  test('every form of a letter folds to the one letter', () {
    // Arrange — isolated, final, initial and medial, which is how the block is laid out.
    const forms = 'ﺏﺐﺑﺒ';

    // Act
    final folded = forms.deshaped;

    // Assert
    expect(folded, 'بببب');
  });

  test('a shaped word reads as the word it was', () {
    // Arrange — «شركة» keyed in presentation forms.
    const shaped = 'ﺵﺮﻛﺔ';

    // Act
    final folded = shaped.deshaped;

    // Assert
    expect(folded, 'شركة');
  });

  test('a lam-alef ligature is the two letters it stands for', () {
    // Arrange — one codepoint (U+FEFB) that is two letters.
    const ligature = 'ﻻ';

    // Act
    final folded = ligature.deshaped;

    // Assert
    expect(folded, 'لا');
    expect(folded.length, 2);
  });

  test('the vowel marks fold too, and the tail fragment goes', () {
    // Arrange — a shadda (U+FE7C) and the tail fragment (U+FE73), which stands for no letter.
    const marks = 'ﻼ';

    // Act
    final shadda = 'ﹼ'.deshaped;
    final tail = 'ﹳ'.deshaped;

    // Assert
    expect(shadda, 'ّ');
    expect(tail, isEmpty);
    expect(marks.deshaped, 'لا');
  });

  test('text that was never shaped is handed back untouched', () {
    // Arrange — the ordinary case, which must not pay for the rare one.
    const plain = 'شركة بريمولا — أكياس شحن 1,000 قطعة';

    // Act
    final folded = plain.deshaped;

    // Assert
    expect(identical(folded, plain), isTrue);
  });
}
