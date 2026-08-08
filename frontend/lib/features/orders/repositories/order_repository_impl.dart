// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/orders/models/new_order.dart';
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
    List<String> paymentStatuses = const <String>[],
    int? customerId,
    String? from,
    String? to,
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
          // Repeated, because the API takes a list: the filter sends one status, but a screen
          // opened on a fixed question may carry several.
          if (statuses.isNotEmpty) 'status': statuses,
          // Repeated for the same reason: «أرِني ما لم يُدفع» means unpaid *and* part-paid in
          // practice, and making somebody run the list twice is how a filter goes unused.
          if (paymentStatuses.isNotEmpty) 'payment_status': paymentStatuses,
          // The null-aware element: same meaning as the `if` above it, and the form the
          // analyzer asks for when the condition is only a null check.
          'customer_id': ?customerId,
          // Plain days. The server turns each into the instants that day starts and ends *in
          // the shop's timezone*, which is why this sends a date and not a timestamp: a
          // boundary computed here would be computed in the phone's zone.
          'from': ?from,
          'to': ?to,
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
  Future<Either<Failure, Order>> create(NewOrder order) {
    return safeRequest<Order>(
      // `toJson` rather than a Map literal assembled here: the body nests the lines, and a
      // twenty-line literal reachable only through Dio is a shape no test can reach. As a model
      // it is a pure function — see `take_order_wire_test.dart`.
      () => _dio.post(OrderEndpoints.index, data: order.toJson()),
      parse: (data) => Order.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Order>> updateInvoice(
    int orderId, {
    List<InvoiceLineUpdate>? lines,
    String? discount,
    int? cityId,
    int? regionId,
    ({String? number})? recipientPhone,
  }) async {
    // `PUT` replaces the whole order, so the fields this screen does not touch have to be sent
    // back as they are — omitting `city_id` would be an instruction to clear the destination.
    // Read first rather than trusting a copy the screen has been holding: the order may have
    // moved while it was open, and the write should carry the current address, not a stale one.
    final current = await order(orderId);

    return current.fold(Left.new, (order) {
      // A move to a city whose regions are different: the old region belongs to the old city
      // and sending it on would be refused, correctly, as a region from somewhere else.
      final movedCity = cityId != null && cityId != order.cityId;
      final region = movedCity ? regionId : (regionId ?? order.regionId);

      return safeRequest<Order>(
        () => _dio.put(
          OrderEndpoints.show(orderId),
          data: <String, dynamic>{
            'city_id': cityId ?? order.cityId,
            'region_id': ?region,
            'customer_shop_id': ?order.customerShopId,
            'design_source': order.designSource,
            'recipient_name': ?order.recipientName,
            // Absent means "leave it alone", so the order's own number goes back unchanged;
            // a record carrying null clears it, which the API reads from the key being missing.
            'recipient_phone': ?(recipientPhone == null
                ? order.recipientPhone
                : recipientPhone.number),
            'address_details': ?order.addressDetails,
            'notes': ?order.notes,
            'design_fee': order.designFee,
            'discount': discount ?? order.discount,
            'tracking_number': ?order.trackingNumber,
            // Omitted entirely when this edit is not about the lines: `items` is the one field
            // whose absence means "leave them alone" rather than "clear them", which is what
            // lets an address be corrected on an order whose lines are already closed.
            if (lines != null) 'items': lines.map((line) => line.toJson()).toList(growable: false),
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
  Future<Either<Failure, void>> addDesign(int orderId, {required int customerDesignId}) {
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
