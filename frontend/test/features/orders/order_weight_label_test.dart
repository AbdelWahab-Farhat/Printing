import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// «كم تزن الطلبية؟» — the one line the order screen prints under its lines.
///
/// The figure is summed by the server out of what the warehouse weighed per line; the order has
/// carried no weight of its own since `weight_kg` was dropped. What is tested here is the whole
/// of the app's share in it: the padding zeros go, the unit is named, and null stays null —
/// «لا يوجد وزن» is not «صفر», and an order nobody has weighed must print no line at all rather
/// than a confident zero.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order orderWith({String? totalWeight}) => Order(
    id: 7,
    code: '1220',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
    totalWeight: totalWeight,
  );

  test('an order with no weight to state has no line to draw', () {
    // Arrange
    final order = orderWith();

    // Act - Assert — null covers «nothing here is weighed» and «nothing has been weighed yet»,
    // and neither of them is «٠».
    expect(order.weightLabel, isNull);
  });

  test('the weight is named in the unit it was measured in', () {
    // Arrange
    final order = orderWith(totalWeight: '12.500');

    // Act - Assert — the column's padding zeros are not a precision anybody weighed to.
    expect(order.weightLabel, '12.5 كيلوغرام');
  });

  test('a whole number of kilograms loses its decimal point', () {
    // Arrange
    final order = orderWith(totalWeight: '17.000');

    // Act - Assert
    expect(order.weightLabel, '17 كيلوغرام');
  });

  test('a heavy order keeps its thousands separator', () {
    // Arrange
    final order = orderWith(totalWeight: '1250.750');

    // Act - Assert — read as a number rather than as a shape, like every other figure the app
    // draws.
    expect(order.weightLabel, '1,250.75 كيلوغرام');
  });
}
