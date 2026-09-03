import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// The five keys a وسيط order carries that no other order does, read off the wire.
///
/// `order_resource_contract_test.dart` proves the generated parser *names* each of them; this
/// proves the values land where the screens read them, and that their absence — which is what
/// every printed order and every reader without `products.view_cost` gets — is a null and not
/// a parse failure.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> base() => <String, dynamic>{
    'id': 52,
    'code': '52',
    'status': 'manufacturing',
    'status_label': 'قيد التصنيع',
    'is_final': false,
    'customer_id': 3,
    'city_id': 1,
    'design_source': 'none',
    'city_name': 'طرابلس',
    'fulfilment_type_label': 'توصيل',
    'is_office_pickup': false,
    'design_source_label': 'بدون تصميم',
    'items_total': '2500.00',
    'design_fee': '0.00',
    'delivery_price': '0.00',
    'discount': '0.00',
    'grand_total': '2500.00',
  };

  Map<String, dynamic> item() => <String, dynamic>{
    'id': 11,
    'product_id': 3,
    'product_variant_id': 12,
    'product_name': 'كروت بزنس',
    'variant_label': 'قياسي',
    'pricing_unit_label': 'قطعة',
    'quantity': '50.000',
    'unit_price': '50.000',
    'line_total': '2500.00',
  };

  test('a وسيط order names its vendor and when the job went out', () {
    // Arrange
    final json = base()
      ..['vendor_id'] = 4
      ..['vendor_name'] = 'مطبعة الأمل'
      ..['manufacturing_started_at'] = '2026-09-03T10:15:00+02:00';

    // Act
    final order = Order.fromJson(json);

    // Assert
    expect(order.status, OrderStatus.manufacturing);
    expect(order.vendorId, 4);
    expect(order.vendorName, 'مطبعة الأمل');
    expect(order.manufacturingStartedAt, isNotNull);
  });

  test('an order we make ourselves has none of that, and still parses', () {
    // Arrange - Act
    final order = Order.fromJson(base()..['status'] = 'printing');

    // Assert
    expect(order.vendorId, isNull);
    expect(order.vendorName, isNull);
    expect(order.manufacturingStartedAt, isNull);
  });

  test('a line carries the cost it was taken at, and the cost it came to', () {
    // Arrange
    final json = item()
      ..['unit_cost'] = '25.000'
      ..['outsourcing_cost'] = '1250.00'
      ..['cogs'] = '1250.00';

    // Act
    final line = OrderItem.fromJson(json);

    // Assert
    expect(line.unitCost, '25.000');
    expect(line.outsourcingCost, '1250.00');
  });

  test('a line sent to somebody without the grant has neither, and still parses', () {
    // Arrange — the keys are omitted, not nulled, for anybody without `products.view_cost`.
    // Act
    final line = OrderItem.fromJson(item());

    // Assert
    expect(line.unitCost, isNull);
    expect(line.outsourcingCost, isNull);
  });
}
