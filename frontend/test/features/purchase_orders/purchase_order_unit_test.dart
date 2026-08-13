import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';

/// What a purchase-order quantity is counted in, said out loud.
///
/// **A number on a buying screen without its unit is a number nobody can act on.** «٥٠٠» against
/// «الأكياس الشفافة السادة» is five hundred kilograms — the product is priced by weight — and a
/// buyer reading it as five hundred bags orders roughly a tonne of the wrong thing. The server
/// has always sent `unit_label`; these are the getters that stop the screens dropping it.
///
/// Arrange - Act - Assert throughout.
void main() {
  PurchaseOrderItem itemWith({String? unitLabel}) => PurchaseOrderItem(
    id: 1,
    productVariantId: 4,
    quantityOrdered: '500.000',
    quantityReceived: '120.500',
    quantityRemaining: '379.500',
    unitCost: '1.500',
    unit: unitLabel == null ? null : 'kilogram',
    unitLabel: unitLabel,
  );

  group('a line bought by weight', () {
    test('says كيلوغرام after every quantity', () {
      // Arrange
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert — trimmed the way every quantity in this app is: «120.500» is «120.5».
      expect(item.orderedWithUnit, '500 كيلوغرام');
      expect(item.receivedWithUnit, '120.5 كيلوغرام');
      expect(item.remainingWithUnit, '379.5 كيلوغرام');
    });

    test('prices per كيلوغرام, not «per unit»', () {
      // Arrange
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert — «١٫٥ د.ل للكيلوغرام» is a price a buyer can check against a quote;
      // «للوحدة» is a word that names nothing.
      expect(item.perUnitSuffix, 'للكيلوغرام');
    });

    test('names the cost field after the thing being priced', () {
      // Arrange
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert
      expect(item.costFieldLabel, 'تكلفة الكيلوغرام (د.ل)');
      expect(item.quantityFieldLabel, 'الكمية المطلوبة (كيلوغرام)');
    });

    test('the receiving box asks for the same unit the order was raised in', () {
      // Arrange — the buyer typed kilograms; the storeman must not be asked for bags.
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert
      expect(item.lineUnit.receivedField, 'الكمية التي وصلت (كيلوغرام)');
    });
  });

  group('a line bought by the piece', () {
    test('says قطعة, and the wording is the same shape', () {
      // Arrange
      final item = itemWith(unitLabel: 'قطعة');

      // Act & Assert — one sentence shape for both units, so «للقطعة» and «للكيلوغرام» are read
      // in the same place on the row rather than each needing to be found.
      expect(item.orderedWithUnit, '500 قطعة');
      expect(item.perUnitSuffix, 'للقطعة');
      expect(item.costFieldLabel, 'تكلفة القطعة (د.ل)');
    });
  });

  group('a line older than the unit column', () {
    test('says nothing rather than guessing', () {
      // Arrange — `unit` was added and backfilled, so this is defensive rather than expected.
      final item = itemWith();

      // Act & Assert — a bare number is honest. Defaulting to «قطعة» is how a weight came to be
      // read as a count in the first place, and it would be wrong silently.
      expect(item.orderedWithUnit, '500');
      expect(item.perUnitSuffix, 'للوحدة');
      expect(item.costFieldLabel, 'تكلفة الوحدة (د.ل)');
      expect(item.quantityFieldLabel, 'الكمية المطلوبة');
    });
  });
}
