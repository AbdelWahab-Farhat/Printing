import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/production_mode.dart';

/// Whether the order being taken has to name who will make it.
///
/// **The server's rule, mirrored rather than invented.** `ResolveOrderFlow` puts an order on the
/// وسيط road when **every** line is outsourced, and `CreateOrder` then refuses one without a
/// vendor — «الطلبية الوسيطة تحتاج مورداً». A وسيط line beside one of ours is refused outright
/// (see `one_bench.dart`), so [VendorRequirement.optional] only ever describes a form mid-edit,
/// on its way to one bench or the other; the row stays drawn then so a vendor already chosen is
/// not thrown away while the clerk removes the line that does not belong.
///
/// Read off the products the lines were picked from: `product_category.production_mode` on a
/// product is the *effective* mode, a parent's answer already applied. See
/// OUTSOURCED-PRODUCTS-FRONTEND-INTEGRATION.md §6.
enum VendorRequirement {
  /// No line is a vendor's work — the row is not drawn at all.
  notOffered,

  /// Some lines are, some are not — a mix the form refuses to submit. Drawn, and left open.
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
