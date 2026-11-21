import 'dart:math' as math;

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The colours written outside `theme.dart`, with nothing else keeping them honest.
///
/// These tests pin the *intent* rather than the values: the paid family sits in the logo's green
/// band and stays well clear of the `primary` it exists to be distinguishable from, the brand
/// card and the header band keep the logo's purple hue, and everything that carries text can be
/// read.
///
/// **They have earned their keep before.** The palette once moved from the staff app's teal to
/// an orange, and the distance assertion below was written without `.abs()`; it passed only
/// because teal's hue happened to be the larger of the two. Against orange it went negative and
/// failed, which is exactly the kind of quiet wrong these tests exist to catch.
///
/// Arrange - Act - Assert throughout.
void main() {
  double hueOf(Color colour) => HSLColor.fromColor(colour).hue;

  /// The logo's green is 160°. The band holds the paid family to it, and clear of the blue
  /// «قيد المعالجة» pill at 207°.
  const green = (low: 150.0, high: 170.0);

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

  test('the green is far enough from the app\'s accent to read as another colour', () {
    // Arrange: the accent is yellow at night and purple by day, so both are checked.
    const schemes = [MaterialTheme.darkScheme, MaterialTheme.lightScheme];

    // Act: **`.abs()`, because a hue gap has no sign.** Which of the two is the larger number is
    // an accident of where each one lands on the wheel, and the question is how far apart they
    // are.
    final gaps = [for (final s in schemes) (hueOf(s.primary) - hueOf(s.paid)).abs()];

    // Assert: a chip and the price directly beneath it must not look like the same decision.
    for (final gap in gaps) {
      expect(gap, greaterThan(35));
    }
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

  group('the brand card', () {
    /// نسبة التباين كما تعرّفها WCAG: الأفتح على الأغمق، وكلٌّ منهما مزاحٌ بـ ٠٫٠٥.
    double contrast(Color a, Color b) {
      final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
          ? (a.computeLuminance(), b.computeLuminance())
          : (b.computeLuminance(), a.computeLuminance());

      return (lighter + 0.05) / (darker + 0.05);
    }

    test('carries white text at body size on both ends, in both appearances', () {
      // Arrange: the card is in the brand's colours at both times of day, so the pairs are
      // checked twice.
      const schemes = [MaterialTheme.lightScheme, MaterialTheme.darkScheme];

      // Act
      final ratios = [
        for (final s in schemes) ...[
          contrast(s.onBrand, s.brand),
          contrast(s.onBrand, s.brandDeep),
        ],
      ];

      // Assert: 4.5 to 1 is the floor for body-size text, and the phone number sits on the card.
      for (final ratio in ratios) {
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    });

    test('is the logo\'s purple, only deeper at one end', () {
      // Arrange
      const scheme = MaterialTheme.lightScheme;

      // Act
      final gap = (hueOf(scheme.brandDeep) - hueOf(scheme.brand)).abs();

      // Assert: a gradient into another hue is a two-colour card, not the brand's card.
      expect(hueOf(scheme.brand), inInclusiveRange(245, 260));
      expect(gap, lessThan(6));
      expect(
        scheme.brandDeep.computeLuminance(),
        lessThan(scheme.brand.computeLuminance()),
      );
    });

    test('the customer code\'s yellow chip reads on it, and its number reads on the chip', () {
      // Arrange
      const scheme = MaterialTheme.lightScheme;

      // Act - Assert: the chip is the one yellow thing on the card, and the code is bold text.
      expect(contrast(scheme.brandDeep, scheme.brandYellow), greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.brandYellow, scheme.brand), greaterThanOrEqualTo(3));
    });
  });

  // The band above the sign-in and sign-up screens: a deep indigo in both appearances, and its
  // text readable on it.
  group('the sign-in header', () {
    /// نسبة التباين في WCAG: ١ للونين متطابقين، و٢١ للأسود على الأبيض.
    double contrast(Color a, Color b) {
      final (x, y) = (a.computeLuminance(), b.computeLuminance());

      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    const schemes = [MaterialTheme.lightScheme, MaterialTheme.darkScheme];

    test('it stays a deep indigo in daylight and in the dark', () {
      // Arrange
      final headers = [for (final scheme in schemes) scheme.header];

      // Act
      final colours = headers.map(HSLColor.fromColor).toList();

      // Assert: the logo's purple hue, and very dark in both.
      for (final colour in colours) {
        expect(colour.hue, inInclusiveRange(240, 260));
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
