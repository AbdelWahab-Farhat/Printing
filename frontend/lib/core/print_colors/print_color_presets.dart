import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// One of the basic inks offered as a single tap above the manual picker.
///
/// [hex] is what is stored. [gradient] is drawn on the chip only, for an ink no flat swatch can
/// show (gold is metallic); it never reaches the server.
@immutable
class PrintColorPreset {
  const PrintColorPreset({required this.name, required this.hex, this.gradient});

  final String name;
  final String hex;
  final List<Color>? gradient;

  Color get color => Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// The basic inks the owner asked for on 2026-11-11, in the order they are shown.
/// See PRINT-COLORS.md §9.
const List<PrintColorPreset> printColorPresets = [
  PrintColorPreset(name: 'أبيض', hex: '#FFFFFF'),
  PrintColorPreset(name: 'أسود', hex: '#000000'),
  PrintColorPreset(name: 'أزرق', hex: '#0057B8'),
  PrintColorPreset(name: 'أخضر', hex: '#009A44'),
  PrintColorPreset(name: 'أصفر', hex: '#FFD100'),
  PrintColorPreset(name: 'أحمر', hex: '#E4002B'),
  PrintColorPreset(
    name: 'ذهبي',
    hex: '#C9A227',
    gradient: [Color(0xFF8C6A12), Color(0xFFF3D57A), Color(0xFFC9A227), Color(0xFF8C6A12)],
  ),
];

/// The preset whose ink this is, or null.
PrintColorPreset? presetForHex(String? hex) {
  if (hex == null) return null;
  final upper = hex.toUpperCase();
  for (final preset in printColorPresets) {
    if (preset.hex == upper) return preset;
  }

  return null;
}

/// Whether [name] is one of the preset names, so picking another preset may replace it.
bool isPresetName(String name) =>
    printColorPresets.any((preset) => preset.name == name.trim());
