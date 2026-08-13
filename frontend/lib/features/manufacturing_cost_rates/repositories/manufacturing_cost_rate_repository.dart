import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';

/// Reading and curating معدلات تكلفة التصنيع, stated without saying how.
abstract interface class ManufacturingCostRateRepository {
  /// One page of the ladder, in the server's own order: sizes first, then products, then the
  /// defaults. **Never re-sorted here** — that order is the order the costs are resolved in, so
  /// the list read top to bottom *is* the rule.
  ///
  /// Every filter left null asks for everything, which is what a screen for curating the table
  /// wants. [costType] is typed rather than taken as a string because an unrecognised value in
  /// this query string is a 500 on the server, not a 422.
  Future<Either<Failure, Paginated<ManufacturingCostRate>>> rates({
    int? productId,
    int? productVariantId,
    ManufacturingCostType? costType,
    bool? isActive,
    int page,
    int perPage,
  });

  /// One rate. A deleted one answers 404 — the route binding respects the soft delete.
  Future<Either<Failure, ManufacturingCostRate>> rate(int rateId);

  /// Adds a rung to the ladder.
  ///
  /// [productId] and [productVariantId] are the rung, and **at most one of them may be set** —
  /// the table carries a CHECK constraint that refuses a row with both, and the API answers
  /// «لا يمكن تحديد منتج ومقاس منتج معاً — اختر أحدهما». Both null is the default rate.
  Future<Either<Failure, ManufacturingCostRate>> create({
    required ManufacturingCostType costType,
    required String ratePerUnit,
    int? productId,
    int? productVariantId,
    String? notes,
    bool isActive,
  });

  /// Corrects one. **A full replacement, and the trap is what gets left out**: the server fills
  /// every column from the body, so an absent `product_id` demotes a product-wide rate into the
  /// default one, an absent `is_active` re-offers a stopped rate, and absent notes erase them.
  Future<Either<Failure, ManufacturingCostRate>> update(
    int rateId, {
    required ManufacturingCostType costType,
    required String ratePerUnit,
    int? productId,
    int? productVariantId,
    String? notes,
    bool isActive,
  });

  /// Stops a rate applying, or starts it again. The ordinary way to retire one.
  Future<Either<Failure, ManufacturingCostRate>> setActivation(
    int rateId, {
    required bool isActive,
  });

  /// Only for a rung that should never have existed. Nothing points at a rate by key — an
  /// applied one is snapshotted onto the cost entry it produced — so this is never refused, and
  /// the freed (rung, cost type) slot can be filled again straight away.
  ///
  /// Answers with the server's own message, like every other command here.
  Future<Either<Failure, String>> delete(int rateId);
}
