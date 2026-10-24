import 'package:dayaa/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// نسخة الويب: من فتح رابطاً قبل أن يدخل يعود إليه بعد الدخول — وإلى رابطٍ داخليٍّ وحده.
///
/// Arrange - Act - Assert في كل اختبار.
void main() {
  group('returningTo', () {
    test('يحمل الرابط المطلوب مع البوابة', () {
      // Arrange
      final target = Uri.parse('/orders/52?tab=payments');

      // Act
      final gate = Routes.returningTo(Routes.login, target);

      // Assert
      expect(Uri.parse(gate).path, Routes.login);
      expect(Routes.returnTarget(Uri.parse(gate)), '/orders/52?tab=payments');
    });

    test('الرئيسية لا تُحمل: البوابة نفسها تنتهي إليها', () {
      // Arrange
      final target = Uri.parse(Routes.home);

      // Act
      final gate = Routes.returningTo(Routes.splash, target);

      // Assert
      expect(gate, Routes.splash);
    });
  });

  group('returnTarget', () {
    test('بلا from لا شيء يُفتح بعد البوابة', () {
      // Arrange
      final location = Uri.parse(Routes.login);

      // Act
      final target = Routes.returnTarget(location);

      // Assert
      expect(target, isNull);
    });

    test('رابطٌ إلى خارج التطبيق يُرمى — لا يُرسل الموظف بعد دخوله حيث يشاء كاتبه', () {
      // Arrange
      final outside = [
        Routes.returningTo(Routes.login, Uri.parse('https://evil.example/login')),
        '/login?from=${Uri.encodeComponent('//evil.example')}',
        '/login?from=orders',
      ];

      // Act
      final targets = outside.map((gate) => Routes.returnTarget(Uri.parse(gate)));

      // Assert
      expect(targets, everyElement(isNull));
    });

    test('ولا يُعاد إلى البوابتين نفسيهما، فلا يدور الرابط على نفسه', () {
      // Arrange
      final loops = [
        '/login?from=${Uri.encodeComponent('/login')}',
        '/splash?from=${Uri.encodeComponent('/splash?from=/orders')}',
      ];

      // Act
      final targets = loops.map((gate) => Routes.returnTarget(Uri.parse(gate)));

      // Assert
      expect(targets, everyElement(isNull));
    });
  });
}
