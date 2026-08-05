import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// How many orders sit in each status, for the numbers beside the filter.
class GetOrderCounts {
  const GetOrderCounts(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, OrderCounts>> call({String? search, int? customerId}) =>
      _repository.statusCounts(search: search, customerId: customerId);
}
