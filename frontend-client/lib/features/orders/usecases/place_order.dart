import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// Send an order to the shop.
///
/// **What comes back is «بانتظار المراجعة».** Nothing has been confirmed and nothing has been
/// priced against stock yet — a person reads it first. The screen after this one says so; it
/// must not congratulate the customer on an order the shop has not accepted.
class PlaceOrder {
  const PlaceOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, CustomerOrderDetail>> call(NewOrder order) =>
      _repository.place(order);
}
