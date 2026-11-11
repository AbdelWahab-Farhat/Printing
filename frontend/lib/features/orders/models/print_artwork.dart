import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/production_mode.dart';

/// Whether an order made of these products goes through our press.
///
/// **The server's rule, mirrored** (`ResolveOrderFlow`, `Order::isPrintedHere()`): an order is
/// off the standard road only when every line is plain («سادة») or every line is a vendor's
/// («وسيط»). A product with no heading counts as printed, as it does there. An empty order
/// prints nothing yet.
bool linesPrintHere(Iterable<Product> products) {
  if (products.isEmpty) return false;

  final modes = [
    for (final product in products)
      product.productCategory?.productionMode ?? ProductionMode.inHouse,
  ];

  return !modes.every((mode) => mode == ProductionMode.none) &&
      !modes.every((mode) => mode == ProductionMode.outsourced);
}

/// Whether the artwork is what a print order needs before it may be taken (PRINT-COLORS.md §9):
/// a design, each with complete colours. An order we are drawing ourselves ([drawnInHouse]) may
/// wait for its design, because the colours are asked for on the design ticket instead. Mirrors
/// `GuardPrintColors::forIntake()`.
///
/// [designColors] is the colour list each chosen design will carry, in any order.
bool printArtworkIsReady({
  required bool printsHere,
  required bool drawnInHouse,
  required List<List<PrintColor>> designColors,
}) {
  if (!printsHere) return true;
  if (designColors.isEmpty) return drawnInHouse;

  return designColors.every(PrintColor.listIsComplete);
}
