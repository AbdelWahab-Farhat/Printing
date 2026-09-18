import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// يرفع ملاحظةً عن السجلّ.
///
/// حذفٌ ناعم على الخادم: القائمة تفقدها والسجلّ يحتفظ بها، وهذا ما يجعل «من حذف الملاحظة؟» سؤالاً
/// له جواب.
class DeleteComment {
  const DeleteComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, String>> call(CommentSubject subject, int commentId) =>
      _repository.remove(subject, commentId);
}
