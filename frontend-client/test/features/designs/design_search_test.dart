import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:flutter_test/flutter_test.dart';

/// البحث في «تصاميمي» بالاسم: ما يطابق وما لا يطابق.
///
/// **تُطوى الحروف قبل المقارنة.** «اعلان» و«إعلان» كلمةٌ واحدة عند من يكتب، ولوحة المفاتيح لا
/// تضع الهمزة إلا لمن يطلبها — فبحثٌ يفرّق بينهما يُخفي تصميماً موجوداً عن صاحبه.
///
/// Arrange - Act - Assert throughout.
void main() {
  CustomerDesign named(String label) => CustomerDesign(id: 1, label: label);

  test('البحث الفارغ يُبقي كل تصميم', () {
    // Arrange
    final design = named('شعار المتجر');

    // Act
    final results = [design.matches(''), design.matches('   ')];

    // Assert
    expect(results, [isTrue, isTrue]);
  });

  test('جزءٌ من الاسم يكفي', () {
    // Arrange
    final design = named('شعار المتجر');

    // Act
    final matches = design.matches('متجر');

    // Assert
    expect(matches, isTrue);
  });

  test('ما ليس في الاسم لا يطابق', () {
    // Arrange
    final design = named('شعار المتجر');

    // Act
    final matches = design.matches('كيس');

    // Assert
    expect(matches, isFalse);
  });

  test('الهمزة لا تفرّق: «اعلان» تجد «إعلان»، و«اخر» تجد «آخر»، و«اسود» تجد «أسود»', () {
    // Arrange
    final designs = [named('إعلان الافتتاح'), named('آخر نسخة'), named('الشعار أسود')];

    // Act
    final results = [
      designs[0].matches('اعلان'),
      designs[1].matches('اخر'),
      designs[2].matches('اسود'),
    ];

    // Assert
    expect(results, [isTrue, isTrue, isTrue]);
  });

  test('التاء المربوطة والهاء سواء، في الاتجاهين', () {
    // Arrange
    final written = named('علبة حلويات');
    final typedWithHa = named('علبه حلويات');

    // Act
    final results = [written.matches('علبه'), typedWithHa.matches('علبة')];

    // Assert
    expect(results, [isTrue, isTrue]);
  });

  test('الألف المقصورة والياء سواء', () {
    // Arrange
    final design = named('مستشفى الأمل');

    // Act
    final matches = design.matches('مستشفي');

    // Assert
    expect(matches, isTrue);
  });

  test('التشكيل والتطويل لا يمنعان المطابقة', () {
    // Arrange
    final designs = [named('شِعَار المحلّ'), named('شعـــار')];

    // Act
    final results = [designs[0].matches('شعار المحل'), designs[1].matches('شعار')];

    // Assert
    expect(results, [isTrue, isTrue]);
  });

  test('الحروف اللاتينية بلا تمييزٍ لحالتها، والفراغ حول البحث لا يُحسب', () {
    // Arrange
    final design = named('Logo Final');

    // Act
    final matches = design.matches('  logo ');

    // Assert
    expect(matches, isTrue);
  });
}
