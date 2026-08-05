// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// One page of the orders list.
class GetOrders {
  const GetOrders(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Paginated<Order>>> call({
    String? search,
    List<String> statuses = const <String>[],
    int? customerId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.orders(
      search: search,
      statuses: statuses,
      customerId: customerId,
      from: from,
      to: to,
      page: page,
      perPage: perPage,
    );
  }
}
