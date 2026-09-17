import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [OrderRepository] over HTTP.
class OrderRepositoryImpl implements OrderRepository {
  const OrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<CustomerOrder>>> list({
    int page = 1,
    bool openOnly = false,
    String? stage,
  }) {
    return safePaginatedRequest<CustomerOrder>(
      () => _dio.get(
        OrderEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          // Omitted when false rather than sent as `0`: the server treats the key's *absence* as
          // «كل الطلبيات», and sending it explicitly would be asking a different question.
          if (openOnly) 'open': 1,
          'stage': ?stage,
        },
      ),
      parseItem: CustomerOrder.fromJson,
    );
  }

  @override
  Future<Either<Failure, CustomerOrderDetail>> detail(int id) {
    return safeRequest<CustomerOrderDetail>(
      () => _dio.get(OrderEndpoints.order(id)),
      parse: (data) => CustomerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, CustomerOrderDetail>> place(NewOrder order) {
    return safeRequest<CustomerOrderDetail>(
      () => _dio.post(OrderEndpoints.store, data: order.toJson()),
      parse: (data) => CustomerOrderDetail.fromJson(data as Map<String, dynamic>),
    );
  }
}
