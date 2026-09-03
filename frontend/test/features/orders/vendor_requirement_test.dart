import 'package:dayaa/features/orders/models/vendor_requirement.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:flutter_test/flutter_test.dart';

/// «هل تحتاج هذه الطلبية مورداً؟» — the one rule the new-order form has to mirror rather than
/// invent, because the server reads the road off the lines and the request cannot be told by a
/// field rule.
///
/// **Every line, or none.** That is `ResolveOrderFlow`'s rule: a printed bag beside four وسيط
/// lines is a printed order, and the server takes it with or without a vendor. Requiring one in
/// the app there would refuse an order the server would have accepted; not offering one where
/// every line is a vendor's would send an order the server refuses in Arabic.
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

  test('an empty form needs nothing', () {
    // Arrange - Act
    final answer = vendorRequirementFor(const <Product>[]);

    // Assert
    expect(answer, VendorRequirement.notOffered);
    expect(answer.isOffered, isFalse);
  });

  test('printed and plain goods are not offered a vendor', () {
    // Arrange - Act
    final answer = vendorRequirementFor([
      under(ProductionMode.inHouse),
      under(ProductionMode.none, id: 2),
    ]);

    // Assert
    expect(answer, VendorRequirement.notOffered);
  });

  test('an order made only of وسيط goods requires one', () {
    // Arrange - Act
    final answer = vendorRequirementFor([
      under(ProductionMode.outsourced),
      under(ProductionMode.outsourced, id: 2),
    ]);

    // Assert — the server refuses it otherwise, with «الطلبية الوسيطة تحتاج مورداً».
    expect(answer, VendorRequirement.required);
    expect(answer.isRequired, isTrue);
    expect(answer.isOffered, isTrue);
  });

  test('a mixed order is offered one and not made to name it', () {
    // Arrange — one printed bag puts the whole order on the standard road.
    // Act
    final answer = vendorRequirementFor([
      under(ProductionMode.outsourced),
      under(ProductionMode.inHouse, id: 2),
    ]);

    // Assert
    expect(answer, VendorRequirement.optional);
    expect(answer.isRequired, isFalse);
    expect(answer.isOffered, isTrue);
  });

  test('a product that came without its category reads as printed', () {
    // Arrange — the road that asks more of the shop, and the server's own default.
    // Act
    final answer = vendorRequirementFor([under(null), under(ProductionMode.outsourced, id: 2)]);

    // Assert
    expect(answer, VendorRequirement.optional);
  });
}
