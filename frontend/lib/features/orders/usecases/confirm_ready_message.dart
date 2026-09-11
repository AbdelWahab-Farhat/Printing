// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «تم إرسال رسالة الجاهزية للزبون» — an employee saying they told the customer.
///
/// **The one thing this app records that it cannot observe.** The message goes out on WhatsApp
/// or by telephone, on somebody's own phone, so there is no event to listen for and nothing to
/// derive: the tick *is* the record, and the server stamps who put it there and when.
///
/// [sent] `false` takes an earlier confirmation back. Both directions are one call because they
/// are one decision made twice — the second time to correct a stray tap — and the order's
/// history keeps both.
class ConfirmReadyMessage {
  const ConfirmReadyMessage(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {required bool sent}) =>
      _repository.confirmReadyMessage(orderId, sent: sent);
}
