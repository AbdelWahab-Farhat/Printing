import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer_comment.dart';
import 'package:printing/features/customers/repositories/customer_comment_repository.dart';

/// Rewrites a note.
///
/// **The text is the only thing an edit can touch** — not who wrote it and not which customer
/// it is about. A note is a sentence somebody said about somebody, and an edit that could move
/// either of those would turn a record into a forgery.
///
/// Whose notes may be rewritten is the server's answer, carried on each one as `canEdit`: its
/// author, or somebody holding `customers.comments.moderate`.
class EditCustomerComment {
  const EditCustomerComment(this._repository);

  final CustomerCommentRepository _repository;

  Future<Either<Failure, CustomerComment>> call(
    int customerId,
    int commentId, {
    required String body,
  }) => _repository.edit(customerId, commentId, body: body);
}
