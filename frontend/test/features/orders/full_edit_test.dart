import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/full_edit_section.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter_test/flutter_test.dart';

/// «حقول الأدمن»: what `orders.edit_fully` sends, and when the save asks first.
///
/// Arrange - Act - Assert throughout.
void main() {
  Order order({
    String deliveryPrice = '20.00',
    String? deliveryCostOverride,
    DateTime? placedAt,
  }) => Order.fromJson(<String, dynamic>{
    'id': 1,
    'code': 'A1',
    'customer_id': 1,
    'city_id': 1,
    'city_name': 'طرابلس',
    'status': 'new',
    'status_label': 'جديدة',
    'is_final': false,
    'fulfilment_type_label': 'توصيل',
    'is_office_pickup': false,
    'design_source_label': 'بدون تصميم',
    'design_source': 'none',
    'items_total': '100.00',
    'design_fee': '0.00',
    'delivery_price': deliveryPrice,
    'delivery_cost_override': deliveryCostOverride,
    'discount': '0.00',
    'grand_total': '100.00',
    'placed_at': (placedAt ?? DateTime(2026, 11, 20, 10)).toIso8601String(),
  });

  group('OrderFullEdit', () {
    test('Arabic digits are sent as Western ones, and a blank cost means automatic', () {
      // Arrange
      final edit = OrderFullEdit(
        deliveryPrice: '٣٥',
        deliveryCost: '  ',
        shippingCompanyId: 4,
        courierName: ' سالم ',
        courierPhone: '',
        depositExpectedAmount: '١٠٠٫٥',
        placedAt: DateTime(2026, 11, 1, 9),
      );

      // Act
      final json = edit.toJson();

      // Assert
      expect(json['delivery_price'], '35');
      expect(json.containsKey('delivery_cost'), isTrue);
      expect(json['delivery_cost'], isNull);
      expect(json['courier_name'], 'سالم');
      expect(json['courier_phone'], isNull);
      expect(json['deposit_expected_amount'], '100.5');
      expect(json['shipping_company_id'], 4);
    });
  });

  group('FullEditDraft', () {
    test('opens clean and on the order own figures', () {
      // Arrange
      final draft = FullEditDraft(order(deliveryCostOverride: '12.00'));
      addTearDown(draft.dispose);

      // Act + Assert
      expect(draft.isDirty, isFalse);
      expect(draft.deliveryPrice.text, '20.00');
      expect(draft.deliveryCost.text, '12.00');
      expect(draft.deliveryPriceMoved, isFalse);
      expect(draft.dateMoved, isFalse);
    });

    test('a typed price and a new day are both noticed', () {
      // Arrange
      final draft = FullEditDraft(order());
      addTearDown(draft.dispose);

      // Act
      draft.deliveryPrice.text = '٢٥';
      draft.pickDate(DateTime(2026, 11, 2));

      // Assert — and the time of day is kept.
      expect(draft.isDirty, isTrue);
      expect(draft.deliveryPriceMoved, isTrue);
      expect(draft.dateMoved, isTrue);
      expect(draft.placedAt.hour, 10);
    });

    test('the same price written differently is not a move', () {
      // Arrange
      final draft = FullEditDraft(order());
      addTearDown(draft.dispose);

      // Act
      draft.deliveryPrice.text = '٢٠';

      // Assert
      expect(draft.deliveryPriceMoved, isFalse);
    });
  });
}
