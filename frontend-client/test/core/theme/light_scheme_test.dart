import 'dart:math' as math;

import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The daylight palette, checked rather than eyeballed.
///
/// **Every hex in [MaterialTheme.lightScheme] is reasoned, not drawn.** The mockup specifies one
/// appearance — the dark one — so the light scheme was derived from it, and a derived palette is
/// exactly the kind that looks fine to the person who wrote it and is unreadable on somebody
/// else's screen in the sun. So the pairs that carry text are measured here against WCAG, and the
/// invariants that make it *the same app* rather than a second brand are asserted.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// WCAG 2.1 relative luminance.
  double luminance(Color colour) {
    double channel(double value) {
      final v = value;

      return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(colour.r) + 0.7152 * channel(colour.g) + 0.0722 * channel(colour.b);
  }

  /// The WCAG contrast ratio between two opaque colours, 1.0 (identical) to 21.0 (black on white).
  double contrast(Color foreground, Color background) {
    final a = luminance(foreground);
    final b = luminance(background);
    final (lighter, darker) = a > b ? (a, b) : (b, a);

    return (lighter + 0.05) / (darker + 0.05);
  }

  group('it is a light scheme at all', () {
    test('the brightness says so, and so does the ThemeData built from it', () {
      // **The regression this file exists for.** `light()` used to return `darkScheme` on
      // purpose, back when there was no light palette — a phone set to light got the dark app
      // and nothing anywhere said otherwise.
      expect(MaterialTheme.lightScheme.brightness, Brightness.light);
      expect(
        const MaterialTheme(TextTheme()).light().brightness,
        Brightness.light,
      );
    });

    test('the page is genuinely lighter than the dark one', () {
      expect(
        luminance(MaterialTheme.lightScheme.surface),
        greaterThan(luminance(MaterialTheme.darkScheme.surface)),
      );
    });
  });

  group('it is the same app', () {
    test('the brand does not change with the time of day', () {
      // An orange that moved between light and dark would be two brands.
      expect(MaterialTheme.lightScheme.primary, MaterialTheme.darkScheme.primary);
      expect(MaterialTheme.lightScheme.onPrimary, MaterialTheme.darkScheme.onPrimary);
    });

    test('a selected chip stays solid, as it is in the dark', () {
      // The design fills a selected chip with the brand and puts white on it; Material's muted
      // container convention is the thing this palette deliberately does not follow.
      expect(
        MaterialTheme.lightScheme.primaryContainer,
        MaterialTheme.lightScheme.primary,
      );
    });

    test('the surface ladder climbs, step by step', () {
      // Dark stacks navy upward from the page; light stacks blue-grey downward from white. Either
      // way a card has to be distinguishable from the page and a border from the card.
      const scheme = MaterialTheme.lightScheme;
      final ladder = [
        scheme.surfaceContainerLowest,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ];

      for (var i = 1; i < ladder.length; i++) {
        expect(
          luminance(ladder[i]),
          lessThan(luminance(ladder[i - 1])),
          reason: 'step $i of the light surface ladder does not darken',
        );
      }
    });
  });

  group('text can be read on what it sits on', () {
    /// WCAG AA for body text. The app draws Arabic at small sizes, where 4.5 is the floor rather
    /// than a target.
    const aa = 4.5;

    /// AA for large or bold text, which is what a filled button's label is.
    const aaLarge = 3.0;

    test('body text on the page', () {
      const scheme = MaterialTheme.lightScheme;

      expect(contrast(scheme.onSurface, scheme.surface), greaterThanOrEqualTo(aa));
    });

    test('secondary text on the page, and on a card', () {
      // `onSurfaceVariant` is the one most likely to be drawn too pale: it is the colour every
      // subtitle, hint and meta line in the app uses.
      const scheme = MaterialTheme.lightScheme;

      expect(contrast(scheme.onSurfaceVariant, scheme.surface), greaterThanOrEqualTo(aa));
      expect(
        contrast(scheme.onSurfaceVariant, scheme.surfaceContainer),
        greaterThanOrEqualTo(aa),
      );
    });

    test('body text on a card and on the raised steps above it', () {
      const scheme = MaterialTheme.lightScheme;

      for (final surface in [
        scheme.surfaceContainerLow,
        scheme.surfaceContainer,
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest,
      ]) {
        expect(contrast(scheme.onSurface, surface), greaterThanOrEqualTo(aa));
      }
    });

    test('a filled button, an error, and the saving notice', () {
      const scheme = MaterialTheme.lightScheme;

      expect(contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(aaLarge));
      expect(contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(aaLarge));
      expect(
        contrast(scheme.onTertiaryContainer, scheme.tertiaryContainer),
        greaterThanOrEqualTo(aa),
      );
      expect(
        contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThanOrEqualTo(aa),
      );
    });

    test('an error message printed on the page', () {
      // `showError` draws `error` on a surface, not on `errorContainer`.
      const scheme = MaterialTheme.lightScheme;

      expect(contrast(scheme.error, scheme.surface), greaterThanOrEqualTo(aa));
    });
  });
}
