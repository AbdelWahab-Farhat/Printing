import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/production_cost_entry.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';

/// Writing off bags that were spoiled producing a line.
///
/// **This is a stock movement wearing a cost's clothes.** It draws the bags off the order's own
/// warehouse and posts what they cost — read out of the batches they came from, never typed — so
/// it is guarded by `inventory.manage` rather than by any `orders.*` grant, and it moves the
/// warehouse balance rather than the order's totals. The line keeps the cost of what it actually
/// fulfilled.
///
/// **The reason is not optional and is not trimmed away into nothing.** The API asks for three
/// characters and this asks for the same thing one round trip earlier: a scrap row without a
/// sentence is a quantity that vanished off a shelf with nobody to ask about it. A note of pure
/// spaces satisfies a `required` check and tells the next reader as little as an empty one, so it
/// is trimmed here and the server's own refusal is what the person then reads.
class RecordScrapLoss {
  const RecordScrapLoss(this._repository);

  final OrderRepository _repository;

  /// [itemId] is the **order line**, not the product or the variant — the API resolves it inside
  /// [orderId], so a line from a different order is a 404 by construction.
  Future<Either<Failure, ProductionCostEntry>> call(
    int orderId,
    int itemId, {
    required String quantity,
    required String notes,
  }) {
    return _repository.recordScrapLoss(
      orderId,
      itemId,
      // Deliberately the ledger's own cleaner rather than a second copy of it: `٢٥` is what a
      // Libyan keyboard produces, every numeric rule on the server is ASCII-only, and a quantity
      // typed at a counter has exactly the problem an amount typed at the same counter has.
      // **Nothing is parsed to a double** — the string is cleaned and passed on.
      quantity: normaliseAmount(quantity),
      notes: notes.trim(),
    );
  }
}
