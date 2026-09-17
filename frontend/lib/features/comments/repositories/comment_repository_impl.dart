import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [CommentRepository] over HTTP.
///
/// **The one place that knows a note's URL depends on what it is about.** The API nests notes
/// under their owner, and turning a [CommentSubject] into that path is this file's whole job —
/// so a screen holds a subject and never a string, and adding a third kind of record is one arm
/// of one switch.
class CommentRepositoryImpl implements CommentRepository {
  const CommentRepositoryImpl(this._dio);

  final Dio _dio;

  /// `/customers/7/comments`, `/vendors/4/comments`.
  static String _base(CommentSubject subject) => switch (subject.kind) {
    CommentSubjectKind.customer => CustomerEndpoints.comments(subject.id),
    CommentSubjectKind.vendor => VendorEndpoints.comments(subject.id),
    CommentSubjectKind.designTicket => DesignTicketEndpoints.comments(subject.id),
  };

  static String _one(CommentSubject subject, int commentId) => '${_base(subject)}/$commentId';

  @override
  Future<Either<Failure, CommentThread>> comments(CommentSubject subject) {
    // `safeMetaRequest`, not `safePaginatedRequest`: `data` is the bare list and `meta` holds
    // one fact about the thread rather than a page's numbers — the paginated parser would report
    // a malformed response for a reply that is exactly what the API promised.
    return safeMetaRequest<CommentThread>(
      () => _dio.get(_base(subject)),
      parse: CommentThread.fromEnvelope,
    );
  }

  @override
  Future<Either<Failure, Comment>> add(CommentSubject subject, {required String body}) {
    return safeRequest<Comment>(
      () => _dio.post(_base(subject), data: <String, dynamic>{'body': body.trim()}),
      parse: (data) => Comment.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, Comment>> edit(
    CommentSubject subject,
    int commentId, {
    required String body,
  }) {
    return safeRequest<Comment>(
      () => _dio.patch(
        _one(subject, commentId),
        data: <String, dynamic>{'body': body.trim()},
      ),
      parse: (data) => Comment.fromJson(data! as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> remove(CommentSubject subject, int commentId) {
    // A command: there is no body to parse and nothing left to show, so the answer is the
    // server's own message.
    return safeCommand(() => _dio.delete(_one(subject, commentId)));
  }
}
