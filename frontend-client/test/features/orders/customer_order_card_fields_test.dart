import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// صفّ «طلباتي» يحمل ما ترسمه بطاقته: المال، ومكان الاستلام ورقمه، والبنود.
///
/// **وخادمٌ أقدم لا يرسلها لا يُسقط القائمة.** الحقول اختيارية: التطبيق يصل إلى المتاجر قبل أن
/// ينشر الخادم، والبطاقة ترسم «—» حيث لا جواب.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> row({bool withCardFields = true}) => <String, dynamic>{
    'id': 7,
    'code': '1228',
    'stage': 'producing',
    'stage_label': 'قيد الإنتاج',
    'is_open': true,
    'total': '245.000',
    'is_awaiting_quote': false,
    if (withCardFields) ...{
      'paid_amount': '100.000',
      'balance': '145.00',
      'city_name': 'بنغازي',
      'recipient_phone': '0913333333',
      'fulfilment_type': 'delivery',
      'fulfilment_type_label': 'توصيل',
      'items': [
        {
          'id': 1,
          'product_name': 'أكياس شحن - مطبوعة',
          'variant_label': '30*40',
          'quantity': '500.000',
          'pricing_unit_label': 'قطعة',
          'unit_price': '0.490',
          'line_total': '245.00',
        },
      ],
    },
  };

  test('a row carries the money, the destination and the lines its card draws', () {
    // Arrange
    final json = row();

    // Act
    final order = CustomerOrder.fromJson(json);

    // Assert
    expect(order.paidAmount, '100.000');
    expect(order.balance, '145.00');
    expect(order.cityName, 'بنغازي');
    expect(order.recipientPhone, '0913333333');
    expect(order.fulfilmentTypeLabel, 'توصيل');
    expect(order.items.single.productName, 'أكياس شحن - مطبوعة');
    expect(order.items.single.pricingUnitLabel, 'قطعة');
  });

  test('a row from a server that does not send them yet still decodes, with nothing in them', () {
    // Arrange
    final json = row(withCardFields: false);

    // Act
    final order = CustomerOrder.fromJson(json);

    // Assert
    expect(order.paidAmount, isNull);
    expect(order.balance, isNull);
    expect(order.cityName, isNull);
    expect(order.recipientPhone, isNull);
    expect(order.items, isEmpty);
  });
}
