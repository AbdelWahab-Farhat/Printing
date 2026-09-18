import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// كلّ ما تركه الموظفون من ملاحظاتٍ على سجلّ، الأحدث أولاً، وهل بقي ما يُقال.
class GetComments {
  const GetComments(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, CommentThread>> call(CommentSubject subject) =>
      _repository.comments(subject);
}
