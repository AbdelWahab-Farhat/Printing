import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';

/// One customer, with their shops.
///
/// Fetched rather than taken from the list the user tapped: the list carries no shops at all,
/// and a phone number read off a row loaded ten minutes ago is one somebody may have corrected
/// since.
class GetCustomer {
  const GetCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Customer>> call(int customerId) => _repository.customer(customerId);
}
