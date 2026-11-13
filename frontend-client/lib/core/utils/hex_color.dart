import 'dart:ui' show Color;

/// `#RRGGBB` codes and the colours they name, in one place.
///
/// Print colours store them and the QR ink accepts them typed, and the two must agree on what
/// a code is: six hex digits, opaque, upper case on the way out. No alpha and no three-digit
/// shorthand (`#F00`) — one form to learn, the same one the server stores.
abstract final class HexColor {
  static final RegExp _pattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// `#E4002B` → a [Color], or null for anything that is not `#` and six hex digits.
  static Color? parse(String? hex) {
    if (hex == null || !_pattern.hasMatch(hex)) return null;

    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  /// A [Color] → `#E4002B`. Alpha is dropped.
  static String of(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// What somebody typed or pasted → `#E4002B`, or null when it is not a full code yet.
  ///
  /// Forgiving about the form, strict about the digits: surrounding spaces, lower case and a
  /// missing `#` are fixed; five digits are not guessed at.
  static String? normalize(String text) {
    var value = text.trim().toUpperCase();
    if (value.isEmpty) return null;
    if (!value.startsWith('#')) value = '#$value';

    return parse(value) == null ? null : value;
  }
}
