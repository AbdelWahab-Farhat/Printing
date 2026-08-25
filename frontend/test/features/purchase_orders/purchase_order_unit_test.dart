import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a purchase-order line is counted in and what it ended up costing, said out loud.
///
/// **A number on a buying screen without its unit is a number nobody can act on.** «٥٠٠» against
/// «لفة نايلون شفاف» is five hundred kilograms — that shelf is counted by weight — and a buyer
/// reading it as five hundred rolls orders roughly a tonne of the wrong thing. The server has
/// always sent `unit_label`; these are the getters that stop the screens dropping it.
///
/// **The unit is the shelf's, not the product's.** It used to be snapshotted from the product's
/// `stock_unit`, which two products sharing one pile could disagree about; that column is gone
/// and `stock_items.unit` replaced it. Nothing in the wording below changed — which is the point
/// of pinning it across the move.
///
/// **And a cost without its additional costs is a price nobody paid.** The server now spreads
/// delivery, unloading and customs across the lines and reports the landed figure per line; the
/// getters here are what make the screens quote *that* rather than what was invoiced.
///
/// Arrange - Act - Assert throughout.
void main() {
  PurchaseOrderItem itemWith({
    String? unitLabel,
    String? baseTotalCost = '750.00',
    String? baseUnitCost = '1.500',
    String? allocatedAdditionalCost,
    String? finalUnitCost,
    String? finalTotalCost,
  }) => PurchaseOrderItem(
    id: 1,
    stockItemId: 4,
    quantityOrdered: '500.000',
    quantityReceived: '120.500',
    quantityRemaining: '379.500',
    baseTotalCost: baseTotalCost,
    baseUnitCost: baseUnitCost,
    allocatedAdditionalCost: allocatedAdditionalCost,
    finalUnitCost: finalUnitCost,
    finalTotalCost: finalTotalCost,
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

    test('names the quantity field after the unit being ordered', () {
      // Arrange
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert
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
      expect(item.quantityFieldLabel, 'الكمية المطلوبة');
    });
  });

  group('what a line costs', () {
    test('quotes the landed cost, not what the vendor invoiced', () {
      // Arrange — 750 د.ل of goods carrying 97.50 د.ل of this order's delivery and customs.
      final item = itemWith(
        unitLabel: 'كيلوغرام',
        allocatedAdditionalCost: '97.50',
        finalUnitCost: '1.695',
        finalTotalCost: '847.50',
      );

      // Act & Assert — the landed figure is the one that decides whether the job made money,
      // and it is what the screen leads with.
      expect(item.unitCostLabel, '1.695');
      expect(item.totalCostLabel, '847.5');
      expect(item.hasAllocatedCost, isTrue);
      expect(item.allocatedCostLabel, '97.5');
      expect(item.baseTotalCostLabel, '750');
    });

    test('falls back to the base figures on an order with no additional costs', () {
      // Arrange — nothing was spread across the lines, so the server's final equals its base.
      final item = itemWith(
        unitLabel: 'كيلوغرام',
        allocatedAdditionalCost: '0.00',
        finalUnitCost: '1.500',
        finalTotalCost: '750.00',
      );

      // Act & Assert — no split worth printing: a «+ ٠ د.ل» line is noise on every ordinary
      // order, which is most of them.
      expect(item.hasAllocatedCost, isFalse);
      expect(item.unitCostLabel, '1.5');
      expect(item.totalCostLabel, '750');
    });

    test('a line written before the landed figures existed shows what it has', () {
      // Arrange — `final_unit_cost` is null on a line the allocator never ran over.
      final item = itemWith(unitLabel: 'كيلوغرام');

      // Act & Assert — the base cost is a true answer, and printing it beats printing nothing.
      expect(item.hasCost, isTrue);
      expect(item.hasAllocatedCost, isFalse);
      expect(item.unitCostLabel, '1.5');
      expect(item.totalCostLabel, '750');
    });

    test('a line older than cost tracking says nothing rather than «0»', () {
      // Arrange
      final item = itemWith(baseTotalCost: null, baseUnitCost: null);

      // Act & Assert — «٠ د.ل» reads as a free delivery, which is a different claim from
      // «nobody recorded this».
      expect(item.hasCost, isFalse);
    });

    test('zero is a recorded cost, not a missing one', () {
      // Arrange — a free replacement batch from the vendor.
      final item = itemWith(baseTotalCost: '0.00', baseUnitCost: '0.000');

      // Act & Assert
      expect(item.hasCost, isTrue);
      expect(item.totalCostLabel, '0');
    });
  });

  group('what a whole order costs', () {
    PurchaseOrder orderWith({
      String? totalAmount,
      String? totalAdditionalCost,
      List<PurchaseOrderAdditionalCost> additionalCosts = const [],
    }) => PurchaseOrder(
      id: 1,
      vendorId: 2,
      status: PurchaseOrderStatus.fresh,
      statusLabel: 'جديد',
      orderDate: '2026-08-13',
      totalAmount: totalAmount,
      totalAdditionalCost: totalAdditionalCost,
      additionalCosts: additionalCosts,
    );

    test('carries the order-level costs the server spread across the lines', () {
      // Arrange
      final order = orderWith(
        totalAmount: '113.00',
        totalAdditionalCost: '13.00',
        additionalCosts: const [
          PurchaseOrderAdditionalCost(id: 7, name: 'توصيل', amount: '10.00'),
          PurchaseOrderAdditionalCost(id: 8, name: 'جمارك', amount: '3.00'),
        ],
      );

      // Act & Assert
      expect(order.hasAdditionalCosts, isTrue);
      expect(order.additionalCosts.first.amountLabel, '10');
    });

    test('an order nobody added costs to has none to show', () {
      // Arrange
      final order = orderWith(totalAmount: '100.00', totalAdditionalCost: '0.00');

      // Act & Assert — the section is left off rather than drawn empty.
      expect(order.hasAdditionalCosts, isFalse);
    });
  });

  group('reading one off the wire', () {
    test('parses the landed costs and the order-level ones', () {
      // Arrange — §1 of PURCHASE-ORDER-ADDITIONAL-COSTS-FRONTEND-INTEGRATION.md, as sent.
      final json = <String, dynamic>{
        'id': 3,
        'vendor_id': 1,
        'status': 'new',
        'status_label': 'جديد',
        'order_date': '2026-08-13',
        'total_amount': '113.00',
        'total_additional_cost': '13.00',
        'additional_costs': [
          {'id': 7, 'name': 'توصيل', 'amount': '10.00'},
          {'id': 8, 'name': 'جمارك', 'amount': '3.00'},
        ],
        'items': [
          {
            'id': 40,
            'stock_item_id': 14,
            'stock_item': {
              'id': 14,
              'code': 'S7',
              'name': 'كيس شحن',
              'width_cm': 25,
              'height_cm': 35,
              'display_name': 'كيس شحن 25*35',
            },
            'quantity_ordered': '4.000',
            'quantity_received': '0.000',
            'quantity_remaining': '4.000',
            'base_total_cost': '75.00',
            'base_unit_cost': '18.750',
            'allocated_additional_cost': '9.75',
            'final_unit_cost': '21.188',
            'final_total_cost': '84.75',
            'unit': 'piece',
            'unit_label': 'قطعة',
          },
        ],
      };

      // Act
      final order = PurchaseOrder.fromJson(json);

      // Assert — strings throughout, never parsed to num: the decimals the server chose are the
      // decimals it means.
      expect(order.totalAdditionalCost, '13.00');
      expect(order.additionalCosts.map((cost) => cost.name), ['توصيل', 'جمارك']);
      expect(order.items.single.finalUnitCost, '21.188');
      expect(order.items.single.allocatedAdditionalCost, '9.75');
    });

    test('a line is titled by the shelf the server named, never by a product', () {
      // Arrange — the six fields the server flattens a stock item into, and no more: there is
      // no `product_name` and no `image_url` in them, because «كيس شحن سادة» and «كيس شحن مطبوع»
      // both draw on this line and naming either would be picking one arbitrarily.
      final json = <String, dynamic>{
        'id': 40,
        'stock_item_id': 14,
        'stock_item': {
          'id': 14,
          'code': 'S7',
          'name': 'كيس شحن',
          'width_cm': 25,
          'height_cm': 35,
          'display_name': 'كيس شحن 25*35',
        },
        'quantity_ordered': '4.000',
        'quantity_received': '0.000',
        'quantity_remaining': '4.000',
      };

      // Act
      final item = PurchaseOrderItem.fromJson(json);

      // Assert — `display_name` **as sent**, never rebuilt here from the name and the two
      // dimensions. A shortfall an order is refused with quotes this exact string, so a second
      // composition in Dart would drift from it and the first screen to notice would be one
      // comparing a refusal to a list. The code is what a buyer reads down a phone line to a
      // supplier, in the space the product photograph used to occupy.
      expect(item.title, 'كيس شحن 25*35');
      expect(item.itemCode, 'S7');
      expect(item.stockItem?.sizeLabel, '25*35');
    });

    test('a line whose shelf did not travel with it still says something', () {
      // Arrange — `stock_item` is `whenLoaded`, and every endpoint publishing an order eager-
      // loads it today. This is the payload that would arrive if one stopped.
      final json = <String, dynamic>{
        'id': 40,
        'stock_item_id': 14,
        'quantity_ordered': '4.000',
        'quantity_received': '0.000',
        'quantity_remaining': '4.000',
      };

      // Act
      final item = PurchaseOrderItem.fromJson(json);

      // Assert — a fallback rather than a failed page, and **no invented code**: nothing to
      // print beats a plausible `S14` that names a different shelf.
      expect(item.title, 'مقاس #14');
      expect(item.itemCode, isNull);
    });

    test('an order raised before any of this parses with the fields absent', () {
      // Arrange — the list endpoint and old rows both leave these out.
      final json = <String, dynamic>{
        'id': 3,
        'vendor_id': 1,
        'status': 'new',
        'status_label': 'جديد',
        'order_date': '2026-08-13',
      };

      // Act
      final order = PurchaseOrder.fromJson(json);

      // Assert — an absent list is an empty one, so no screen has to null-check it.
      expect(order.totalAdditionalCost, isNull);
      expect(order.additionalCosts, isEmpty);
    });
  });
}
