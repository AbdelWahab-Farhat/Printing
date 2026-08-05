import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';

/// Fulfils [BusinessFieldRepository] over HTTP.
class BusinessFieldRepositoryImpl implements BusinessFieldRepository {
  const BusinessFieldRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<BusinessField>>> fields({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<BusinessField>(
      () => _dio.get(
        BusinessFieldEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: BusinessField.fromJson,
    );
  }

  @override
  Future<Either<Failure, BusinessField>> create({
    required String name,
    required int sortOrder,
  }) {
    return safeRequest<BusinessField>(
      () => _dio.post(
        BusinessFieldEndpoints.index,
        data: <String, dynamic>{'name': name, 'sort_order': sortOrder},
      ),
      parse: (data) => BusinessField.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, BusinessField>> update(
    int fieldId, {
    required String name,
    required int sortOrder,
    required bool isActive,
  }) {
    return safeRequest<BusinessField>(
      // A PUT sends the field's whole representation, which is why `is_active` is here and not
      // only on the activation endpoint: leaving it out of a full replacement would silently
      // re-offer a stopped field on every rename.
      () => _dio.put(
        BusinessFieldEndpoints.show(fieldId),
        data: <String, dynamic>{'name': name, 'sort_order': sortOrder, 'is_active': isActive},
      ),
      parse: (data) => BusinessField.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, BusinessField>> setActivation(int fieldId, {required bool isActive}) {
    return safeRequest<BusinessField>(
      () => _dio.patch(
        BusinessFieldEndpoints.activation(fieldId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => BusinessField.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> delete(int fieldId) {
    return safeCommand(() => _dio.delete(BusinessFieldEndpoints.show(fieldId)));
  }
}
