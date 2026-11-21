import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ألوان محادثة الدعم — وأوّلُ ما يُحرس فيها أن يُقرأ ما عليها.
///
/// **Born of a complaint: «الألوان غير واضحة».** The customer's bubble was once the solid brand
/// colour with white text (3.2 to 1) and grey time on it (1.6 to 1), unreadable. These tests pin
/// the intent rather than the values: text on each bubble at 7 to 1 or better, time and read mark
/// at 4.5 to 1 or better, in both appearances.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);

    return (hi + 0.05) / (lo + 0.05);
  }

  const schemes = [MaterialTheme.lightScheme, MaterialTheme.darkScheme];

  test('نصُّ الرسالة يُقرأ على الفقاعتين في الوضعين', () {
    // Arrange
    final pairs = [
      for (final s in schemes) ...[
        (ink: s.onOutgoingBubble, on: s.outgoingBubble),
        (ink: s.onIncomingBubble, on: s.incomingBubble),
      ],
    ];

    // Act
    final ratios = [for (final pair in pairs) contrast(pair.ink, pair.on)];

    // Assert
    for (final ratio in ratios) {
      expect(ratio, greaterThanOrEqualTo(7));
    }
  });

  test('الوقت وعلامة القراءة يُقرآن على الفقاعتين في الوضعين', () {
    // Arrange — خطٌّ صغير، فالحدّ ٤٫٥ لا ٣.
    final pairs = [
      for (final s in schemes) ...[
        (ink: s.outgoingMeta, on: s.outgoingBubble),
        (ink: s.incomingMeta, on: s.incomingBubble),
      ],
    ];

    // Act
    final ratios = [for (final pair in pairs) contrast(pair.ink, pair.on)];

    // Assert
    for (final ratio in ratios) {
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

  test('my bubble is in the brand: the logo\'s purple, in both appearances', () {
    // Arrange
    final hues = [for (final s in schemes) HSLColor.fromColor(s.outgoingBubble).hue];

    // Act - Assert: within 15° of `#4C29D0` itself (253°).
    for (final hue in hues) {
      expect(hue, inInclusiveRange(238, 268));
    }
  });
}
