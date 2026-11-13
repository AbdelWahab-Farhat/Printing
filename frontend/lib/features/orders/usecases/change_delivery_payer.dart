// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/delivery_payer_change.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «التوصيل على: المستلم / علينا» on an order already taken. Docs/orders/DELIVERY-PAYER.md.
///
/// [paidBy] is `recipient` or `us`. When we pay, the fee becomes the order's own cost and its
/// profit is worked out again on the server; when a Nawris parcel is out, Nawris is told.
class ChangeDeliveryPayer {
  const ChangeDeliveryPayer(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, DeliveryPayerChange>> call(int orderId, {required String paidBy}) =>
      _repository.changeDeliveryPayer(orderId, paidBy: paidBy);
}
