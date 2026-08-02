// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';

/// Fulfils [OrderRepository] over HTTP.
///
/// The fact that the API spells the filter `status[]` and the body key `reason` never leaves
/// this file.
class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Order>>> orders({
    String? search,
    List<String> statuses = const <String>[],
    int? customerId,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Order>(
      () => _dio.get(
        OrderEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string becomes the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          // Repeated, because a queue is several statuses at once — «رواجع» is three.
          if (statuses.isNotEmpty) 'status': statuses,
          // The null-aware element: same meaning as the `if` above it, and the form the
          // analyzer asks for when the condition is only a null check.
          'customer_id': ?customerId,
        },
      ),
      parseItem: Order.fromJson,
    );
  }

  @override
  Future<Either<Failure, Order>> order(int orderId) {
    return safeRequest<Order>(
      () => _dio.get(OrderEndpoints.show(orderId)),
      parse: (data) => Order.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Order>> changeStatus(
    int orderId, {
    required OrderStatus status,
    String? reason,
  }) {
    return safeRequest<Order>(
      () => _dio.post(
        OrderEndpoints.status(orderId),
        data: <String, dynamic>{
          'status': status.wire,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      ),
      parse: (data) => Order.fromJson(data as Map<String, dynamic>),
    );
  }
}
