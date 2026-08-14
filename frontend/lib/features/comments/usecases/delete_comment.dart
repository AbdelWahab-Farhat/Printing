import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// Takes a note off the customer.
///
/// Soft on the server: the list loses it and the audit trail keeps it, which is what makes «من
/// حذف الملاحظة؟» a question with an answer.
class DeleteComment {
  const DeleteComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, String>> call(CommentSubject subject, int commentId) =>
      _repository.remove(subject, commentId);
}
