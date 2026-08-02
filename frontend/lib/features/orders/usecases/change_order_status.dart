// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// Moving an order through the workshop.
///
/// **The rules are not re-stated here, on purpose.** Which moves are legal, which need a reason
/// and which the signed-in user may make are all decided on the server and arrive with the order
/// as `available_transitions`. A copy of that map in the app would be a second source of truth
/// that nothing keeps honest — and the one that drifts is always the one guarding the button.
///
/// What this class does own is the trimming: a reason of spaces is no reason, and sending one
/// would satisfy a required-field check while telling the next reader nothing.
class ChangeOrderStatus {
  const ChangeOrderStatus(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(
    int orderId, {
    required OrderStatus status,
    String? reason,
  }) {
    final trimmed = reason?.trim();

    return _repository.changeStatus(
      orderId,
      status: status,
      reason: trimmed != null && trimmed.isNotEmpty ? trimmed : null,
    );
  }
}
