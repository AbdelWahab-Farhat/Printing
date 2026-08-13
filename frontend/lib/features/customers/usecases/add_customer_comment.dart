import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_comment.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';

/// Leaves a note about a customer for whoever serves them next.
///
/// **Costs `customers.view` and nothing more.** A note is a working tool rather than a
/// privilege: anyone who may look a customer up may tell the next person what they learned.
class AddCustomerComment {
  const AddCustomerComment(this._repository);

  final CustomerCommentRepository _repository;

  Future<Either<Failure, CustomerComment>> call(int customerId, {required String body}) =>
      _repository.add(customerId, body: body);
}
