import 'package:dayaa/features/tools/models/qr_code_art.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

/// ما يضمنه الترميز نفسه، بلا شاشة ولا رسم.
///
/// الفحوص هنا **بنيوية لا لقطات**: مصفوفة QR لا تُقرأ بالعين، ومقارنتها بمصفوفةٍ محفوظة تثبت
/// أنها لم تتغيّر ولا تثبت أنها صحيحة. أنماطُ الكشف والتوقيت وعدد الوحدات هي ما تشترطه
/// المواصفة، وهي ما يقرأه الماسح فعلاً.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('QrCodeArt.encode', () {
    test('يرمّز رابطاً بعدد وحدات يوافق إصداراً صحيحاً', () {
      // Arrange
      const url = 'https://daaya.ly';

      // Act
      final art = QrCodeArt.encode(url);

      // Assert — عدد الوحدات في أي رمز هو 4×الإصدار + 17، والإصدار بين ١ و٤٠.
      final version = (art.moduleCount - 17) / 4;
      expect(version, equals(version.roundToDouble()));
      expect(version, inInclusiveRange(1, 40));
      expect(art.data, url);
    });

    test('يرسم أنماط الكشف الثلاثة في زواياها', () {
      // Arrange
      final art = QrCodeArt.encode('https://daaya.ly');
      final last = art.moduleCount - 7;

      // نمط الكشف: مربّع ٧×٧ حافته مطبوعة، يليها حلقة فارغة، ثم قلبٌ ٣×٣ مطبوع.
      void expectFinderAt(int row, int col) {
        expect(art.isDark(row, col), isTrue, reason: 'ركن النمط عند $row/$col');
        expect(art.isDark(row + 1, col + 1), isFalse, reason: 'الحلقة الفارغة عند $row/$col');
        expect(art.isDark(row + 3, col + 3), isTrue, reason: 'قلب النمط عند $row/$col');
      }

      // Act & Assert — أعلى اليسار، أعلى اليمين، أسفل اليسار. ولا رابع: الركن الأخير هو ما
      // يعرف منه الماسح دوران الرمز.
      expectFinderAt(0, 0);
      expectFinderAt(0, last);
      expectFinderAt(last, 0);
      expect(art.isDark(last + 3, last + 3), isFalse);
    });

    test('يرسم خط التوقيت متناوباً بين الأنماط', () {
      // Arrange
      final art = QrCodeArt.encode('https://daaya.ly');

      // Act & Assert — الصف السادس بين النمطين يتناوب مطبوعاً وفارغاً، وهو المسطرة التي يقيس
      // بها الماسح عرض الوحدة.
      for (var col = 8; col < art.moduleCount - 8; col++) {
        expect(art.isDark(6, col), col.isEven, reason: 'خط التوقيت عند العمود $col');
      }
    });

    test('نفس المحتوى يعطي نفس المصفوفة', () {
      // Arrange
      const data = '0910000000';

      // Act
      final first = QrCodeArt.encode(data);
      final second = QrCodeArt.encode(data);

      // Assert — لا عشوائية في اختيار القناع: الموظف الذي يعيد الإنشاء يجب أن يرى الرمز نفسه.
      expect(second.moduleCount, first.moduleCount);
      for (var row = 0; row < first.moduleCount; row++) {
        for (var col = 0; col < first.moduleCount; col++) {
          expect(second.isDark(row, col), first.isDark(row, col));
        }
      }
    });

    test('محتوى أطول يحتاج رمزاً أكبر', () {
      // Arrange
      const short = '0910000000';
      final long = 'https://daaya.ly/?ref=${'x' * 300}';

      // Act
      final smallArt = QrCodeArt.encode(short);
      final largeArt = QrCodeArt.encode(long);

      // Assert
      expect(largeArt.moduleCount, greaterThan(smallArt.moduleCount));
    });

    test('يرمي حين لا يسع المحتوى أكبر رمز', () {
      // Arrange — أكبر رمز بتصحيح `H` يسع نحو ١٢٧٣ بايتاً؛ هذا ضعفها.
      final tooLong = 'x' * 3000;

      // Act & Assert
      expect(() => QrCodeArt.encode(tooLong), throwsA(isA<InputTooLongException>()));
    });

    test('نصٌّ عربي يُرمَّز كما هو', () {
      // Arrange — العربية بايتان للحرف في UTF-8، وهو المسار الذي يكسر المرمِّزات الساذجة.
      const arabic = 'دعاية لخدمات الطباعة';

      // Act
      final art = QrCodeArt.encode(arabic);

      // Assert
      expect(art.data, arabic);
      expect(art.moduleCount, greaterThan(0));
    });
  });

  group('هامش الهدوء', () {
    test('يضيف أربع وحدات على كل جانب', () {
      // Arrange
      final art = QrCodeArt.encode('https://daaya.ly');

      // Act
      final canvas = art.canvasModules;

      // Assert — الهامش هو ما يجعل الرمز مقروءاً بعد أن يُقصّ ويوضع على تصميم ملوّن.
      expect(QrCodeArt.quietZone, 4);
      expect(canvas, art.moduleCount + 8);
    });
  });

  group('مستوى تصحيح الخطأ', () {
    test('هو الأعلى، كما في أداة الموقع', () {
      // Assert — `QRCode.CorrectLevel.H` في qr.html.
      expect(QrCodeArt.errorCorrectLevel, QrErrorCorrectLevel.H);
    });
  });
}
