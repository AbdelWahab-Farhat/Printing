import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line the shop has not priced yet, arriving at the staff app.
///
/// **A regression test for a screen that went blank.** «قائمة الطلبات» drew «حدث خطأ ما» over
/// the whole list, for every order, because one request in it carried a line with no price:
/// `unit_price` was declared `required String`, the server sent null, and the decode threw
/// before a single row was built. The server was answering 200 the entire time.
///
/// The payload below is **copied from a real response** — `GET /api/v1/orders`, order 1292,
/// a request for «كروت» priced «حسب الطلب». A fixture invented here would have agreed with
/// whatever the model expected, which is exactly how the original bug survived a green suite.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// One line as `OrderItemResource` actually sends it when nobody has quoted it yet.
  Map<String, dynamic> unpricedItem() => <String, dynamic>{
    'id': 130,
    'product_id': 4,
    'product_variant_id': 13,
    'product_name': 'كروت',
    'variant_label': 'كروت عادية',
    'quantity': '100.000',
    'pricing_unit': 'piece',
    'pricing_unit_label': 'قطعة',
    'unit_price': null,
    'line_total': null,
    'billable_quantity': '100.000',
    'shortage_quantity': null,
    'undelivered_quantity': null,
    'warehouse_quantity': null,
    'material_cost': null,
    'labor_cost': null,
    'overhead_cost': null,
    'outsourcing_cost': null,
    'cogs': null,
    'unit_cost': null,
    'sort_order': 0,
    'notes': null,
  };

  /// The order that carried it, trimmed to the fields the model reads.
  Map<String, dynamic> requestedOrder() => <String, dynamic>{
    'id': 1292,
    'code': '1292',
    'status': 'requested',
    'status_label': 'بانتظار المراجعة',
    'is_final': false,
    'is_closed': false,
    'customer_id': 710,
    'city_id': 1,
    'design_source': 'none',
    'design_source_label': 'بدون تصميم',
    'city_name': 'طرابلس',
    'fulfilment_type_label': 'استلام مكتب',
    'is_office_pickup': true,
    'items_total': '0.00',
    'design_fee': '0.00',
    'delivery_price': '0.00',
    'discount': '0.00',
    'grand_total': '0.00',
    'remaining_amount': '0.00',
    'payment_status_label': 'غير مدفوعة',
    'items': [unpricedItem()],
  };

  test('an order carrying an unpriced line decodes at all', () {
    // Arrange — the response that used to take the whole screen down.
    final json = requestedOrder();

    // Act
    final order = Order.fromJson(json);

    // Assert — the failure this guards is not a wrong number on a row, it is **no rows**: the
    // decode threw and «قائمة الطلبات» drew its generic error over every order in the shop.
    expect(order.id, 1292);
    expect(order.status, OrderStatus.requested);
    expect(order.items, hasLength(1));
  });

  test('the line keeps its quantity and reports itself unpriced', () {
    // Arrange
    final json = requestedOrder();

    // Act
    final item = Order.fromJson(json).items!.single;

    // Assert — null all the way through rather than coerced to '0.00'. The card asks
    // [OrderItem.isPriced] and draws «غير مسعّر»; a zero here would have it draw a line the
    // shop is giving away.
    expect(item.unitPrice, isNull);
    expect(item.lineTotal, isNull);
    expect(item.isPriced, isFalse);
    expect(item.quantity, '100.000');
  });

  test('a priced line is untouched by any of this', () {
    // Arrange — the ordinary case, from the same response.
    final json = requestedOrder();
    final line = (json['items']! as List<dynamic>).first as Map<String, dynamic>;

    line['unit_price'] = '1.130';
    line['line_total'] = '113.00';

    // Act
    final item = Order.fromJson(json).items!.single;

    // Assert
    expect(item.isPriced, isTrue);
    expect(item.unitPrice, '1.130');
    expect(item.unitPriceOrZero, '1.130');
  });

  test('the downstream fallback is zero only where a price cannot be missing', () {
    // Arrange
    final json = requestedOrder();

    // Act
    final item = Order.fromJson(json).items!.single;

    // Assert — the invoice editor, the shortages sheet and the partial-delivery sheet read
    // these. All three live far past «جديدة», which an unpriced line cannot reach, so the
    // fallback is unreachable in practice — and zero rather than a throw so that a broken
    // invariant shows up as a visibly wrong figure instead of a dead screen.
    expect(item.unitPriceOrZero, '0');
    expect(item.lineTotalOrZero, '0');
  });
}
