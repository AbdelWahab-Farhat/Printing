import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/api_endpoints.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/customers_filter.dart';
import 'package:printing/features/customers/models/new_customer.dart';
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
    bool? hasOrders,
    CustomersSort sort = CustomersSort.newest,
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
          if (hasOrders != null) 'has_orders': hasOrders ? 1 : 0,
          // The default is left out rather than spelled: `sort=newest` and no `sort` are the
          // same request, and the shorter one is the one somebody reads in a log.
          if (sort != CustomersSort.newest) 'sort': sort.wire,
        },
      ),
      parseItem: Customer.fromJson,
    );
  }

  @override
  Future<Either<Failure, Customer>> create(NewCustomer customer) {
    return safeRequest<Customer>(
      // `toJson` rather than a Map literal assembled here: the body nests shops inside the
      // customer, and a literal reachable only through Dio is a shape no test can reach. As a
      // model it is a pure function.
      () => _dio.post(CustomerEndpoints.index, data: customer.toJson()),
      parse: (data) => Customer.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Customer>> customer(int customerId) {
    return safeRequest<Customer>(
      () => _dio.get(CustomerEndpoints.show(customerId)),
      parse: (data) => Customer.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Customer>> update(int customerId, NewCustomer customer) {
    return safeRequest<Customer>(
      () => _dio.put(CustomerEndpoints.show(customerId), data: customer.toJson()),
      parse: (data) => Customer.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Customer>> setActivation(int customerId, {required bool isActive}) {
    return safeRequest<Customer>(
      () => _dio.patch(
        CustomerEndpoints.activation(customerId),
        data: <String, dynamic>{'is_active': isActive},
      ),
      parse: (data) => Customer.fromJson(data as Map<String, dynamic>),
    );
  }
}
