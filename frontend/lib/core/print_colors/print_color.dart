import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// One ink a design is printed in — «ألوان الطباعة». See PRINT-COLORS.md.
///
/// - [name] is how two people on the floor talk about it: «أحمر الشعار».
/// - [code] is **the authority** — `PANTONE 186 C`, a CMYK mix — and what the press matches.
/// - [hex] is a swatch to tell entries apart at a glance, never the shade to print: phone
///   screens disagree about colour, which is the whole reason this feature exists.
///
/// Written by hand rather than through freezed: three strings, and the four models that carry a
/// list of these (`CustomerDesign`, `OrderDesign`, `DesignTicket`, `DesignTicketFile`) generate
/// their own code against [PrintColor.fromJson] and [toJson] either way.
@immutable
class PrintColor {
  const PrintColor({required this.name, this.code, this.hex});

  factory PrintColor.fromJson(Map<String, dynamic> json) => PrintColor(
    name: json['name'] as String? ?? '',
    code: json['code'] as String?,
    hex: json['hex'] as String?,
  );

  final String name;
  final String? code;

  /// `#RRGGBB`, upper case — the only form the server stores.
  final String? hex;

  /// The swatch, or null when there is none or it cannot be read.
  Color? get swatch => parseHex(hex);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name.trim(),
    // Null rather than empty: the server stores a blank as null, and sending one keeps the
    // round-trip identical.
    'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
    'hex': hex,
  };

  /// `#E4002B` → a [Color], or null for anything that is not six hex digits.
  static Color? parseHex(String? hex) {
    if (hex == null || !_hexPattern.hasMatch(hex)) return null;

    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  /// A [Color] → `#E4002B`, the form the server accepts.
  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// A server list → models. Tolerates null and stray entries rather than failing a whole order
  /// over one of them.
  static List<PrintColor> listFromJson(Object? json) => [
    if (json is List)
      for (final entry in json)
        if (entry is Map<String, dynamic>) PrintColor.fromJson(entry),
  ];

  static List<Map<String, dynamic>> listToJson(List<PrintColor> colors) => [
    for (final color in colors) color.toJson(),
  ];

  /// More than this is a photograph, not a spot-colour job — the server's own limit.
  static const max = 12;

  static final RegExp _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  @override
  bool operator ==(Object other) =>
      other is PrintColor &&
      other.name == name &&
      other.code == code &&
      other.hex == hex;

  @override
  int get hashCode => Object.hash(name, code, hex);

  @override
  String toString() => 'PrintColor($name, $code, $hex)';
}
