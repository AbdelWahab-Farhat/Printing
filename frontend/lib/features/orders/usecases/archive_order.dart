/// Moving an order to الأرشيف, and taking it back out.
///
/// **Two classes in one file because they are one decision read from both ends** — the same
/// arrangement `manage_order_designs.dart` uses. Whether a business grants both, one, or
/// neither is a role question, and the two permissions behind them are separate for exactly
/// that reason; but nobody can understand the delete without the restore, because the restore
/// is what makes the delete recoverable and what makes it *cost* something.
library;

// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Archives an order: it leaves every list but الأرشيف, and its stock goes back on the shelf.
///
/// **Deliberately not «إلغاء تام», and the difference is the whole first section of the design
/// note.** A cancellation records that the job happened and ended without a delivery — a real
/// business event, with a reason, that stays in the lists. A delete says the row should never
/// have been written: a duplicate, a wrong number, a test. Which is why the undo of one leaves
/// the warehouse alone and the undo of the other does not.
///
/// **The refusals are the server's and are shown as sent.** Money already taken, and an open
/// parcel at Nawris, are both refused by name and both name what to do first — reverse the
/// entries, or release the shipment. Re-deriving either here would be this app guessing at a
/// ledger it does not hold and at a parcel only the carrier can close.
class DeleteOrder {
  const DeleteOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId) => _repository.deleteOrder(orderId);
}

/// Puts an archived order back in the shop — **with its stock drawn again.**
///
/// That second half is the reason this is not `ReinstateOrder` and the reason the confirmation
/// exists at all. Restoring claims the order was always real, so it has to come back the way it
/// left: goods off the shelf. And the new deduction eats today's cost layers rather than the
/// ones it originally consumed, so the same order returns having cost something else. The
/// server says that in `stock_effect.note`; the dialog shows the sentence rather than composing
/// one, so it cannot drift from what the action does.
class RestoreOrder {
  const RestoreOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId) => _repository.restoreOrder(orderId);
}
