// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// One order, with its lines, its designs and its whole timeline.
class GetOrder {
  const GetOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId) => _repository.order(orderId);
}
