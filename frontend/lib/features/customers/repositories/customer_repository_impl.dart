import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';

/// Fulfils [CustomerRepository] over HTTP.
///
/// The Dio calls live here rather than in a separate data source: with one source of data the
/// extra class only forwarded. The request body is assembled here too, so the fact that the API
/// spells the field `is_active` never leaves this file.
class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<Customer>>> customers({
    String? search,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<Customer>(
      () => _dio.get(
        CustomerEndpoints.index,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null" and the API would filter on it.
          if (search != null && search.isNotEmpty) 'search': search,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
      ),
      parseItem: Customer.fromJson,
    );
  }

  @override
  Future<Either<Failure, Customer>> create({
    required String name,
    required String phone,
  }) {
    return safeRequest<Customer>(
      () => _dio.post(
        CustomerEndpoints.index,
        data: <String, dynamic>{'name': name, 'phone': phone},
      ),
      parse: (data) => Customer.fromJson(data as Map<String, dynamic>),
    );
  }
}
