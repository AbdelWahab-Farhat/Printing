import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// يعيد كتابة ملاحظة.
///
/// **النصّ هو الشيء الوحيد الذي يمسّه التعديل** — لا مَن كتبها ولا عمّن هي. الملاحظة جملةٌ قالها
/// أحدٌ عن أحد، وتعديلٌ يستطيع تحريك أيٍّ من الاثنين يحوّل السجلّ إلى تزوير.
///
/// ومَن تُعدَّل ملاحظاته جوابُ الخادم، محمولاً على كلٍّ منها كـ`canEdit`: كاتبُها، أو مَن يملك
/// `customers.comments.moderate`.
class EditComment {
  const EditComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, Comment>> call(
    CommentSubject subject,
    int commentId, {
    required String body,
  }) => _repository.edit(subject, commentId, body: body);
}
