import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';
import 'package:dio/dio.dart';

/// ينفّذ [CommentRepository] فوق HTTP.
///
/// **المكان الوحيد الذي يعرف أنّ رابط الملاحظة يتبع ما هي عنه.** الواجهة تُعشّش الملاحظات تحت
/// مالكها، وتحويلُ [CommentSubject] إلى ذلك المسار هو كلُّ عمل هذا الملف — فتحمل الشاشةُ موضوعاً
/// لا نصّاً، وإضافةُ نوعٍ ثالث من السجلات ذراعٌ واحدة في تفرّعٍ واحد.
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
    // `safeMetaRequest` لا `safePaginatedRequest`: `data` هي القائمة المجرّدة، و`meta` تحمل
    // حقيقةً واحدة عن الخيط لا أرقامَ صفحة — والمحلّل المصفَّح كان سيبلّغ عن ردٍّ مشوّه لردٍّ هو
    // تماماً ما وعدت به الواجهة.
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
  Future<Either<Failure, int>> markThreadRead(CommentSubject subject) async {
    // العميل والمورّد لا مسار لهما ولا شارة، فلا شيء يُطفأ. صفرٌ بلا رحلة، لا فشلٌ: الشاشة
    // نفسها تخدم الثلاثة، وخطأٌ هنا كان سيظهر للمستخدم كعطبٍ في فتح محادثةٍ فُتحت.
    if (subject.kind != CommentSubjectKind.designTicket) return const Right(0);

    return safeRequest<int>(
      () => _dio.post(DesignTicketEndpoints.commentsRead(subject.id)),
      // `unread_total` لا `unread_comments_count`: الثانية صفرٌ بالتعريف بعد هذا النداء، وما
      // يحتاجه المتّصل هو الرقم الذي يضعه فوق الجرس.
      parse: (data) => ((data! as Map<String, dynamic>)['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<Either<Failure, String>> remove(CommentSubject subject, int commentId) {
    // A command: there is no body to parse and nothing left to show, so the answer is the
    // server's own message.
    return safeCommand(() => _dio.delete(_one(subject, commentId)));
  }
}
