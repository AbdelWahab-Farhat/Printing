import 'dart:ui';

import 'package:dayaa/core/utils/text_direction.dart';
import 'package:flutter_test/flutter_test.dart';

/// أيُّ اتجاهٍ تجري فيه جملةٌ واحدة، تقرّره الجملة لا التطبيق.
///
/// التطبيق عربيٌّ وكلّ ما فيه يجري من اليمين إلى اليسار — لكن صندوق الرسائل هو المكان الوحيد
/// الذي يكتب فيه الشخص ما يشاء، و«ok» أو اسمُ ملفٍ أو وصفٌ إنجليزيّ مكتوبٌ في صندوقٍ من اليمين
/// إلى اليسار يخرج وعلاماتُه في الطرف الخطأ. والقاعدة قاعدةُ يونيكود نفسها — أوّل حرفٍ ذي اتجاه —
/// وهي ما يستعمله كلّ تطبيق محادثة في هذه الهواتف.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  group('أوّل حرفٍ ذي اتجاه يقرّر', () {
    test('العربية تجري من اليمين إلى اليسار', () {
      // Arrange
      const text = 'وصلني، أبدأ اليوم';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.rtl);
    });

    test('اللاتينية تجري من اليسار إلى اليمين', () {
      // Arrange
      const text = 'ok, sending the PDF now';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.ltr);
    });

    test('الأرقام وعلامات الترقيم قبل أول حرفٍ تُتخطّى', () {
      // Arrange — «٥٪ خصم» و«5% discount» شكلٌ واحد، والأرقام لا تقول شيئاً عن اتجاه أيٍّ
      // منهما.
      const arabic = '٥٪ خصم';
      const latin = '5% discount';

      // Act & Assert
      expect(arabic.readingDirection, TextDirection.rtl);
      expect(latin.readingDirection, TextDirection.ltr);
    });

    test('كلمةٌ لاتينية قبل العربية تظلّ هي القائدة', () {
      // Arrange — أوّلُ حرفٍ ذي اتجاه لا الأغلبية: وهذا ما يضع «QR» في أول السطر حيث كتبها
      // صاحبها.
      const text = 'QR لازم يكون واضح';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, TextDirection.ltr);
    });
  });

  group('حين لا شيء فيه حرفاً', () {
    test('النصّ الفارغ لا يقرّر شيئاً', () {
      // Arrange - Act - Assert — `null`، فيبقى حاملُه على اتجاه التطبيق بدل أن يُدفع إلى
      // الإنجليزية.
      expect(''.readingDirection, isNull);
    });

    test('الأرقام وحدها لا تقرّر شيئاً', () {
      // Arrange
      const text = '0911234567';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, isNull);
    });

    test('الوجه الضاحك لا يقرّر شيئاً', () {
      // Arrange
      const text = '👍';

      // Act
      final direction = text.readingDirection;

      // Assert
      expect(direction, isNull);
    });
  });

  test('العربية المشكَّلة مسبقاً تجري كالحروف التي خلفها', () {
    // Arrange — كتلة أشكال العرض، وهي ما يصل منسوخاً من ملف PDF. انظر `ArabicPresentationForms`:
    // النصّ نفسه، مكتوباً بطريقةٍ ثانية.
    const text = 'ﺷﺮﻛﺔ';

    // Act
    final direction = text.readingDirection;

    // Assert
    expect(direction, TextDirection.rtl);
  });
}
