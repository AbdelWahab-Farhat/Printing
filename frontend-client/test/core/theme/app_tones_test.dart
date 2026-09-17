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
}
