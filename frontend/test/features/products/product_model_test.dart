import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/products/models/product.dart';

/// What the detail screen reads off the model, and nothing a widget is allowed to work out for
/// itself: the measured size of a variant, the order of a price ladder, and what a photograph
/// actually is.
///
/// Arrange - Act - Assert throughout.
void main() {
  Map<String, dynamic> productJson(Map<String, dynamic> overrides) => {
    'id': 7,
    'code': 'P7',
    'slug': 'shipping-bag',
    'name': 'كيس شحن',
    'category': 'printed',
    'category_label': 'مطبوعة',
    'pricing_unit': 'piece',
    'pricing_unit_label': 'قطعة',
    'pricing_mode': 'listed',
    'pricing_mode_label': 'سعر معلن',
    'has_listed_prices': true,
    'min_order_quantity': '100.000',
    'is_active': true,
    'created_at': '2026-07-30T12:00:00+00:00',
    'updated_at': '2026-08-02T09:30:00+00:00',
    ...overrides,
  };

  Map<String, dynamic> variantJson(Map<String, dynamic> overrides) => {
    'id': 1,
    'label': '25*35',
    'width_cm': 25,
    'height_cm': 35,
    'is_active': true,
    'sort_order': 0,
    'price_tiers': <Map<String, dynamic>>[],
    ...overrides,
  };

  group('timestamps', () {
    test('are parsed, so the screen can say when the bag entered the catalogue', () {
      // Arrange — the API has always sent these; nothing read them until a screen had room.
      final product = Product.fromJson(productJson({}));

      // Act
      final created = product.createdAt;

      // Assert
      expect(created, isNotNull);
      expect(created!.year, 2026);
      expect(product.updatedAt, isNotNull);
    });
  });

  group('ProductVariant.dimensionsLabel', () {
    test('states the measured size, which the card has no room for', () {
      // Arrange
      final variant = ProductVariant.fromJson(variantJson({}));

      // Act
      final label = variant.dimensionsLabel;

      // Assert
      expect(label, '25 × 35 سم');
    });

    test('is null for a size recorded as a name only', () {
      // Arrange — a shop may call a size «كبير» and never have measured it, which is why the
      // API sends the label and the dimensions separately.
      final variant = ProductVariant.fromJson(
        variantJson({'label': 'كبير', 'width_cm': null, 'height_cm': null}),
      );

      // Act
      final label = variant.dimensionsLabel;

      // Assert
      expect(label, isNull);
    });

    test('is null when only one dimension is known', () {
      // Arrange — half a measurement is not a size.
      final variant = ProductVariant.fromJson(variantJson({'height_cm': null}));

      // Act & Assert
      expect(variant.dimensionsLabel, isNull);
    });
  });

  group('ProductVariant.tiersByQuantity', () {
    test('orders the ladder ascending however the server sent it', () {
      // Arrange — the screen reads «١٠٠ فأكثر، ٣٠٠ فأكثر، ١٠٠٠ فأكثر», so the order is the
      // model's job and not the caller's hope.
      final variant = ProductVariant.fromJson(
        variantJson({
          'price_tiers': [
            {'id': 3, 'min_quantity': '1000.000', 'unit_price': '0.700'},
            {'id': 1, 'min_quantity': '100.000', 'unit_price': '0.900'},
            {'id': 2, 'min_quantity': '300.000', 'unit_price': '0.850'},
          ],
        }),
      );

      // Act
      final ordered = variant.tiersByQuantity;

      // Assert — numerically, not as text: '1000' sorts before '300' as a string.
      expect([for (final tier in ordered) tier.minQuantityLabel], ['100', '300', '1000']);
    });

    test('leaves the price strings exactly as the server sent them', () {
      // Arrange — money is text here; ordering must never round-trip a value through a float.
      final variant = ProductVariant.fromJson(
        variantJson({
          'price_tiers': [
            {'id': 1, 'min_quantity': '100.000', 'unit_price': '0.850'},
          ],
        }),
      );

      // Act
      final price = variant.tiersByQuantity.single.unitPrice;

      // Assert
      expect(price, '0.850');
    });

    test('does not reorder the variant it was read from', () {
      // Arrange — a getter that sorted in place would change what every other reader sees.
      final variant = ProductVariant.fromJson(
        variantJson({
          'price_tiers': [
            {'id': 2, 'min_quantity': '300.000', 'unit_price': '0.850'},
            {'id': 1, 'min_quantity': '100.000', 'unit_price': '0.900'},
          ],
        }),
      );

      // Act
      variant.tiersByQuantity;

      // Assert
      expect(variant.priceTiers.first.id, 2);
    });
  });

  group('activeVariants', () {
    test('counts what can be ordered, while variants still holds what is shown', () {
      // Arrange — a stopped size stays on the screen because it is what a past order was
      // priced at; only the count of what is on offer excludes it.
      final product = Product.fromJson(
        productJson({
          'variants': [
            variantJson({'id': 1}),
            variantJson({'id': 2, 'is_active': false}),
          ],
        }),
      );

      // Act
      final active = product.activeVariants;

      // Assert
      expect(product.variants, hasLength(2));
      expect(active, hasLength(1));
      expect(active.single.id, 1);
    });
  });

  group('hasAnyPrice', () {
    test('is false for a bag quoted by hand', () {
      // Arrange
      final product = Product.fromJson(
        productJson({
          'pricing_mode': 'quote',
          'has_listed_prices': false,
          'variants': [variantJson({})],
        }),
      );

      // Act & Assert — no number this app derived from an empty ladder.
      expect(product.hasAnyPrice, isFalse);
      expect(product.startingPrice, isNull);
    });

    test('is true as soon as one size is priced', () {
      // Arrange
      final product = Product.fromJson(
        productJson({
          'variants': [
            variantJson({
              'price_tiers': [
                {'id': 1, 'min_quantity': '100.000', 'unit_price': '0.850'},
              ],
            }),
          ],
        }),
      );

      // Act & Assert
      expect(product.hasAnyPrice, isTrue);
      expect(product.startingPrice, '0.850');
    });
  });

  group('ProductImage', () {
    Map<String, dynamic> imageJson(Map<String, dynamic> overrides) => {
      'id': 1,
      'url': 'https://example.test/a.jpg',
      'is_primary': true,
      'sort_order': 0,
      ...overrides,
    };

    test('states what the file is, now that a screen has room to say it', () {
      // Arrange
      final image = ProductImage.fromJson(
        imageJson({'width_px': 1200, 'height_px': 800, 'size_bytes': 245760}),
      );

      // Act & Assert
      expect(image.dimensionsLabel, '1200 × 800');
      expect(image.sizeLabel, '240 ك.ب');
    });

    test('grows into megabytes with one decimal, never gigabytes', () {
      // Arrange — a photograph is never small enough for bytes to be useful, nor large enough
      // for the next unit up.
      final image = ProductImage.fromJson(imageJson({'size_bytes': 3 * 1024 * 1024}));

      // Act & Assert
      expect(image.sizeLabel, '3.0 م.ب');
    });

    test('says nothing about a file the server never measured', () {
      // Arrange — the columns are nullable; a missing measurement leaves a line off the screen
      // rather than printing a zero that reads as a fact.
      final image = ProductImage.fromJson(imageJson({}));

      // Act & Assert
      expect(image.dimensionsLabel, isNull);
      expect(image.sizeLabel, isNull);
    });
  });
}
