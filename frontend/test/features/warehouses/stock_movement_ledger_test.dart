import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:flutter_test/flutter_test.dart';

/// How one movement reads as a line of a ledger: signed, with the balance it left behind, and
/// — for a reader allowed to know — what the stock on it cost.
///
/// Arrange - Act - Assert throughout.
void main() {
  const main = MovementPlace(id: 1, name: 'المخزن الرئيسي');
  const floor = MovementPlace(id: 2, name: 'صالة العرض');

  StockMovement movement({
    MovementType type = MovementType.purchaseArrival,
    String quantity = '1000.000',
    String? signed,
    String? after,
    String? unitCost,
    String? totalCost,
    String? uncosted,
    MovementPlace? from,
    MovementPlace? to = main,
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
    signedQuantity: signed,
    balanceAfter: after,
    unitCost: unitCost,
    totalCost: totalCost,
    uncostedQuantity: uncosted,
  );

  group('the signed column', () {
    test('a thousand in and a thousand out are never the same digits', () {
      // Arrange
      final arrival = movement(signed: '1000.000');
      final issue = movement(signed: '-1000.000');

      // Act + Assert
      expect(arrival.signedQuantityLabel, '+1,000');
      expect(issue.signedQuantityLabel, '−1,000');
      expect(arrival.isInbound, isTrue);
      expect(issue.isInbound, isFalse);
    });

    test('an unscoped feed has no sign to give', () {
      // Arrange
      final row = movement();

      // Act + Assert
      expect(row.signedQuantityLabel, isNull);
      expect(row.isInbound, isNull);
      expect(row.balanceAfterLabel, isNull);
    });
  });

  group('a count', () {
    test('hands back the number the person saw: what the shelf held before it', () {
      // Arrange — the screenshot's adjustment: 105,250 on the books, nothing on the shelf
      final count = movement(
        type: MovementType.adjustment,
        quantity: '105250.000',
        signed: '-105250.000',
        after: '0.000',
        from: main,
        to: null,
      );

      // Act + Assert
      expect(count.balanceBeforeLabel, '105,250');
      expect(count.balanceAfterLabel, '0');
    });
  });

  group('the other end of a transfer', () {
    test('is named from where the ledger is read, and never for anything else', () {
      // Arrange
      final transfer = movement(type: MovementType.internalTransfer, from: main, to: floor);
      final arrival = movement();

      // Act + Assert
      expect(transfer.otherEndFrom(main.id), '← صالة العرض');
      expect(transfer.otherEndFrom(floor.id), 'من المخزن الرئيسي');
      expect(arrival.otherEndFrom(main.id), '');
    });
  });

  group('the cost line', () {
    test('arriving stock leads with its price, leaving stock with its total', () {
      // Arrange
      final arrival = movement(
        signed: '300.000',
        quantity: '300.000',
        unitCost: '3.500',
        totalCost: '1050.00',
        uncosted: '0.000',
      );
      final issue = movement(
        type: MovementType.orderFulfillment,
        signed: '-1000.000',
        unitCost: '3.500',
        totalCost: '3500.00',
        uncosted: '0.000',
        from: main,
        to: null,
      );

      // Act + Assert
      expect(arrival.costLine('قطعة')?.text, '3.500 د.ل/قطعة · 1,050 د.ل');
      expect(arrival.costLine('قطعة')?.warns, isFalse);
      expect(issue.costLine('قطعة')?.text, '3,500 د.ل (3.500/قطعة)');
    });

    test('stock nobody priced is a word, never a zero', () {
      // Arrange
      final unpriced = movement(totalCost: '0.00', uncosted: '1000.000');

      // Act
      final line = unpriced.costLine('قطعة');

      // Assert
      expect(line?.text, 'بلا تكلفة');
      expect(line?.warns, isTrue);
      expect(line?.text, isNot(contains('0')));
    });

    test('a row partly unpriced shows the total it can vouch for and names the rest', () {
      // Arrange — 150 issued: 100 from a layer at zero and 50 at 5.000
      final issue = movement(
        type: MovementType.orderFulfillment,
        quantity: '150.000',
        signed: '-150.000',
        totalCost: '250.00',
        uncosted: '100.000',
        from: main,
        to: null,
      );

      // Act
      final line = issue.costLine('قطعة');

      // Assert — and no unit price: an average that counts zeros describes nothing
      expect(line?.text, '250 د.ل · 100 قطعة بلا تكلفة');
      expect(line?.warns, isTrue);
      expect(line?.text, isNot(contains('/')));
    });

    test('a row older than the cost ledger has no line at all', () {
      // Arrange
      final old = movement(signed: '1000.000');

      // Act + Assert
      expect(old.costLine('قطعة'), isNull);
    });
  });
}
