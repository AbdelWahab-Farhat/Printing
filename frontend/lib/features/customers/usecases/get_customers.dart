import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';

/// One page of customers.
class GetCustomers {
  const GetCustomers(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Paginated<Customer>>> call({
    String? search,
    bool? isActive,
    bool? hasOrders,
    CustomersSort sort = CustomersSort.newest,
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.customers(
      // Trimmed here rather than in the Cubit: a phone number pasted with a trailing space is a
      // search that silently finds nobody, and every caller would otherwise have to remember it.
      search: search?.trim(),
      isActive: isActive,
      hasOrders: hasOrders,
      sort: sort,
      page: page,
      perPage: perPage,
    );
  }
}
