// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «وصل العربون» — an employee confirming the money the order was parked for actually landed.
///
/// **Two people, deliberately.** Whoever moved the order to «عربون مدفوع» made a claim on the
/// customer's word so the work could start; this is somebody else saying the shop has seen it.
/// The server enforces the second person, and folds that rule together with the grant into
/// `Order.canConfirmDeposit` — which is what the switch is gated on, never the permission alone.
///
/// [received] `false` takes a confirmation back. Both directions are one call because they are
/// one decision made twice — the second time to correct a stray tap — and the order keeps both
/// stamps.
///
/// **It gates nothing downstream.** An order whose deposit is unconfirmed prints, ships and
/// settles exactly like one whose deposit is confirmed; the flag feeds a queue, not a lock.
class ConfirmDepositReceipt {
  const ConfirmDepositReceipt(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {required bool received}) =>
      _repository.confirmDepositReceipt(orderId, received: received);
}
