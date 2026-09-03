import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:flutter_test/flutter_test.dart';

/// How one movement reads on the workshop-wide feed, where no warehouse was named and the
/// server therefore sent no sign: the direction is still on the row — which end is missing
/// says whether the stock entered the business or left it — and the reference says what it
/// was, not just that there was one.
///
/// Arrange - Act - Assert throughout.
void main() {
  const main = MovementPlace(id: 1, name: 'المخزن الرئيسي');
  const floor = MovementPlace(id: 2, name: 'مخزن التشغيل');

  StockMovement movement({
    MovementType type = MovementType.purchaseArrival,
    String quantity = '1.600',
    String? signed,
    int? referenceId,
    MovementPlace? from,
    MovementPlace? to = main,
    String? unitLabel,
  }) => StockMovement(
    id: 1,
    movementType: type,
    movementTypeLabel: 'توريد',
    quantity: quantity,
    stockItemId: 7,
    fromWarehouseId: from?.id,
    fromWarehouse: from,
    toWarehouseId: to?.id,
    toWarehouse: to,
    referenceId: referenceId,
    signedQuantity: signed,
    unitLabel: unitLabel,
  );

  group('the direction, with no warehouse in the question', () {
    test('stock arriving from outside is a plus', () {
      // Arrange
      final row = movement(to: main);

      // Act
      final label = row.directedQuantityLabel;

      // Assert
      expect(label, '+1.6');
    });

    test('stock leaving the business is a minus', () {
      // Arrange
      final row = movement(type: MovementType.orderFulfillment, from: main, to: null);

      // Act
      final label = row.directedQuantityLabel;

      // Assert
      expect(label, '−1.6');
    });

    test('a count downwards is a minus too — it took stock off the shelf', () {
      // Arrange
      final row = movement(type: MovementType.adjustment, quantity: '3.000', from: main, to: null);

      // Act
      final label = row.directedQuantityLabel;

      // Assert
      expect(label, '−3');
    });

    test('a transfer changes no total, so it carries no sign', () {
      // Arrange
      final row = movement(type: MovementType.internalTransfer, quantity: '20.600', from: main, to: floor);

      // Act
      final label = row.directedQuantityLabel;

      // Assert
      expect(label, '20.6');
    });

    test("the server's own sign wins when the feed was read for one warehouse", () {
      // Arrange — a transfer, read from the shelf that sent it
      final row = movement(type: MovementType.internalTransfer, from: main, to: floor, signed: '-1.600');

      // Act
      final label = row.directedQuantityLabel;

      // Assert
      expect(label, '−1.6');
    });
  });

  group('the reference', () {
    test('an issue for an order names the order', () {
      // Arrange
      final row = movement(type: MovementType.orderFulfillment, from: main, to: null, referenceId: 1242);

      // Act
      final (label, orderId) = (row.referenceLabel, row.orderId);

      // Assert
      expect(label, 'طلب #1242');
      expect(orderId, 1242);
    });

    test('a reversal and a scrap loss belong to an order as well', () {
      // Arrange
      final reversal = movement(type: MovementType.orderReversal, referenceId: 1229);
      final scrap = movement(type: MovementType.scrapLoss, from: main, to: null, referenceId: 1229);

      // Act
      final labels = [reversal.referenceLabel, scrap.referenceLabel];

      // Assert
      expect(labels, ['طلب #1229', 'طلب #1229']);
      expect(reversal.orderId, 1229);
    });

    test("an arrival's reference is a document number, not an order", () {
      // Arrange
      final row = movement(referenceId: 5);

      // Act
      final (label, orderId) = (row.referenceLabel, row.orderId);

      // Assert
      expect(label, 'مرجع #5');
      expect(orderId, isNull);
    });

    test('no reference, nothing said', () {
      // Arrange
      final row = movement();

      // Act
      final label = row.referenceLabel;

      // Assert
      expect(label, isNull);
    });
  });

  test('the unit arrives with the row and is drawn as sent', () {
    // Arrange
    final row = StockMovement.fromJson({
      'id': 1,
      'movement_type': 'purchase_arrival',
      'movement_type_label': 'توريد',
      'quantity': '1.600',
      'stock_item_id': 7,
      'unit': 'kilogram',
      'unit_label': 'كيلوغرام',
    });

    // Act
    final unit = row.unitLabel;

    // Assert
    expect(unit, 'كيلوغرام');
  });
}
