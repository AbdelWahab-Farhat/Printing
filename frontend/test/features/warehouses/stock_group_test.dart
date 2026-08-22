import 'package:dayaa/features/warehouses/models/stock_group.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every size of one bag belongs on one card.
///
/// The list is one row per *size*, and a warehouse that stocks «أكياس الشحن» in four sizes
/// reads as four unrelated products with the same name repeated four times. Grouping is the
/// only thing here: the shelves themselves are untouched, and their order is the server's.
///
/// Arrange - Act - Assert throughout.
void main() {
  WarehouseStock shelf({
    required int id,
    int? productId,
    String label = '25*35',
    String productName = 'أكياس الشحن',
  }) => WarehouseStock(
    id: id,
    warehouseId: 1,
    productVariantId: id,
    quantity: '10.000',
    unit: 'kg',
    unitLabel: 'كيلوغرام',
    variant: productId == null
        ? null
        : StockVariant(
            id: id,
            label: label,
            productId: productId,
            productCode: 'P$productId',
            productName: productName,
          ),
  );

  test('sizes of the same product become one group', () {
    // Arrange
    final shelves = [
      shelf(id: 1, productId: 7, label: '25*35'),
      shelf(id: 2, productId: 7, label: '45*50'),
      shelf(id: 3, productId: 7, label: '50*60'),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert
    expect(groups, hasLength(1));
    expect(groups.single.shelves.map((s) => s.id), [1, 2, 3]);
    expect(groups.single.productName, 'أكياس الشحن');
    expect(groups.single.productCode, 'P7');
  });

  test('different products stay apart, in the order the server sent them', () {
    // Arrange
    final shelves = [
      shelf(id: 1, productId: 7),
      shelf(id: 2, productId: 9, productName: 'أكياس شحن سادة'),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert
    expect(groups.map((g) => g.productName), ['أكياس الشحن', 'أكياس شحن سادة']);
    expect(groups.every((g) => g.isSingle), isTrue);
  });

  test('the same product split by another one is still one group', () {
    // Arrange — the server orders by size id, so two sizes of one bag can arrive apart
    final shelves = [
      shelf(id: 1, productId: 7),
      shelf(id: 2, productId: 9, productName: 'أكياس شحن سادة'),
      shelf(id: 3, productId: 7, label: '50*60'),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert — merged where it first appeared, and nothing is dropped
    expect(groups, hasLength(2));
    expect(groups.first.shelves.map((s) => s.id), [1, 3]);
    expect(groups.last.shelves.map((s) => s.id), [2]);
  });

  test('a shelf that arrived without its product stands alone', () {
    // Arrange — two such lines say nothing about belonging together, so they are not joined
    final shelves = [shelf(id: 1), shelf(id: 2)];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert
    expect(groups, hasLength(2));
    expect(groups.every((g) => g.isSingle), isTrue);
  });

  test('the group wears the first picture it has, not the first shelf', () {
    // Arrange — the picture is the product's, and one size may have arrived without it
    final shelves = [
      shelf(id: 1, productId: 7),
      const WarehouseStock(
        id: 2,
        warehouseId: 1,
        productVariantId: 2,
        quantity: '5.000',
        unit: 'kg',
        unitLabel: 'كيلوغرام',
        variant: StockVariant(
          id: 2,
          label: '45*50',
          productId: 7,
          productName: 'أكياس الشحن',
          imageUrl: 'https://example.test/bag.jpg',
        ),
      ),
    ];

    // Act
    final groups = StockGroup.from(shelves);

    // Assert
    expect(groups.single.imageUrl, 'https://example.test/bag.jpg');
  });
}
