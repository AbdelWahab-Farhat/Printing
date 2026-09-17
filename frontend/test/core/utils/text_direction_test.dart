import 'dart:ui';

import 'package:dayaa/core/utils/text_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which way one sentence runs, decided by the sentence rather than by the app.
///
/// The app is Arabic and everything in it runs right-to-left — but a message box is the one
/// place a person types whatever they like, and «ok» or a file name or an English brief typed
/// into an RTL box comes out with its punctuation at the wrong end. The rule is Unicode's own
/// first-strong heuristic, which is what every messaging app on these phones uses.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('the first strong letter decides', () {
    test('Arabic runs right to left', () {
      // Arrange
      const text = 'وصلني، أبدأ اليوم';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.rtl);
    });

    test('Latin runs left to right', () {
      // Arrange
      const text = 'ok, sending the PDF now';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.ltr);
    });

    test('digits and punctuation before the first letter are skipped', () {
      // Arrange — «٥٪ خصم» and «5% discount» are the same shape, and the digits say nothing
      // about which way either of them runs.
      const arabic = '٥٪ خصم';
      const latin = '5% discount';

      // Act & Assert
      expect(arabic.readingDirection, TextDirection.rtl);
      expect(latin.readingDirection, TextDirection.ltr);
    });

    test('a Latin word ahead of Arabic still leads', () {
      // Arrange — first-strong, not majority: this is what puts «QR» at the start of the line
      // where the person typed it.
      const text = 'QR لازم يكون واضح';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.ltr);
    });
  });

  group('when nothing in it is a letter', () {
    test('an empty string decides nothing', () {
      // Arrange - Act - Assert — null, so whatever holds it keeps the app's own direction
      // rather than being forced into English.
      expect(''.readingDirection, isNull);
    });

    test('digits alone decide nothing', () {
      // Arrange
      const text = '0911234567';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, isNull);
    });

    test('an emoji decides nothing', () {
      // Arrange
      const text = '👍';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, isNull);
    });
  });

  test('pre-shaped Arabic runs right to left like the letters behind it', () {
    // Arrange — the presentation-forms block, which is what arrives pasted out of a PDF. See
    // ArabicPresentationForms: the same text, written a second way.
    const text = 'ﺷﺮﻛﺔ';

    // Act
    final direction = text.readingDirection;

    // Assert
    expect(direction, TextDirection.rtl);
  });
}
