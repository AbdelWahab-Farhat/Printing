import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/core/theme/app_tones.dart';
import 'package:printing/core/theme/theme.dart';

/// «مدفوعة بالكامل» — الأخضر، وكم يبعد عن تيركواز التطبيق.
///
/// The one colour in this app written as a hex, so it is the one colour with nothing generated
/// keeping it honest. These tests pin the *intent* rather than the six values: the family sits in
/// the green band, stays well clear of the teal `primary` it exists to be distinguishable from,
/// and each container still carries text anybody can read. A future re-export of the palette
/// cannot quietly drag this back towards the teal without one of them failing.
///
/// Arrange - Act - Assert throughout.
void main() {
  double hueOf(Color colour) => HSLColor.fromColor(colour).hue;

  /// 120° is pure green; 180° is the cyan `primary` sits on. The paid family belongs nearer the
  /// first — it used to sit around 148°, near enough the teal that «مدفوعة بالكامل» beside «سعر
  /// الطلبية» read as one colour printed twice.
  const green = (low: 130.0, high: 145.0);

  test('the paid tones sit in the green band, in light', () {
    // Arrange
    final scheme = MaterialTheme.lightScheme();

    // Act
    final hues = [hueOf(scheme.paid), hueOf(scheme.paidContainer), hueOf(scheme.onPaidContainer)];

    // Assert
    for (final hue in hues) {
      expect(hue, inInclusiveRange(green.low, green.high));
    }
  });

  test('the paid tones sit in the green band, in dark', () {
    // Arrange
    final scheme = MaterialTheme.darkScheme();

    // Act
    final hues = [hueOf(scheme.paid), hueOf(scheme.paidContainer), hueOf(scheme.onPaidContainer)];

    // Assert
    for (final hue in hues) {
      expect(hue, inInclusiveRange(green.low, green.high));
    }
  });

  test('the green is far enough from the app\'s teal to read as another colour', () {
    // Arrange
    final scheme = MaterialTheme.lightScheme();

    // Act
    final gap = hueOf(scheme.primary) - hueOf(scheme.paid);

    // Assert — a chip and the price directly beneath it must not look like the same decision.
    expect(gap, greaterThan(35));
  });

  test('the pale fill still carries its text', () {
    // Arrange
    final schemes = [MaterialTheme.lightScheme(), MaterialTheme.darkScheme()];

    // Act - Assert — leaning greener must not cost the pair its contrast.
    for (final scheme in schemes) {
      final gap =
          (scheme.paidContainer.computeLuminance() - scheme.onPaidContainer.computeLuminance())
              .abs();

      expect(gap, greaterThan(0.4));
    }
  });

  /// Amber, and deliberately at the orange end of it: a shelf running low is neither fine nor
  /// broken, and pure yellow has no dark step that stays yellow for the light theme to use.
  const amber = (low: 30.0, high: 50.0);

  test('the low-stock tones sit in the amber band, in light', () {
    // Arrange
    final scheme = MaterialTheme.lightScheme();

    // Act
    final hues = [hueOf(scheme.warn), hueOf(scheme.warnContainer), hueOf(scheme.onWarnContainer)];

    // Assert
    for (final hue in hues) {
      expect(hue, inInclusiveRange(amber.low, amber.high));
    }
  });

  test('the low-stock tones sit in the amber band, in dark', () {
    // Arrange
    final scheme = MaterialTheme.darkScheme();

    // Act
    final hues = [hueOf(scheme.warn), hueOf(scheme.warnContainer), hueOf(scheme.onWarnContainer)];

    // Assert
    for (final hue in hues) {
      expect(hue, inInclusiveRange(amber.low, amber.high));
    }
  });

  test('«تحت الحد» is far enough from «نافد» to be a different state, not a paler one', () {
    // Arrange — the two sit side by side in one bar, and one of them has to stop somebody
    final schemes = [MaterialTheme.lightScheme(), MaterialTheme.darkScheme()];

    // Act - Assert
    for (final scheme in schemes) {
      final gap = (hueOf(scheme.warn) - hueOf(scheme.error)).abs();

      expect(gap, greaterThan(20));
    }
  });

  test('«تحت الحد» is nowhere near the teal «سليم» is drawn in', () {
    // Arrange
    final scheme = MaterialTheme.lightScheme();

    // Act
    final gap = (hueOf(scheme.primary) - hueOf(scheme.warn)).abs();

    // Assert
    expect(gap, greaterThan(60));
  });

  test('the amber fill still carries its text', () {
    // Arrange
    final schemes = [MaterialTheme.lightScheme(), MaterialTheme.darkScheme()];

    // Act - Assert
    for (final scheme in schemes) {
      final gap =
          (scheme.warnContainer.computeLuminance() - scheme.onWarnContainer.computeLuminance())
              .abs();

      expect(gap, greaterThan(0.4));
    }
  });
}
