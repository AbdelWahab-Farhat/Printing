import 'package:dayaa_client/core/utils/number_input_formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يقبله حقل الكمية تحت الإصبع.
///
/// **يُختبر المُنسِّق لا الشاشة**: القاعدة هنا حسابٌ على نصّ، وشجرةُ ويدجتات كاملة من أجلها
/// اختبارٌ أبطأ يقول الشيء نفسه بثقةٍ أقل.
void main() {
  /// ما يبقى في الحقل بعد أن يُكتب [next] فوق [previous].
  String typed(TextInputFormatter formatter, {required String previous, required String next}) =>
      formatter
          .formatEditUpdate(
            TextEditingValue(
              text: previous,
              selection: TextSelection.collapsed(offset: previous.length),
            ),
            TextEditingValue(
              text: next,
              selection: TextSelection.collapsed(offset: next.length),
            ),
          )
          .text;

  group('الأرقام العربية', () {
    const formatter = WesternDigitsInputFormatter();

    test('١٢٣ تصير 123', () {
      expect(typed(formatter, previous: '', next: '١٢٣'), '123');
    });

    test('الأرقام الفارسية كذلك', () {
      expect(typed(formatter, previous: '', next: '۱۲۳'), '123');
    });

    test('الفاصلة العشرية العربية تصير نقطة', () {
      expect(typed(formatter, previous: '', next: '١٫٥'), '1.5');
    });

    test('ما كان لاتينياً يُترك كما هو', () {
      expect(typed(formatter, previous: '', next: '1000'), '1000');
    });
  });

  group('شكل الكمية', () {
    const piece = QuantityInputFormatter(wholeOnly: true);
    const kilogram = QuantityInputFormatter(wholeOnly: false);

    test('نقطة ثانية تُردّ، والنصّ يبقى على آخر حالٍ صحيحة', () {
      // هذا هو العطب الذي جاء من أجله: `[0-9.]` كان يبني «1.2.3» نقرةً شرعيةً في كل مرة.
      expect(typed(kilogram, previous: '1.2', next: '1.2.'), '1.2');
    });

    test('نقطةٌ وحدها ليست كمية', () {
      // كانت تمرّ، وتُضاف إلى السلة، ويردّها الخادم ٤٢٢ بعد رحلةٍ لا داعي لها: «.» ليس رقماً
      // عند `is_numeric`. والرفض هنا تحت الإصبع.
      expect(typed(kilogram, previous: '', next: '.'), '');
      expect(typed(piece, previous: '', next: '.'), '');
    });

    test('الكسر يُكتب بصفرٍ قبله', () {
      // «.5» تُردّ مع «.»، و«0.5» هي الطريق — والحقل يفتح على أقل كمية فلا يكون فارغاً أصلاً.
      expect(typed(kilogram, previous: '', next: '.5'), '');
      expect(typed(kilogram, previous: '0', next: '0.5'), '0.5');
    });

    test('نقطةٌ في الآخر تمرّ، لأنها الطريق الوحيد إلى ٧٫٥', () {
      // وهي غير ضارّة حيث «.» ضارّة: الخادم يقرأ «100.» مئةً.
      expect(typed(kilogram, previous: '100', next: '100.'), '100.');
    });

    test('نقطة واحدة تمرّ لمن يُباع بالوزن', () {
      // «سادة» تُطلب بالكيلوغرام، و٧٫٥ كجم كميةٌ يقصدها صاحبها — والخادم يقبلها.
      expect(typed(kilogram, previous: '7', next: '7.'), '7.');
      expect(typed(kilogram, previous: '7.', next: '7.5'), '7.5');
    });

    test('من يُباع بالقطعة لا نقطة فيه أصلاً', () {
      // نصفُ كيسٍ ليس شيئاً — نفس ما يرفضه `RequestOrderRequest`، مقولاً قبل الرحلة.
      expect(typed(piece, previous: '100', next: '100.'), '100');
      expect(typed(piece, previous: '100', next: '100.5'), '100');
    });

    test('الأرقام تمرّ في الحالتين', () {
      expect(typed(piece, previous: '10', next: '100'), '100');
      expect(typed(kilogram, previous: '10', next: '100'), '100');
    });

    test('الحروف لا تمرّ', () {
      expect(typed(kilogram, previous: '10', next: '10a'), '10');
      expect(typed(piece, previous: '10', next: '١٠'), '10');
    });

    test('تفريغ الحقل مسموح', () {
      // من يبدّل كمية يمسح القديمة أولاً؛ مُنسِّقٌ يرفض ذلك يحبسه على رقمٍ لا يريده.
      expect(typed(piece, previous: '100', next: ''), '');
      expect(typed(kilogram, previous: '7.5', next: ''), '');
    });
  });
}
