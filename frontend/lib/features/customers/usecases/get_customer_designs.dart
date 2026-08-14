import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/repositories/customer_design_repository.dart';

/// Everything a customer has had printed, newest first.
class GetCustomerDesigns {
  const GetCustomerDesigns(this._repository);

  final CustomerDesignRepository _repository;

  Future<Either<Failure, List<CustomerDesign>>> call(int customerId) =>
      _repository.designs(customerId);
}
