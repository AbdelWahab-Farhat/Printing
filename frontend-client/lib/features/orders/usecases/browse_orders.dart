import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// One page of «طلباتي».
class BrowseOrders {
  const BrowseOrders(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Paginated<CustomerOrder>>> call({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) => _repository.list(page: page, openOnly: openOnly, stage: stage);
}
