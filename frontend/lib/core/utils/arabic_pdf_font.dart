/// خطّ عربي للـ PDF لا ينقصه شكلُ حرفٍ منفرد.
///
/// **مكتبة `pdf` تشكّل النص بنفسها، ولا تترك ذلك للخط.** كل حرف يُكتب برمز شكله من كتلة
/// **Arabic Presentation Forms**: الياء في آخر «الهادي» — بعد دال لا تتصل بما بعدها — تصير
/// `U+FEF1` (الياء المنفردة)، لا `U+064A`. والخطوط الحديثة مثل Almarai فيها أشكال الأول والوسط
/// والآخر، أما المنفرد فهو الحرف نفسه فلا رمز له.
///
/// **المكتبة تعرف هذا وتسدّه بجدول — إلا الياء.** جدولها يربط كل حرف أساسي بشكله المنفرد، لكنه
/// يضع الياء على `U+FEEF` (الألف المقصورة المنفردة) بدل `U+FEF1`، ولا يعرف ڤ ولا گ ولا پ ولا
/// غيرها من الحروف الممدودة. الرمز الناقص يصير «.notdef»، والثاني منها في الصفحة نفسها يُسقط
/// الملف كله: «تعذّر إنشاء ملف الفاتورة — Missing glyph for character 'ﻱ' (U+FEF1)». واسم
/// كـ«العبيدي» أو «الزاوي» أو «البدري» يكفي لذلك.
///
/// **لماذا لا يُعالج النص قبل الرسم** كما يفعل [String.deshaped]: لأن الرمز لا يأتي من النص،
/// بل من التشكيل داخل المكتبة بعد أن يصلها. فالعلاج في الخط: كل شكل منفرد ينقصه يُشار به إلى
/// رسم حرفه — وهو هو، فالحرف المنفرد لا يتصل بشيء.
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ArabicPdfFont extends pw.TtfFont {
  ArabicPdfFont(super.data);

  /// الخط كما تبنيه المكتبة، وقد مُلئت فيه الأشكال المنفردة الناقصة.
  ///
  /// تُستدعى مرة لكل مستند، وجدول الرموز يُقرأ منه لقياس العرض ثم لاقتطاع الخط المضمَّن —
  /// فما يُملأ هنا يسري على الاثنين.
  @override
  PdfFont buildFont(PdfDocument pdfDocument) {
    final font = super.buildFont(pdfDocument);

    if (font is PdfTtfFont) {
      final glyphs = font.font.charToGlyphIndexMap;

      // شكلٌ له رسم في الخط نفسه يبقى كما هو.
      _isolatedForms.forEach((letter, isolated) {
        final glyph = glyphs[letter];
        if (glyph != null) glyphs.putIfAbsent(isolated, () => glyph);
      });

      // جدول المكتبة يضع رسم الياء على الألف المقصورة المنفردة. خطٌّ له رسمها — كـAlmarai —
      // يكتبه فوقه عند القراءة؛ وخطٌّ ليس له تصير فيه «هدى» «هدي» لولا هذا السطر.
      final alefMaksura = glyphs[0x0649];
      if (alefMaksura != null && glyphs[0xFEEF] == glyphs[0x064A]) glyphs[0xFEEF] = alefMaksura;
    }

    return font;
  }
}

/// كل حرف يشكّله الـ `bidi` وشكله المنفرد — جدول المكتبة نفسها (`shaping_resolver.dart`) مقصوراً
/// على المنفرد.
const Map<int, int> _isolatedForms = {
  0x0621: 0xFE80, // ء
  0x0622: 0xFE81, // آ
  0x0623: 0xFE83, // أ
  0x0624: 0xFE85, // ؤ
  0x0625: 0xFE87, // إ
  0x0626: 0xFE89, // ئ
  0x0627: 0xFE8D, // ا
  0x0628: 0xFE8F, // ب
  0x0629: 0xFE93, // ة
  0x062A: 0xFE95, // ت
  0x062B: 0xFE99, // ث
  0x062C: 0xFE9D, // ج
  0x062D: 0xFEA1, // ح
  0x062E: 0xFEA5, // خ
  0x062F: 0xFEA9, // د
  0x0630: 0xFEAB, // ذ
  0x0631: 0xFEAD, // ر
  0x0632: 0xFEAF, // ز
  0x0633: 0xFEB1, // س
  0x0634: 0xFEB5, // ش
  0x0635: 0xFEB9, // ص
  0x0636: 0xFEBD, // ض
  0x0637: 0xFEC1, // ط
  0x0638: 0xFEC5, // ظ
  0x0639: 0xFEC9, // ع
  0x063A: 0xFECD, // غ
  0x0641: 0xFED1, // ف
  0x0642: 0xFED5, // ق
  0x0643: 0xFED9, // ك
  0x0644: 0xFEDD, // ل
  0x0645: 0xFEE1, // م
  0x0646: 0xFEE5, // ن
  0x0647: 0xFEE9, // ه
  0x0648: 0xFEED, // و
  0x0649: 0xFEEF, // ى
  0x064A: 0xFEF1, // ي — التي أسقطت الفاتورة
  0x0671: 0xFB50, // ٱ
  0x0677: 0xFBDD, // ٷ
  0x0679: 0xFB66, // ٹ
  0x067A: 0xFB5E, // ٺ
  0x067B: 0xFB52, // ٻ
  0x067E: 0xFB56, // پ
  0x067F: 0xFB62, // ٿ
  0x0680: 0xFB5A, // ڀ
  0x0683: 0xFB76, // ڃ
  0x0684: 0xFB72, // ڄ
  0x0686: 0xFB7A, // چ
  0x0687: 0xFB7E, // ڇ
  0x0688: 0xFB88, // ڈ
  0x068C: 0xFB84, // ڌ
  0x068D: 0xFB82, // ڍ
  0x068E: 0xFB86, // ڎ
  0x0691: 0xFB8C, // ڑ
  0x0698: 0xFB8A, // ژ
  0x06A4: 0xFB6A, // ڤ
  0x06A6: 0xFB6E, // ڦ
  0x06A9: 0xFB8E, // ک
  0x06AD: 0xFBD3, // ڭ
  0x06AF: 0xFB92, // گ
  0x06B1: 0xFB9A, // ڱ
  0x06B3: 0xFB96, // ڳ
  0x06BA: 0xFB9E, // ں
  0x06BB: 0xFBA0, // ڻ
  0x06BE: 0xFBAA, // ھ
  0x06C0: 0xFBA4, // ۀ
  0x06C1: 0xFBA6, // ہ
  0x06C5: 0xFBE0, // ۅ
  0x06C6: 0xFBD9, // ۆ
  0x06C7: 0xFBD7, // ۇ
  0x06C8: 0xFBDB, // ۈ
  0x06C9: 0xFBE2, // ۉ
  0x06CB: 0xFBDE, // ۋ
  0x06CC: 0xFBFC, // ی
  0x06D0: 0xFBE4, // ې
  0x06D2: 0xFBAE, // ے
  0x06D3: 0xFBB0, // ۓ
};
