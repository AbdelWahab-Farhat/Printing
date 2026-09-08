import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [ShippingCompanyRepository] over HTTP.
class ShippingCompanyRepositoryImpl implements ShippingCompanyRepository {
  const ShippingCompanyRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<ShippingCompany>>> companies({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<ShippingCompany>(
      () => _dio.get(
        ShippingCompanyEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string becomes the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: ShippingCompany.fromJson,
    );
  }

  @override
  Future<Either<Failure, ShippingCompany>> create({
    required String name,
    String? phone,
    String? notes,
    bool isActive = true,
    bool? isDefault,
  }) {
    return safeRequest<ShippingCompany>(
      () => _dio.post(
        ShippingCompanyEndpoints.index,
        data: _body(name, phone, notes, isActive, isDefault),
      ),
      parse: (data) => ShippingCompany.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, ShippingCompany>> update(
    int id, {
    required String name,
    String? phone,
    String? notes,
    bool isActive = true,
    bool? isDefault,
  }) {
    return safeRequest<ShippingCompany>(
      () => _dio.put(
        ShippingCompanyEndpoints.show(id),
        data: _body(name, phone, notes, isActive, isDefault),
      ),
      parse: (data) => ShippingCompany.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int id) {
    return safeCommand(() => _dio.delete(ShippingCompanyEndpoints.show(id)));
  }

  /// The whole record either way: the endpoint replaces rather than patches, so a field left
  /// out clears it — which is why nulls are sent rather than omitted.
  ///
  /// **`is_default` is the one key that is omitted rather than nulled**, and only when the
  /// caller said nothing about it. It is a fact about the list rather than about this row —
  /// switching it on takes it off another company — so the endpoint reads its absence as
  /// «اتركها كما هي», and a null would be an answer where silence was meant.
  Map<String, dynamic> _body(
    String name,
    String? phone,
    String? notes,
    bool isActive,
    bool? isDefault,
  ) {
    return <String, dynamic>{
      'name': name,
      'phone': phone,
      'notes': notes,
      'is_active': isActive,
      'is_default': ?isDefault,
    };
  }
}
