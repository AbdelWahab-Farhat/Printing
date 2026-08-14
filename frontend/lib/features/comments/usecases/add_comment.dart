import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// Leaves a note about a customer for whoever serves them next.
///
/// **Costs `customers.view` and nothing more.** A note is a working tool rather than a
/// privilege: anyone who may look a customer up may tell the next person what they learned.
class AddComment {
  const AddComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, Comment>> call(CommentSubject subject, {required String body}) =>
      _repository.add(subject, body: body);
}
