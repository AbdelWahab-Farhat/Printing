import 'dart:math' as math;

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مدفوعة بالكامل» — الأخضر، وكم يبعد عن برتقالي التطبيق.
///
/// The one colour in this app written outside `theme.dart`, so it is the one colour with nothing
/// else keeping it honest. These tests pin the *intent* rather than the six values: the family
/// sits in the green band, stays well clear of the `primary` it exists to be distinguishable
/// from, and each container still carries text anybody can read.
///
/// **They have just earned their keep.** The palette moved from the staff app's teal to this
/// app's orange, and the distance assertion below was written without `.abs()` — it passed only
/// because teal's hue happened to be the larger of the two. Against orange it went negative and
/// failed, which is exactly the kind of quiet wrong these tests exist to catch.
///
/// Arrange - Act - Assert throughout.
void main() {
  double hueOf(Color colour) => HSLColor.fromColor(colour).hue;

  /// 120° is pure green. The band was chosen to keep «مدفوعة بالكامل» clear of the teal it used
  /// to sit beside; against orange it has an easier job and is kept as it was.
  const green = (low: 130.0, high: 145.0);

  test('the paid tones sit in the green band', () {
    // Arrange
    const scheme = MaterialTheme.darkScheme;

    // Act
    final hues = [hueOf(scheme.paid), hueOf(scheme.paidContainer), hueOf(scheme.onPaidContainer)];

    // Assert
    for (final hue in hues) {
      expect(hue, inInclusiveRange(green.low, green.high));
    }
  });

  test('the green is far enough from the app\'s orange to read as another colour', () {
    // Arrange
    const scheme = MaterialTheme.darkScheme;

    // Act — **`.abs()`, because a hue gap has no sign.** Which of the two is the larger number
    // is an accident of where each one lands on the wheel, and the question being asked is how
    // far apart they are.
    final gap = (hueOf(scheme.primary) - hueOf(scheme.paid)).abs();

    // Assert — a chip and the price directly beneath it must not look like the same decision.
    expect(gap, greaterThan(35));
  });

  test('the pale fill still carries its text', () {
    // Arrange
    const scheme = MaterialTheme.darkScheme;

    // Act - Assert — leaning greener must not cost the pair its contrast.
    final gap =
        (scheme.paidContainer.computeLuminance() - scheme.onPaidContainer.computeLuminance())
            .abs();

    expect(gap, greaterThan(0.4));
  });

  group('the deep end of the account card', () {
    /// نسبة التباين كما تعرّفها WCAG: الأفتح على الأغمق، وكلٌّ منهما مزاحٌ بـ ٠٫٠٥.
    double contrast(Color a, Color b) {
      final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
          ? (a.computeLuminance(), b.computeLuminance())
          : (b.computeLuminance(), a.computeLuminance());

      return (lighter + 0.05) / (darker + 0.05);
    }

    test('carries white text at body size, in both appearances', () {
      // Arrange — البطاقة بلون العلامة في الوضعين، فالزوج نفسه يُفحص مرتين.
      const schemes = [MaterialTheme.lightScheme, MaterialTheme.darkScheme];

      // Act
      final ratios = [for (final s in schemes) contrast(s.onPrimary, s.primaryDeep)];

      // Assert — ٤٫٥ إلى ١ هي عتبة النص بحجمه العادي، ورقم الهاتف يجلس على هذا الطرف.
      for (final ratio in ratios) {
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    });

    test('is still the brand\'s orange, only deeper', () {
      // Arrange
      const scheme = MaterialTheme.lightScheme;

      // Act
      final gap = (hueOf(scheme.primaryDeep) - hueOf(scheme.primary)).abs();

      // Assert — تدرّجٌ من البرتقالي إلى الأحمر بطاقةٌ بلونين، لا بطاقةٌ بلون العلامة.
      expect(gap, lessThan(6));
      expect(
        scheme.primaryDeep.computeLuminance(),
        lessThan(scheme.primary.computeLuminance()),
      );
    });
  });

  // الترويسة الكحلية فوق شاشتي الدخول وإنشاء الحساب: كحليّةٌ في الوضعين، ونصّها مقروء عليها.
  group('the sign-in header', () {
    /// نسبة التباين في WCAG: ١ للونين متطابقين، و٢١ للأسود على الأبيض.
    double contrast(Color a, Color b) {
      final (x, y) = (a.computeLuminance(), b.computeLuminance());

      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    const schemes = [MaterialTheme.lightScheme, MaterialTheme.darkScheme];

    test('it stays navy in daylight and in the dark', () {
      // Arrange
      final headers = [for (final scheme in schemes) scheme.header];

      // Act
      final colours = headers.map(HSLColor.fromColor).toList();

      // Assert — أزرق الصبغة، وداكنٌ جداً في الحالتين.
      for (final colour in colours) {
        expect(colour.hue, inInclusiveRange(200, 230));
        expect(colour.lightness, lessThan(0.2));
      }
    });

    test('in the dark it sits a step below the page, so it still reads as a band', () {
      // Arrange
      const scheme = MaterialTheme.darkScheme;

      // Act
      final header = scheme.header.computeLuminance();
      final page = scheme.surface.computeLuminance();

      // Assert
      expect(header, lessThan(page));
    });

    test('the title and the line under it both read on it', () {
      // Arrange
      final pairs = [
        for (final scheme in schemes) ...[
          (ink: scheme.onHeader, on: scheme.header, floor: 7.0),
          (ink: scheme.onHeaderVariant, on: scheme.header, floor: 4.5),
        ],
      ];

      // Act
      final ratios = [for (final pair in pairs) contrast(pair.ink, pair.on)];

      // Assert
      for (final (index, ratio) in ratios.indexed) {
        expect(ratio, greaterThan(pairs[index].floor));
      }
    });
  });
}
