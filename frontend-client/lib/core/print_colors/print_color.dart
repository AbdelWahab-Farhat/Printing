import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// لونٌ واحد من «ألوان الطباعة» على تصميم — PRINT-COLORS.md §8.
///
/// - [name] و[hex] يختارهما العميل: «أحمر الشعار» ونقطةٌ حمراء.
/// - [code] يكتبه فريقنا — `PANTONE 186 C` — وهو ما تطابقه المطبعة. يُعرض هنا ولا يُكتب: لا خانة
///   له في هذا التطبيق، والخادم يُسقطه لو وصل.
///
/// بشكل `PrintColor` في تطبيق الموظفين نفسه، لأن الردّ واحد.
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

  /// `#RRGGBB` بأحرفٍ كبيرة — الصيغة الوحيدة التي يحفظها الخادم.
  final String? hex;

  /// النقطة، أو null حين لا لون أو لا يُقرأ.
  Color? get swatch => parseHex(hex);

  /// ما يُرسل: الاسم واللون فقط. الرمز ليس للعميل أن يكتبه.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name.trim(),
    'hex': hex,
  };

  /// `#E4002B` ← [Color]، أو null لما ليس ستّ خانات.
  static Color? parseHex(String? hex) {
    if (hex == null || !_hexPattern.hasMatch(hex)) return null;

    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  /// [Color] ← `#E4002B`، الصيغة التي يقبلها الخادم.
  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// قائمة الخادم ← نماذج. تتحمّل null والعناصر الشاذّة بدل أن تُسقط القائمة كلّها.
  static List<PrintColor> listFromJson(Object? json) => [
    if (json is List)
      for (final entry in json)
        if (entry is Map<String, dynamic>) PrintColor.fromJson(entry),
  ];

  static List<Map<String, dynamic>> listToJson(List<PrintColor> colors) => [
    for (final color in colors) color.toJson(),
  ];

  /// حدُّ الخادم نفسه.
  static const max = 12;

  /// Whether the press can work from this colour: it has its swatch or our team's code. A name
  /// alone does not count. Mirrors `PrintColors::isComplete()` (PRINT-COLORS.md §9).
  bool get isComplete =>
      swatch != null || (code != null && code!.trim().isNotEmpty);

  /// Whether a design's list is what a print order needs: at least one colour, each complete.
  static bool listIsComplete(List<PrintColor> colors) =>
      colors.isNotEmpty && colors.every((color) => color.isComplete);

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
