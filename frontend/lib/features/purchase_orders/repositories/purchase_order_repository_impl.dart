import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order_counts.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:dio/dio.dart';

/// Fulfils [PurchaseOrderRepository] over HTTP.
///
/// The fact that the API spells the status change `PATCH .../status` and the receipt
/// `POST .../arrivals` never leaves this file.
class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  const PurchaseOrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<PurchaseOrder>>> purchaseOrders({
    int? vendorId,
    int? warehouseId,
    List<String> statuses = const <String>[],
    String? search,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<PurchaseOrder>(
      () => _dio.get(
        PurchaseOrderEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: the list endpoint reads its filters without
          // validating them, and a literal "null" reaching the enum is a 500 rather than an
          // empty page.
          'vendor_id': ?vendorId,
          'warehouse_id': ?warehouseId,
          // A list, sent as `status[]=new&status[]=arrived` by the client's `multiCompatible`
          // format — which is what the server reads a group from. One status travels the same
          // way and is read the same way.
          if (statuses.isNotEmpty) 'status': statuses,
          // Omitted rather than sent blank for the same reason: the server reads an empty
          // `search` as «no term», and saying it explicitly only makes the URL longer.
          'search': ?search,
        },
      ),
      parseItem: PurchaseOrder.fromJson,
    );
  }

  @override
  Future<Either<Failure, PurchaseOrderCounts>> statusCounts({
    int? vendorId,
    String? search,
  }) {
    return safeRequest<PurchaseOrderCounts>(
      () => _dio.get(
        PurchaseOrderEndpoints.summary,
        queryParameters: <String, dynamic>{
          'vendor_id': ?vendorId,
          'search': ?search,
        },
      ),
      parse: (data) =>
          PurchaseOrderCounts.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> purchaseOrder(int purchaseOrderId) {
    return safeRequest<PurchaseOrder>(
      () => _dio.get(PurchaseOrderEndpoints.show(purchaseOrderId)),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> create({
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    List<PurchaseOrderAdditionalCostLine> additionalCosts = const [],
    String? expectedDate,
    String? notes,
  }) {
    return safeRequest<PurchaseOrder>(
      () => _dio.post(
        PurchaseOrderEndpoints.index,
        data: _document(
          vendorId: vendorId,
          warehouseId: warehouseId,
          orderDate: orderDate,
          items: items,
          additionalCosts: additionalCosts,
          expectedDate: expectedDate,
          notes: notes,
        ),
      ),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> update(
    int purchaseOrderId, {
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    List<PurchaseOrderAdditionalCostLine> additionalCosts = const [],
    String? expectedDate,
    String? notes,
  }) {
    return safeRequest<PurchaseOrder>(
      () => _dio.put(
        PurchaseOrderEndpoints.show(purchaseOrderId),
        data: _document(
          vendorId: vendorId,
          warehouseId: warehouseId,
          orderDate: orderDate,
          items: items,
          additionalCosts: additionalCosts,
          expectedDate: expectedDate,
          notes: notes,
        ),
      ),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, PurchaseOrder>> changeStatus(
    int purchaseOrderId, {
    required PurchaseOrderStatus status,
  }) {
    return safeRequest<PurchaseOrder>(
      () => _dio.patch(
        PurchaseOrderEndpoints.status(purchaseOrderId),
        data: <String, dynamic>{'status': status.wire},
      ),
      parse: (data) => PurchaseOrder.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockArrival>> receiveArrival(
    int purchaseOrderId, {
    required List<ReceivedLine> items,
    String? invoiceNumber,
    String? notes,
  }) {
    return safeRequest<StockArrival>(
      () => _dio.post(
        PurchaseOrderEndpoints.arrivals(purchaseOrderId),
        data: <String, dynamic>{
          // Neither the vendor nor the warehouse is sent: both come from the order, and a
          // client that could name them could book stock into the wrong place.
          if (invoiceNumber != null && invoiceNumber.isNotEmpty)
            'invoice_number': invoiceNumber,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': items.map((line) => line.toJson()).toList(growable: false),
        },
      ),
      parse: (data) => StockArrival.fromJson(data as Map<String, dynamic>),
    );
  }

  /// The body create and update share. Written once, because the two differ only in the verb —
  /// and a field added to one and forgotten in the other is a silent half-save.
  Map<String, dynamic> _document({
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    required List<PurchaseOrderAdditionalCostLine> additionalCosts,
    String? expectedDate,
    String? notes,
  }) {
    return <String, dynamic>{
      'vendor_id': vendorId,
      'warehouse_id': warehouseId,
      'order_date': orderDate,
      if (expectedDate != null && expectedDate.isNotEmpty)
        'expected_date': expectedDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items.map((line) => line.toJson()).toList(growable: false),
      // Sent even when empty, unlike the optional dates above. An absent `additional_costs` on a
      // PUT clears the stored set anyway, so leaving it out would say the same thing less
      // clearly — and the form always knows the full current list.
      'additional_costs': additionalCosts
          .map((cost) => cost.toJson())
          .toList(growable: false),
    };
  }
}
