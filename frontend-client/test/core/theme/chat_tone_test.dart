import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ألوان محادثة الدعم — وأوّلُ ما يُحرس فيها أن يُقرأ ما عليها.
///
/// **الشكوى التي وُلدت منها: «الألوان غير واضحة».** فقاعة العميل كانت البرتقالي الصريح بنصٍّ
/// أبيض (٣٫٢ إلى ١)، ووقتها رماديٌّ على البرتقالي (١٫٦ إلى ١) — لا يُقرأ. هذه الاختبارات تثبّت
/// القصد لا القيم: النصّ على كل فقاعة ٧ إلى ١ فأكثر، والوقت وعلامة القراءة ٤٫٥ إلى ١ فأكثر،
/// في الوضعين.
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

  test('فقاعتي بلون العلامة: برتقاليةُ الدرجة في الوضعين', () {
    // Arrange
    final hues = [for (final s in schemes) HSLColor.fromColor(s.outgoingBubble).hue];

    // Act - Assert — ما بين ١٠° و٣٠°، حيث `#F4622A` نفسه (١٦°).
    for (final hue in hues) {
      expect(hue, inInclusiveRange(10, 30));
    }
  });
}
