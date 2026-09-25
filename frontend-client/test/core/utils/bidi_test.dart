import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:flutter_test/flutter_test.dart';

/// «٢٥×٣٥» لا «٣٥×٢٥».
///
/// The bug these guard is one a string comparison cannot see: the text is right and the *screen*
/// is wrong, because the bidirectional algorithm reorders a measurement inside an Arabic line.
/// So the tests assert on where the isolate marks land, which is the only thing about the fix
/// that a test can hold.
///
/// Arrange - Act - Assert throughout.
void main() {
  // Written as escapes: the characters themselves are invisible and would silently
  // reorder this source file in any editor that honours them.
  const lri = '\u2066';
  const pdi = '\u2069';

  test('a bare measurement is isolated whole, the × kept inside it', () {
    // Arrange — the shape that flips: two numbers with a neutral between them.
    const label = '25×35';

    // Act
    final drawn = label.bidiSafe;

    // Assert — one isolate around the whole thing, not one around each number: two isolates
    // would leave the × outside, and it would flip exactly as before.
    expect(drawn, '$lri$label$pdi');
  });

  test('the Arabic around a measurement is left alone', () {
    // Arrange
    const summary = 'كيس شحن فلاير 25×35';

    // Act
    final drawn = summary.bidiSafe;

    // Assert
    expect(drawn, 'كيس شحن فلاير ${lri}25×35$pdi');
  });

  test('a trailing separator stays outside the isolate', () {
    // Arrange — «25×35 سم»: the space belongs to the sentence, not to the number, and pinning
    // it left-to-right opens a gap where the Arabic resumes.
    const label = '25×35 سم';

    // Act
    final drawn = label.bidiSafe;

    // Assert
    expect(drawn, '${lri}25×35$pdi سم');
  });

  test('two measurements in one line are isolated separately', () {
    // Arrange — the product card's size range.
    const range = '25×35 … 45×60 سم';

    // Act
    final drawn = range.bidiSafe;

    // Assert
    expect(drawn, '${lri}25×35$pdi … ${lri}45×60$pdi سم');
  });

  test('a thousands separator does not split a quantity in two', () {
    // Arrange — two isolates, around «5» and around «000», would reorder against each other.
    const quantity = '5,000 كيس';

    // Act
    final drawn = quantity.bidiSafe;

    // Assert
    expect(drawn, '${lri}5,000$pdi كيس');
  });

  test('text with no digits is returned unchanged, and is the same object', () {
    // Arrange — the common case, which must not pay for the rare one.
    const plain = 'كيس شحن فلاير';

    // Act
    final drawn = plain.bidiSafe;

    // Assert
    expect(identical(drawn, plain), isTrue);
  });

  test('Arabic-Indic digits are isolated too', () {
    // Arrange — the app draws Latin numerals today; the helper must not have to be rewritten
    // the day that changes.
    const label = '٢٥×٣٥';

    // Act
    final drawn = label.bidiSafe;

    // Assert
    expect(drawn, '$lri$label$pdi');
  });

  test('every isolate opened is closed', () {
    // Arrange — an unclosed LRI leaks its direction over the rest of the paragraph.
    const messy = 'طلبية #1228 · 5,000 كيس · 25×35 سم · 4,250.00 د.ل';

    // Act
    final drawn = messy.bidiSafe;

    // Assert
    expect(lri.allMatches(drawn).length, pdi.allMatches(drawn).length);
    expect(lri.allMatches(drawn), isNotEmpty);
  });
}
