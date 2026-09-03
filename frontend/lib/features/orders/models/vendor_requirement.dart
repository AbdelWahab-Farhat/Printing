import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/production_mode.dart';

/// Whether the order being taken has to name who will make it.
///
/// **The server's rule, mirrored rather than invented.** `ResolveOrderFlow` puts an order on the
/// وسيط road when **every** line is outsourced, and `CreateOrder` then refuses one without a
/// vendor — «الطلبية الوسيطة تحتاج مورداً». A printed line beside four وسيط ones is a printed
/// order: the press really does have to run, the road is the standard one, and a vendor is
/// merely accepted. So the form *requires* the picker only where the server would, and *offers*
/// it wherever a vendor is plausibly involved — requiring it on a mixed order would refuse an
/// order the server would have taken.
///
/// Read off the products the lines were picked from: `product_category.production_mode` on a
/// product is the *effective* mode, a parent's answer already applied. See
/// OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md §6.
enum VendorRequirement {
  /// No line is a vendor's work — the row is not drawn at all.
  notOffered,

  /// Some lines are, some are not. Drawn, and left open: the server accepts an id on any order.
  optional,

  /// Every line is — the road is the vendor's, and the server refuses the order without one.
  required;

  bool get isOffered => this != VendorRequirement.notOffered;

  bool get isRequired => this == VendorRequirement.required;
}

/// «هل تحتاج هذه الطلبية مورداً؟», answered from the products on its lines.
///
/// An empty form has no lines to read, so it needs nothing; the unknown case — a product whose
/// category did not come with the payload — reads as not outsourced, which is the road that asks
/// *more* of the shop and the same default the server takes.
VendorRequirement vendorRequirementFor(Iterable<Product> products) {
  final modes = [
    for (final product in products)
      product.productCategory?.productionMode ?? ProductionMode.inHouse,
  ];

  if (modes.isEmpty || modes.none((mode) => mode.needsAVendor)) {
    return VendorRequirement.notOffered;
  }

  return modes.every((mode) => mode.needsAVendor)
      ? VendorRequirement.required
      : VendorRequirement.optional;
}

extension on List<ProductionMode> {
  bool none(bool Function(ProductionMode mode) test) => !any(test);
}
