import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';

/// Stops selling to a customer, or starts again.
///
/// **There is no delete, and there will not be one.** A customer's orders point at their row,
/// so removing it would leave a history that cannot say who an order was for. Deactivating
/// keeps every record and only takes them out of the active list.
class SetCustomerActivation {
  const SetCustomerActivation(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Customer>> call(int customerId, {required bool isActive}) =>
      _repository.setActivation(customerId, isActive: isActive);
}
