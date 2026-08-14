import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [VendorRepository] over HTTP.
class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Vendor>>> vendors({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Vendor>(
      () => _dio.get(
        VendorEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          // The server reads `0`/`1`; omitting it asks for both.
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: Vendor.fromJson,
    );
  }

  @override
  Future<Either<Failure, Vendor>> show(int vendorId) {
    return safeRequest<Vendor>(
      () => _dio.get(VendorEndpoints.show(vendorId)),
      parse: (data) => Vendor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Vendor>> create({
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  }) {
    return safeRequest<Vendor>(
      () => _dio.post(
        VendorEndpoints.index,
        data: _details(
          name: name,
          phone: phone,
          contactPerson: contactPerson,
          email: email,
          address: address,
        ),
      ),
      parse: (data) => Vendor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Vendor>> update(
    int vendorId, {
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  }) {
    return safeRequest<Vendor>(
      () => _dio.put(
        VendorEndpoints.show(vendorId),
        data: _details(
          name: name,
          phone: phone,
          contactPerson: contactPerson,
          email: email,
          address: address,
        ),
      ),
      parse: (data) => Vendor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Vendor>> setActive(int vendorId, bool isActive) {
    return safeRequest<Vendor>(
      () => _dio.patch(
        VendorEndpoints.activation(vendorId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => Vendor.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Paginated<StockArrival>>> stockArrivals({
    int? vendorId,
    int? warehouseId,
    String? from,
    String? to,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<StockArrival>(
      () => _dio.get(
        StockArrivalEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // The null-aware element: same meaning as an `if` on each, and the form the analyzer
          // asks for when the condition is only a null check.
          'vendor_id': ?vendorId,
          'warehouse_id': ?warehouseId,
          // Plain days. The server turns each into the instants that day starts and ends in the
          // shop's timezone, which is why this sends a date and not a timestamp.
          'from': ?from,
          'to': ?to,
        },
      ),
      parseItem: StockArrival.fromJson,
    );
  }

  @override
  Future<Either<Failure, StockArrival>> stockArrival(int stockArrivalId) {
    return safeRequest<StockArrival>(
      () => _dio.get(StockArrivalEndpoints.show(stockArrivalId)),
      parse: (data) => StockArrival.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, StockArrival>> recordStockArrival({
    required int vendorId,
    required int warehouseId,
    required List<StockArrivalLine> items,
    String? invoiceNumber,
    String? notes,
  }) {
    return safeRequest<StockArrival>(
      () => _dio.post(
        StockArrivalEndpoints.index,
        data: <String, dynamic>{
          'vendor_id': vendorId,
          'warehouse_id': warehouseId,
          'items': items.map((item) => item.toJson()).toList(growable: false),
          if (invoiceNumber != null && invoiceNumber.isNotEmpty)
            'invoice_number': invoiceNumber,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      ),
      parse: (data) => StockArrival.fromJson(data as Map<String, dynamic>),
    );
  }

  /// The vendor's details, shared by create and update.
  ///
  /// **`is_active` is deliberately absent**, and the nullable fields are sent as explicit nulls
  /// rather than omitted: this is a full replacement, so a cleared email has to arrive as a
  /// cleared email. The flag is the one thing that must *not* be replaced by silence — see
  /// [VendorRepository.setActive].
  Map<String, dynamic> _details({
    required String name,
    required String phone,
    required String? contactPerson,
    required String? email,
    required String? address,
  }) {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'contact_person': contactPerson,
      'email': email,
      'address': address,
    };
  }
}
