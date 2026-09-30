import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ألوان محادثة الدعم على شاشة الموظف — وأوّلُ ما يُحرس فيها أن يُقرأ ما عليها.
///
/// **من أدوار الثيم لا من هكس**: ردُّ المحل `primaryContainer` بحبره، وفقاعة العميل سطحٌ أفتح
/// من خلفية المحادثة. فالاختبار يثبّت القصد لا القيم: النصّ ٧ إلى ١، والوقت وعلامة القراءة ٤٫٥
/// إلى ١ — مخلوطاً بشفافيته فوق فقاعته، كما يُرسم — وفقاعة العميل تبين عن الخلفية، في الوضعين.
///
/// Arrange - Act - Assert في كل حالة.
void main() {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (hi, lo) = la > lb ? (la, lb) : (lb, la);

    return (hi + 0.05) / (lo + 0.05);
  }

  final schemes = [MaterialTheme.lightScheme(), MaterialTheme.darkScheme()];

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
    final ratios = [
      for (final pair in pairs) contrast(Color.alphaBlend(pair.ink, pair.on), pair.on),
    ];

    // Assert
    for (final ratio in ratios) {
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

  test('فقاعةُ العميل ليست لونَ الخلفية التي تحتها', () {
    // Arrange - Act
    final pairs = [for (final s in schemes) (s.incomingBubble, s.chatBackdrop)];

    // Assert — فقاعةٌ بلون الخلفية كلامٌ بلا حدود؛ تبين بالتعبئة والشعرة، بلا ظلّ.
    for (final (bubble, backdrop) in pairs) {
      expect(bubble, isNot(backdrop));
    }
  });
}
