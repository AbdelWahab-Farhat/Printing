import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// يترك ملاحظةً عن سجلٍّ لمن يخدمه بعده.
///
/// **تكلّف `customers.view` ولا شيء أكثر.** الملاحظة أداةُ عملٍ لا امتياز: من جاز له أن يبحث عن
/// عميلٍ جاز له أن يخبر مَن بعده بما تعلّمه.
class AddComment {
  const AddComment(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, Comment>> call(CommentSubject subject, {required String body}) =>
      _repository.add(subject, body: body);
}
