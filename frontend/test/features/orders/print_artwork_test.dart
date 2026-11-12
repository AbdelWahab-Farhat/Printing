import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/orders/models/print_artwork.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:flutter_test/flutter_test.dart';

/// «لا طلبية طباعة بلا ألوانها» on the new-order form — the server's rule mirrored, so the button
/// stays shut instead of the server refusing (PRINT-COLORS.md §9).
///
/// Arrange - Act - Assert throughout.
void main() {
  Product under(ProductionMode? mode, {int id = 1}) => Product(
    id: id,
    code: 'P$id',
    slug: 'p-$id',
    name: 'منتج $id',
    pricingUnit: 'piece',
    pricingUnitLabel: 'قطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'حسب الكمية',
    minOrderQuantity: '1.000',
    productCategory: mode == null
        ? null
        : ProductCategory(id: 9, name: 'تصنيف', productionMode: mode),
  );

  const black = PrintColor(name: 'أسود', hex: '#000000');
  const named = PrintColor(name: 'أزرق');
  const coded = PrintColor(name: 'أحمر', code: 'PANTONE 186 C');

  group('linesPrintHere', () {
    test('an empty form prints nothing yet', () {
      expect(linesPrintHere(const <Product>[]), isFalse);
    });

    test('a printed line makes it a print order, even beside plain ones', () {
      expect(linesPrintHere([under(ProductionMode.none), under(ProductionMode.inHouse, id: 2)]), isTrue);
    });

    test('plain goods alone are not printed', () {
      expect(linesPrintHere([under(ProductionMode.none), under(ProductionMode.none, id: 2)]), isFalse);
    });

    test('a vendor’s goods alone are not printed by us', () {
      expect(linesPrintHere([under(ProductionMode.outsourced)]), isFalse);
    });

    test('a product with no heading counts as printed, as on the server', () {
      expect(linesPrintHere([under(null)]), isTrue);
    });
  });

  group('printArtworkIsReady', () {
    test('an order nobody prints needs nothing', () {
      expect(
        printArtworkIsReady(printsHere: false, drawnInHouse: false, designColors: const []),
        isTrue,
      );
    });

    test('a print order with no design is not ready', () {
      expect(
        printArtworkIsReady(printsHere: true, drawnInHouse: false, designColors: const []),
        isFalse,
      );
    });

    test('unless we are drawing it — the colours come on the design ticket', () {
      expect(
        printArtworkIsReady(printsHere: true, drawnInHouse: true, designColors: const []),
        isTrue,
      );
    });

    test('a design with no colours is not ready', () {
      expect(
        printArtworkIsReady(printsHere: true, drawnInHouse: false, designColors: const [[]]),
        isFalse,
      );
    });

    test('a colour named without its swatch is not ready', () {
      expect(
        printArtworkIsReady(
          printsHere: true,
          drawnInHouse: false,
          designColors: const [
            [black, named],
          ],
        ),
        isFalse,
      );
    });

    test('every design must be ready, not only the first', () {
      expect(
        printArtworkIsReady(
          printsHere: true,
          drawnInHouse: false,
          designColors: const [
            [black],
            [],
          ],
        ),
        isFalse,
      );
    });

    test('swatches or press codes on every colour make it ready', () {
      expect(
        printArtworkIsReady(
          printsHere: true,
          drawnInHouse: false,
          designColors: const [
            [black, coded],
          ],
        ),
        isTrue,
      );
    });
  });
}
