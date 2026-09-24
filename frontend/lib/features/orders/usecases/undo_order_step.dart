// dartz exports an `Order` of its own — hidden, as in `reinstate_order.dart`.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Taking a settled order back to «تم الاستلام».
///
/// Not a status change, for the reason [ReinstateOrder] gives: «تم التسوية» is final on the
/// server's map, and this is the undo of one recorded move with a fixed destination. The reason
/// is required — the dialog will not submit without one — and trimmed here like every note.
class UnsettleOrder {
  const UnsettleOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {required String reason}) =>
      _repository.unsettle(orderId, reason: reason.trim());
}

/// Taking back a delivery recorded by mistake.
///
/// No destination to pass: the server reads where the order was delivered from and puts it back
/// there — `undoDeliveryTo` on the order names it beforehand. The reason is required.
class UndoOrderDelivery {
  const UndoOrderDelivery(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {required String reason}) =>
      _repository.undoDelivery(orderId, reason: reason.trim());
}
