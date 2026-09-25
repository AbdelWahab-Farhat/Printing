import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

/// قواعد الكمية التي يرسمها السلايدر وزرّا + و−: الخطوة، والحدّان، وما يُكتب تحت كل مقاس.
///
/// Arrange - Act - Assert throughout.
void main() {
  const pieces = Product(
    id: 1,
    name: 'أكياس شحن - مطبوعة',
    pricingUnit: 'piece',
    minOrderQuantity: '100.000',
    variants: [
      ProductVariant(
        id: 10,
        label: 'صغير',
        priceTiers: [
          PriceTier(id: 1, minQuantity: '100.000', unitPrice: '1.130'),
          PriceTier(id: 2, minQuantity: '300.000', unitPrice: '1.030'),
          PriceTier(id: 3, minQuantity: '1000.000', unitPrice: '0.880'),
        ],
      ),
    ],
  );

  const kilos = Product(
    id: 12,
    name: 'أكياس شفافه - ساده',
    pricingUnit: 'kilogram',
    minOrderQuantity: '1.000',
    variants: [
      ProductVariant(
        id: 40,
        label: 'صغير جدا',
        priceTiers: [PriceTier(id: 9, minQuantity: '1.000', unitPrice: '49.000')],
      ),
    ],
  );

  group('quantityStep', () {
    test('pieces move fifty at a time', () {
      // Arrange
      const product = pieces;

      // Act
      final step = product.quantityStep;

      // Assert
      expect(step, 50);
    });

    test('a kilogram moves one at a time', () {
      // Arrange
      const product = kilos;

      // Act
      final step = product.quantityStep;

      // Assert
      expect(step, 1);
    });

    test('a unit this build has not heard of moves one at a time', () {
      // Arrange
      const product = Product(id: 3, name: 'متر', pricingUnit: 'metre');

      // Act
      final step = product.quantityStep;

      // Assert
      expect(step, 1);
    });
  });

  group('quantityFloor', () {
    test('is the product minimum, read as a number', () {
      // Arrange
      const product = pieces;

      // Act
      final floor = product.quantityFloor;

      // Assert
      expect(floor, 100);
    });

    test('is one when the product states no minimum', () {
      // Arrange
      const product = Product(id: 3, name: 'بلا حد', pricingUnit: 'piece');

      // Act
      final floor = product.quantityFloor;

      // Assert
      expect(floor, 1);
    });
  });

  group('quantityCeiling', () {
    test('pieces reach two thousand', () {
      // Arrange
      const product = pieces;

      // Act
      final ceiling = product.quantityCeiling;

      // Assert
      expect(ceiling, 2000);
    });

    test('kilograms reach a hundred', () {
      // Arrange
      const product = kilos;

      // Act
      final ceiling = product.quantityCeiling;

      // Assert
      expect(ceiling, 100);
    });

    test('a break beyond the usual end pushes it to twice that break', () {
      // Arrange
      const product = Product(
        id: 4,
        name: 'بكميات كبيرة',
        pricingUnit: 'piece',
        minOrderQuantity: '100.000',
        variants: [
          ProductVariant(
            id: 20,
            label: 'صغير',
            priceTiers: [
              PriceTier(id: 1, minQuantity: '100.000', unitPrice: '1.000'),
              PriceTier(id: 2, minQuantity: '5000.000', unitPrice: '0.700'),
            ],
          ),
        ],
      );

      // Act
      final ceiling = product.quantityCeiling;

      // Assert
      expect(ceiling, 10000);
    });

    test('never sits on top of the minimum', () {
      // Arrange
      const product = Product(
        id: 5,
        name: 'حدّه عالٍ',
        pricingUnit: 'piece',
        minOrderQuantity: '3000.000',
      );

      // Act
      final ceiling = product.quantityCeiling;

      // Assert
      expect(ceiling, 6000);
    });
  });

  group('dimensions', () {
    test('are written width by height, without a trailing .0', () {
      // Arrange
      const variant = ProductVariant(id: 1, label: 'صغير', widthCm: 25, heightCm: 35.0);

      // Act
      final dimensions = variant.dimensions;

      // Assert
      expect(dimensions, '25×35');
    });

    test('are null when the size has no centimetres', () {
      // Arrange
      const variant = ProductVariant(id: 1, label: 'كروت عاديه');

      // Act
      final dimensions = variant.dimensions;

      // Assert
      expect(dimensions, isNull);
    });

    test('are shown under a name, and not under a label that already is them', () {
      // Arrange
      const named = ProductVariant(id: 1, label: 'متوسط', widthCm: 35, heightCm: 40);
      const measured = ProductVariant(id: 2, label: '30*30', widthCm: 30, heightCm: 30);

      // Act
      final underName = named.dimensionsUnderLabel;
      final underMeasure = measured.dimensionsUnderLabel;

      // Assert
      expect(underName, '35×40');
      expect(underMeasure, isNull);
    });
  });

  test('a quantity is a number above zero, and nothing else', () {
    // Arrange
    const typed = ['750', '2.5', '100.', '0', '', '.', '1.2.3'];

    // Act
    final taken = typed.where(isOrderableQuantity).toList();

    // Assert
    expect(taken, ['750', '2.5', '100.']);
  });

  test('the breaks are read in order of quantity, whatever order they arrived in', () {
    // Arrange
    const variant = ProductVariant(
      id: 1,
      label: 'صغير',
      priceTiers: [
        PriceTier(id: 3, minQuantity: '1000.000', unitPrice: '0.880'),
        PriceTier(id: 1, minQuantity: '100.000', unitPrice: '1.130'),
        PriceTier(id: 2, minQuantity: '300.000', unitPrice: '1.030'),
      ],
    );

    // Act
    final ordered = variant.tiersInOrder.map((tier) => tier.id).toList();

    // Assert
    expect(ordered, [1, 2, 3]);
  });
}
