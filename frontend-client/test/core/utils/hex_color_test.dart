import 'dart:ui' show Color;

import 'package:dayaa_client/core/utils/hex_color.dart';
import 'package:dayaa_client/features/tools/models/qr_ink.dart';
import 'package:flutter_test/flutter_test.dart';

/// Arrange - Act - Assert throughout.
void main() {
  group('HexColor.normalize', () {
    test('fixes the form: spaces, lower case, a missing #', () {
      expect(HexColor.normalize(' e4002b '), '#E4002B');
      expect(HexColor.normalize('#e4002b'), '#E4002B');
    });

    test('does not guess at short or foreign codes', () {
      expect(HexColor.normalize(''), isNull);
      expect(HexColor.normalize('#E400'), isNull);
      expect(HexColor.normalize('#F00'), isNull);
      expect(HexColor.normalize('#E4002BFF'), isNull);
      expect(HexColor.normalize('#GGGGGG'), isNull);
    });
  });

  test('parse and of round-trip, opaque and upper case', () {
    // Arrange
    const code = '#1E3A8A';

    // Act
    final color = HexColor.parse(code)!;

    // Assert
    expect(color, const Color(0xFF1E3A8A));
    expect(HexColor.of(color), code);
    expect(HexColor.of(const Color(0x801E3A8A)), code);
  });

  group('QrInk.isLowContrast', () {
    test('every quick swatch reads on white', () {
      expect(QrInk.palette.where(QrInk.isLowContrast), isEmpty);
    });

    test('pure red passes; orange and yellow are flagged', () {
      expect(QrInk.isLowContrast(const Color(0xFFFF0000)), isFalse);
      expect(QrInk.isLowContrast(const Color(0xFFFF8800)), isTrue);
      expect(QrInk.isLowContrast(const Color(0xFFFFFF00)), isTrue);
    });
  });
}
