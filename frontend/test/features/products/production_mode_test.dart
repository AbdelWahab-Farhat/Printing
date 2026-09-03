import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:flutter_test/flutter_test.dart';

/// «طريقة التنفيذ» — the three answers to how goods under a heading come to exist, and the one
/// this app invents for an answer it has never heard.
///
/// The boolean this replaced could hold two of the three; what is under test is that every
/// shape the server sends lands on the right case, and that the two questions the screens ask of
/// a mode — «هل يحمل سعر تكلفة؟» and «هل يحتاج مورداً؟» — answer yes for وسيط and for nothing
/// else.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('reading a category off the wire', () {
    test('a وسيط heading parses as outsourced, with the server\'s own word beside it', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 9,
        'name': 'كروت بزنس',
        'production_mode': 'outsourced',
        'production_mode_label': 'وسيط — لدى مورد خارجي',
        'skips_production': true,
      };

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.productionMode, ProductionMode.outsourced);
      expect(category.productionModeCaption, 'وسيط — لدى مورد خارجي');
    });

    test('a heading the server said nothing about is ordinary production work', () {
      // Arrange — the unknown case takes the road that asks more of the shop, never less.
      final json = <String, dynamic>{'id': 5, 'name': 'أكياس مطبوعة'};

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert
      expect(category.productionMode, ProductionMode.inHouse);
      expect(category.productionModeCaption, ProductionMode.inHouse.label);
    });

    test('a fourth mode added on the server does not take the list down', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 6,
        'name': 'شيء جديد',
        'production_mode': 'assembled',
        'production_mode_label': 'تجميع',
      };

      // Act
      final category = ProductCategory.fromJson(json);

      // Assert — parsed as unknown, drawn with the word that came with it.
      expect(category.productionMode, ProductionMode.unknown);
      expect(category.productionModeCaption, 'تجميع');
    });

    test('the effective mode arrives nested on a product', () {
      // Arrange — the product endpoint sends the parent's answer already applied, which is what
      // the product form and the new-order form read.
      final json = <String, dynamic>{
        'id': 3,
        'code': 'P3',
        'slug': 'business-cards',
        'name': 'كروت بزنس',
        'pricing_unit': 'piece',
        'pricing_unit_label': 'قطعة',
        'pricing_mode': 'tiered',
        'pricing_mode_label': 'حسب الكمية',
        'min_order_quantity': '50.000',
        'product_category': {
          'id': 9,
          'name': 'كروت',
          'production_mode': 'outsourced',
          'production_mode_label': 'وسيط — لدى مورد خارجي',
        },
        'variants': [
          {'id': 12, 'label': 'قياسي', 'cost_price': '25.000'},
          {'id': 13, 'label': 'مربع'},
        ],
      };

      // Act
      final product = Product.fromJson(json);

      // Assert
      expect(product.productCategory?.productionMode, ProductionMode.outsourced);
      expect(product.variants.first.costPrice, '25.000');
      // Absent is null — and null is *not* «بلا تكلفة»; the screens gate on the grant.
      expect(product.variants.last.costPrice, isNull);
    });
  });

  group('what a mode decides', () {
    test('only وسيط carries a cost price', () {
      // Arrange - Act - Assert
      expect(ProductionMode.outsourced.hasCostPrice, isTrue);
      expect(ProductionMode.inHouse.hasCostPrice, isFalse);
      expect(ProductionMode.none.hasCostPrice, isFalse);
      expect(ProductionMode.unknown.hasCostPrice, isFalse);
    });

    test('only وسيط needs a vendor', () {
      // Arrange - Act - Assert
      expect(ProductionMode.outsourced.needsAVendor, isTrue);
      expect(ProductionMode.inHouse.needsAVendor, isFalse);
      expect(ProductionMode.none.needsAVendor, isFalse);
      expect(ProductionMode.unknown.needsAVendor, isFalse);
    });

    test('the picker offers the three real modes and never the invented one', () {
      // Arrange - Act
      final offered = ProductionMode.choices;

      // Assert
      expect(offered, [ProductionMode.inHouse, ProductionMode.none, ProductionMode.outsourced]);
      expect(offered, isNot(contains(ProductionMode.unknown)));
    });
  });
}
