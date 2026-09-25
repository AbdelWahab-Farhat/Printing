import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// One order, opened.
class GetOrder {
  const GetOrder(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, CustomerOrderDetail>> call(int id) => _repository.detail(id);
}
