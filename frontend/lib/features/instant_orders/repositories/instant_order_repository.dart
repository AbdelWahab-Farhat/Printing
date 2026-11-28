// dartz exports an `Order` of its own; hidden so the model keeps its name.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/instant_orders/models/instant_models.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dio/dio.dart';

/// «الطلبات الفورية» over HTTP — INSTANT-ORDERS-PLAN.md.
///
/// Moving an instant order after it is taken (handover, cancel) goes through the ordinary status
/// screen and its repository; this one only takes and edits.
abstract interface class InstantOrderRepository {
  Future<Either<Failure, List<SellingBranch>>> branches();

  /// The customer this phone belongs to, or null — any spelling of the number.
  Future<Either<Failure, FoundCustomer?>> findCustomer(String phone);

  Future<Either<Failure, InstantCatalogue>> products(int branchId);

  Future<Either<Failure, InstantOrderResult>> create({
    required String clientToken,
    required int branchId,
    required String phone,
    required String name,
    required int? cityId,
    required int? regionId,
    required List<InstantLine> lines,
    required int discount,
    required String? notes,
  });

  Future<Either<Failure, Order>> update(
    int orderId, {
    required List<InstantLine> lines,
    required int discount,
    required String? notes,
  });
}

class InstantOrderRepositoryImpl implements InstantOrderRepository {
  const InstantOrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<SellingBranch>>> branches() {
    return safeRequest<List<SellingBranch>>(
      () => _dio.get(InstantOrderEndpoints.branches),
      parse: (data) => [
        for (final row in data as List<dynamic>) SellingBranch.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<Either<Failure, FoundCustomer?>> findCustomer(String phone) {
    return safeRequest<FoundCustomer?>(
      () => _dio.get(InstantOrderEndpoints.customer, queryParameters: {'phone': phone}),
      parse: (data) {
        final body = data as Map<String, dynamic>;
        final customer = body['customer'];

        return body['found'] == true && customer is Map<String, dynamic>
            ? FoundCustomer.fromJson(customer)
            : null;
      },
    );
  }

  @override
  Future<Either<Failure, InstantCatalogue>> products(int branchId) {
    return safeMetaRequest<InstantCatalogue>(
      () => _dio.get(InstantOrderEndpoints.products, queryParameters: {'branch_id': branchId}),
      parse: (data, meta) => InstantCatalogue(
        products: [
          for (final row in data as List<dynamic>) InstantProduct.fromJson(row as Map<String, dynamic>),
        ],
        warehouseName: meta['warehouse_name'] as String?,
      ),
    );
  }

  @override
  Future<Either<Failure, InstantOrderResult>> create({
    required String clientToken,
    required int branchId,
    required String phone,
    required String name,
    required int? cityId,
    required int? regionId,
    required List<InstantLine> lines,
    required int discount,
    required String? notes,
  }) {
    return safeMetaRequest<InstantOrderResult>(
      () => _dio.post(
        InstantOrderEndpoints.store,
        data: <String, dynamic>{
          // The same token on a retry, so a tap that timed out is never two sales.
          'client_token': clientToken,
          'branch_id': branchId,
          'customer': <String, dynamic>{
            'phone': phone,
            'name': name,
            'city_id': ?cityId,
            'region_id': ?regionId,
          },
          'items': [for (final line in lines) line.toJson()],
          if (discount > 0) 'discount': discount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data, meta) => InstantOrderResult(
        order: Order.fromJson(data as Map<String, dynamic>),
        customerNotice: meta['customer_notice'] as String?,
      ),
    );
  }

  @override
  Future<Either<Failure, Order>> update(
    int orderId, {
    required List<InstantLine> lines,
    required int discount,
    required String? notes,
  }) {
    return safeRequest<Order>(
      () => _dio.put(
        InstantOrderEndpoints.update(orderId),
        data: <String, dynamic>{
          'items': [for (final line in lines) line.toJson()],
          'discount': discount,
          'notes': notes,
        },
      ),
      parse: (data) => Order.fromJson(data as Map<String, dynamic>),
    );
  }
}
