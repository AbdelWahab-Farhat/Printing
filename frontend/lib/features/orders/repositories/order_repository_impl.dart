// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_counts.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';

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
  Future<Either<Failure, OrderCounts>> statusCounts({String? search, int? customerId}) {
    return safeRequest<OrderCounts>(
      () => _dio.get(
        OrderEndpoints.summary,
        queryParameters: <String, dynamic>{
          if (search != null && search.isNotEmpty) 'search': search,
          'customer_id': ?customerId,
        },
      ),
      parse: (data) => OrderCounts.fromJson(data as Map<String, dynamic>),
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
  Future<Either<Failure, Order>> updateInvoice(
    int orderId, {
    required List<InvoiceLineUpdate> lines,
    required String discount,
  }) async {
    // `PUT` replaces the whole order, so the fields the sheet does not touch have to be sent
    // back as they are — omitting `city_id` would be an instruction to clear the destination.
    // Read first rather than trusting a copy the sheet has been holding: the order may have
    // moved while it was open, and the write should carry the current address, not a stale one.
    final current = await order(orderId);

    return current.fold(Left.new, (order) {
      return safeRequest<Order>(
        () => _dio.put(
          OrderEndpoints.show(orderId),
          data: <String, dynamic>{
            'city_id': order.cityId,
            'region_id': ?order.regionId,
            'customer_shop_id': ?order.customerShopId,
            'design_source': order.designSource,
            'recipient_name': ?order.recipientName,
            'recipient_phone': ?order.recipientPhone,
            'address_details': ?order.addressDetails,
            'notes': ?order.notes,
            'design_fee': order.designFee,
            'discount': discount,
            'shipping_company': ?order.shippingCompany,
            'tracking_number': ?order.trackingNumber,
            'courier_name': ?order.courierName,
            'items': lines.map((line) => line.toJson()).toList(growable: false),
          },
        ),
        parse: (data) => Order.fromJson(data as Map<String, dynamic>),
      );
    });
  }

  @override
  Future<Either<Failure, Order>> changeStatus(
    int orderId, {
    required OrderStatus status,
    String? reason,
    Map<String, Object?> fields = const {},
  }) {
    return safeRequest<Order>(
      () => _dio.post(
        OrderEndpoints.status(orderId),
        data: <String, dynamic>{
          'status': status.wire,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          // Sent as the transition described them and no other way. An empty bag is left out
          // rather than sent as `{}`, so a move that asks for nothing looks exactly as it did
          // before any of this existed.
          if (fields.isNotEmpty) 'fields': fields,
        },
      ),
      parse: (data) => Order.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, void>> addDesign(
    int orderId, {
    required int customerDesignId,
  }) {
    // The response is the version, not the order — and the screen wants the order, whose
    // `available_transitions` may have changed with it. So nothing is parsed here and the
    // caller re-reads.
    return safeRequest<void>(
      () => _dio.post(
        OrderEndpoints.designs(orderId),
        data: <String, dynamic>{'customer_design_id': customerDesignId},
      ),
      parse: (_) {},
    );
  }

  @override
  Future<Either<Failure, void>> reviewDesign(
    int orderId,
    int designId, {
    required bool isApproved,
    String? rejectionReason,
  }) {
    return safeRequest<void>(
      () => _dio.post(
        OrderEndpoints.reviewDesign(orderId, designId),
        data: <String, dynamic>{
          'status': isApproved ? 'approved' : 'rejected',
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejection_reason': rejectionReason,
        },
      ),
      parse: (_) {},
    );
  }
}
