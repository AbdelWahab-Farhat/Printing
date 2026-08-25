import 'package:dayaa/features/products/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

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

  /// **«المادة» — where what the shelf counts in went.**
  ///
  /// A product used to carry a `stock_unit` of its own beside its `pricing_unit`, and that column
  /// is gone: «كيس شحن سادة 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows over one pile
  /// of bags, so neither of them can own how that pile is counted. The split the old pair
  /// expressed is intact and still worth pinning — what the customer is charged by is one thing
  /// and what the warehouse counts is another — it simply has two owners now: `pricing_unit` on
  /// the product, `unit` on the shelf, with the material deciding what a *new* shelf starts out
  /// counted in.
  group('the material', () {
    Map<String, dynamic> material(Map<String, dynamic> overrides) => {
      'id': 3,
      'code': 'G3',
      'name': 'كيس شحن',
      'default_unit': 'piece',
      'default_unit_label': 'قطعة',
      ...overrides,
    };

    Map<String, dynamic> shelf(Map<String, dynamic> overrides) => {
      'id': 4,
      'code': 'S4',
      'name': 'كيس شحن',
      'width_cm': 25,
      'height_cm': 35,
      'display_name': 'كيس شحن 25*35',
      'unit': 'piece',
      'unit_label': 'قطعة',
      ...overrides,
    };

    test('what the shelf counts in is read beside the pricing unit, not instead of it', () {
      // Arrange — a bag bought in by the kilo and sold by the piece. Still one product and two
      // units; the second one now belongs to the material and to the shelf under it.
      final product = Product.fromJson(
        productJson({
          'stock_item_group_id': 3,
          'stock_item_group': material({
            'default_unit': 'kilogram',
            'default_unit_label': 'كيلوغرام',
          }),
          'variants': [
            variantJson({
              'stock_item_id': 4,
              'stock_item': shelf({'unit': 'kilogram', 'unit_label': 'كيلوغرام'}),
            }),
          ],
        }),
      );

      // Act & Assert — both survive and neither is derived from the other. The material's
      // `default_unit` is what a shelf minted for a *new* size starts out counted in; the
      // shelf's own `unit` is what the existing pile is counted in today. The two are read
      // apart because changing the material's never disturbs a shelf that already exists.
      expect(product.pricingUnit, 'piece');
      expect(product.stockItemGroup?.defaultUnit, 'kilogram');
      expect(product.stockItemGroup?.defaultUnitLabel, 'كيلوغرام');
      expect(product.variants.single.stockItem?.unit, 'kilogram');
    });

    test('is read off the id, so a response that carried only it still counts', () {
      // Arrange — `stock_item_group` is eager-loaded on every product path today, but the id is
      // a plain column and always on the wire. A screen that decided «بلا مادة» from a missing
      // relation would be stating a fact the payload never made.
      final related = Product.fromJson(
        productJson({'stock_item_group_id': 3, 'stock_item_group': material({})}),
      );
      final bare = Product.fromJson(productJson({'stock_item_group_id': 3}));
      final none = Product.fromJson(productJson({}));

      // Act & Assert
      expect(related.hasMaterial, isTrue);
      expect(bare.hasMaterial, isTrue);
      expect(bare.stockItemGroup, isNull);
      // A quote-only bag genuinely has none, and that is an answer rather than a fault.
      expect(none.hasMaterial, isFalse);
    });

    test('the shelf a size draws on is named exactly as the server composed it', () {
      // Arrange — «كيس شحن 25*35», one `*` and no spaces. The sentence an order is refused with
      // at «جاهزة» quotes this string, so rebuilding it here out of the name and the dimensions
      // would hand the storekeeper a second spelling of one shelf to reconcile.
      final product = Product.fromJson(
        productJson({
          'variants': [
            variantJson({'stock_item_id': 4, 'stock_item': shelf({})}),
          ],
        }),
      );

      // Act
      final variant = product.variants.single;

      // Assert — and a code, where a product thumbnail used to be: a pile is not one product's,
      // so picturing either of the two sharing it would tell the storekeeper the wrong thing.
      expect(variant.shelfLabel, 'كيس شحن 25*35');
      expect(variant.stockItem?.code, 'S4');
      expect(variant.isStocked, isTrue);
    });

    test('a size with no shelf is reported by name rather than treated as a fault', () {
      // Arrange — `stock_item_id` is nullable because a quote-only size is never stocked. Every
      // stock path refuses such a size by name, so a screen that said nothing about it would
      // leave the limitation to be discovered when an order failed at «جاهزة».
      final product = Product.fromJson(
        productJson({
          'variants': [
            variantJson({'id': 1, 'stock_item_id': 4, 'stock_item': shelf({})}),
            variantJson({'id': 2, 'label': 'حسب الطلب'}),
          ],
        }),
      );

      // Act
      final unlinked = product.unlinkedVariants;

      // Assert — the unstocked size is singled out, and the stocked one is left alone.
      expect(unlinked, hasLength(1));
      expect(unlinked.single.label, 'حسب الطلب');
      expect(unlinked.single.isStocked, isFalse);
      expect(unlinked.single.shelfLabel, isNull);
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

      // Assert — numerically, not as text: '1000' sorts before '300' as a string. The
      // labels arrive grouped, which is how every number in this app is drawn.
      expect([for (final tier in ordered) tier.minQuantityLabel], ['100', '300', '1,000']);
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
