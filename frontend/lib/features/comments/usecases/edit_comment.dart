import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// Rewrites a note.
///
/// **The text is the only thing an edit can touch** — not who wrote it and not which customer
/// it is about. A note is a sentence somebody said about somebody, and an edit that could move
/// either of those would turn a record into a forgery.
///
/// Whose notes may be rewritten is the server's answer, carried on each one as `canEdit`: its
/// author, or somebody holding `customers.comments.moderate`.
class EditComment {
  const EditComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, Comment>> call(
    CommentSubject subject,
    int commentId, {
    required String body,
  }) => _repository.edit(subject, commentId, body: body);
}
