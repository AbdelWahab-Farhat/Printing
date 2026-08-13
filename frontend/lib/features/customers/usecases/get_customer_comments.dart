import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_comment.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';

/// Every note staff have left on a customer, newest first.
class GetCustomerComments {
  const GetCustomerComments(this._repository);

  final CustomerCommentRepository _repository;

  Future<Either<Failure, List<CustomerComment>>> call(int customerId) =>
      _repository.comments(customerId);
}
