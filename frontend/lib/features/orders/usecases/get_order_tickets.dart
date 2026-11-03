import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order_ticket.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «التذاكر المرتبطة» بطلبية — الأنواع الثلاثة، المفتوحةُ أولاً.
class GetOrderTickets {
  const GetOrderTickets(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, List<OrderTicket>>> call(int orderId) =>
      _repository.orderTickets(orderId);
}
