// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Undoing a cancellation that was a mistake.
///
/// **It is not a status change, and it deliberately does not go through [ChangeOrderStatus].**
/// «إلغاء تام» is the end of the road on the server's own map — nothing follows it, which is
/// exactly why the order screen says «لا مزيد من الإجراءات» and why the move screen has no
/// button to offer. What this asks for is the undo of one recorded move: the server reads the
/// order's timeline, finds the status it was cancelled from, and puts it back there.
///
/// **So there is no destination to pass**, and the class takes none. Where the order lands is
/// on the order itself as `reinstateTo`, so the button can name it beforehand.
///
/// What this class owns is the same trimming [ChangeOrderStatus] owns: a note of spaces is no
/// note, and sending one would fill the timeline's reason column with nothing.
class ReinstateOrder {
  const ReinstateOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {String? reason}) {
    final trimmed = reason?.trim();

    return _repository.reinstate(
      orderId,
      reason: trimmed != null && trimmed.isNotEmpty ? trimmed : null,
    );
  }
}
