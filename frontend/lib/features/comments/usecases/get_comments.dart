import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// Every note staff have left on a customer, newest first.
class GetComments {
  const GetComments(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, List<Comment>>> call(CommentSubject subject) =>
      _repository.comments(subject);
}
