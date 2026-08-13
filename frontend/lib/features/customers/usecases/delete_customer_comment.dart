import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';

/// Takes a note off the customer.
///
/// Soft on the server: the list loses it and the audit trail keeps it, which is what makes «من
/// حذف الملاحظة؟» a question with an answer.
class DeleteCustomerComment {
  const DeleteCustomerComment(this._repository);

  final CustomerCommentRepository _repository;

  Future<Either<Failure, String>> call(int customerId, int commentId) =>
      _repository.remove(customerId, commentId);
}
