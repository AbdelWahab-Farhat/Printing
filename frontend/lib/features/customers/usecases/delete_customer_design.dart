import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';

/// Takes a design out of the customer's library.
///
/// **The file survives.** The row is soft-deleted and the stored object is left where it is,
/// so an order printed last year can still show what was printed. The person tidying this list
/// has no way of knowing which designs old orders point at, and this is what makes that safe.
class DeleteCustomerDesign {
  const DeleteCustomerDesign(this._repository);

  final CustomerDesignRepository _repository;

  Future<Either<Failure, String>> call(int customerId, int designId) =>
      _repository.remove(customerId, designId);
}
