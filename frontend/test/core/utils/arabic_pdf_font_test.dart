import 'dart:typed_data';

import 'package:dayaa/core/utils/arabic_pdf_font.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// الحرف المنفرد في ملف PDF.
///
/// مكتبة `pdf` تشكّل النص بنفسها: «ي» في آخر «الهادي» — بعد دال لا تتصل بما بعدها — تصير
/// `U+FEF1`، شكلَ الياء المنفردة. Almarai ليس فيه هذا الرمز، والمكتبة تسدّ النقص لبقية الحروف
/// إلا الياء (جدولها يضعها على `U+FEEF`، الألف المقصورة). حرفان ناقصان في صفحة واحدة كانا
/// يُسقطان الفاتورة كلها برسالة «Missing glyph for character 'ﻱ'».
///
/// Arrange - Act - Assert.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ByteData regular;
  late ByteData bold;

  setUpAll(() async {
    regular = await rootBundle.load('assets/fonts/Almarai-Regular.ttf');
    bold = await rootBundle.load('assets/fonts/Almarai-Bold.ttf');
  });

  Map<int, int> glyphsOf(ByteData data) {
    final font = ArabicPdfFont(data).getFont(pw.Context(document: PdfDocument())) as PdfTtfFont;

    return font.font.charToGlyphIndexMap;
  }

  test('الياء المنفردة تُرسم بشكل الياء نفسه', () {
    // Arrange
    final data = regular;

    // Act
    final glyphs = glyphsOf(data);

    // Assert
    expect(glyphs[0xFEF1], isNotNull);
    expect(glyphs[0xFEF1], glyphs[0x064A]);
  });

  test('كل حرف منفرد ينقص Almarai يجد شكله، في الوزنين', () {
    // Arrange — ي، ثم ڤ وگ وپ وچ وژ وک: كلها حروف في الخط بلا رمز لشكلها المنفرد.
    const letters = {
      0x064A: 0xFEF1, // ي
      0x06A4: 0xFB6A, // ڤ
      0x06AF: 0xFB92, // گ
      0x067E: 0xFB56, // پ
      0x0686: 0xFB7A, // چ
      0x0698: 0xFB8A, // ژ
      0x06A9: 0xFB8E, // ک
    };

    // Act
    final weights = [glyphsOf(regular), glyphsOf(bold)];

    // Assert
    for (final glyphs in weights) {
      letters.forEach((letter, isolated) {
        expect(glyphs[isolated], glyphs[letter], reason: 'U+${isolated.toRadixString(16)}');
      });
    }
  });

  test('الألف المقصورة المنفردة تبقى ألفاً مقصورة، لا ياءً', () {
    // Arrange — «هدى»: جدول المكتبة يضع شكل الياء على رمز الألف المقصورة المنفردة.
    final data = regular;

    // Act
    final glyphs = glyphsOf(data);

    // Assert
    expect(glyphs[0xFEEF], isNot(glyphs[0x064A]));
  });

  test('صفحة فيها «الهادي» و«ڤ» تخرج ملفاً بدل أن ترمي', () async {
    // Arrange — شكلان منفردان ناقصان في صفحة واحدة: هذا ما أسقط الفاتورة على الهاتف.
    final document = pw.Document()
      ..addPage(
        pw.Page(
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: ArabicPdfFont(regular)),
          build: (context) => pw.Text('الهادي ڤ'),
        ),
      );

    // Act
    final bytes = await document.save();

    // Assert
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });
}
