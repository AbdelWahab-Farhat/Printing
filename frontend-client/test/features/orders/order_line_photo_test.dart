import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// صورة المنتج على بند الطلبية المفتوحة.
///
/// الخادم يرسلها مع الطلبية المفتوحة وحدها، و«طلباتي» لا يصلها المفتاح أصلاً — فغيابه ليس خطأً
/// يُسقط البند، بل بندٌ يُرسم بشكل الكيس مكان الصورة.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> line() => <String, dynamic>{
    'id': 158,
    'product_name': 'أكياس يد خارجية - مطبوعه',
    'variant_label': '30*30',
    'quantity': '100.000',
    'pricing_unit_label': 'قطعة',
    'unit_price': '1.720',
    'line_total': '172.00',
  };

  test('a line carries the photo of its product', () {
    // Arrange
    final json = line()..['product_image_url'] = 'https://api.daaya.ly/storage/products/2/a.png';

    // Act
    final decoded = OrderLine.fromJson(json);

    // Assert
    expect(decoded.productImageUrl, 'https://api.daaya.ly/storage/products/2/a.png');
  });

  test('a line from a list row, with no photo key at all, still decodes', () {
    // Arrange
    final json = line();

    // Act
    final decoded = OrderLine.fromJson(json);

    // Assert
    expect(decoded.productImageUrl, isNull);
  });
}
