// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «طلبية تعويض» on an order already taken. Docs/orders/ORDER-COMPENSATION.md.
///
/// On, the customer owes nothing and the goods' cost is reported as a compensation loss; off,
/// the order is billed again. Words typed under the reason are trimmed, and an empty box sends
/// nothing.
class ChangeOrderCompensation {
  const ChangeOrderCompensation(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(
    int orderId, {
    required bool isCompensation,
    String? reason,
    String? note,
    int? originalId,
  }) {
    final words = note?.trim();

    return _repository.changeCompensation(
      orderId,
      isCompensation: isCompensation,
      reason: reason,
      note: words == null || words.isEmpty ? null : words,
      originalId: originalId,
    );
  }
}
