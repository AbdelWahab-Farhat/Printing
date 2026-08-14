import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';

/// What the app can do about the notes staff leave on a record.
///
/// Its own contract rather than four more methods on `CustomerRepository` — and now its own
/// feature, because the same four calls serve a supplier: everything here is scoped to one
/// record and none of it paginates, while a record's own repository is a searchable, paged list.
///
/// **Every call takes a [CommentSubject] rather than an id.** The API nests notes under their
/// owner, so an id alone would not say which door to knock on.
abstract interface class CommentRepository {
  /// Every note on this record, newest first.
  ///
  /// A plain list, not a page. Notes accumulate at the speed of conversation, and a load-more
  /// spinner under a list that is already complete is a lie about there being more.
  Future<Either<Failure, List<Comment>>> comments(CommentSubject subject);

  /// Leaves a note, and answers with the one the server stored.
  ///
  /// The author is never sent: the backend stamps the signed-in user, which is what makes it
  /// impossible to sign somebody else's name to a sentence.
  Future<Either<Failure, Comment>> add(CommentSubject subject, {required String body});

  /// Rewrites one.
  ///
  /// Refused with 403 for a note this user did not write, unless they hold
  /// `comments.moderate` — which is exactly what the note's `canEdit` already says,
  /// so a screen drawing its buttons off that flag will not normally meet the refusal.
  Future<Either<Failure, Comment>> edit(
    CommentSubject subject,
    int commentId, {
    required String body,
  });

  /// Removes one. Soft on the server: the list loses it, the history keeps it, and «من حذف
  /// الملاحظة؟» stays answerable. Answers with the server's own message.
  Future<Either<Failure, String>> remove(CommentSubject subject, int commentId);
}
