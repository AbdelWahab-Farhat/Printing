import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/repositories/comment_repository.dart';

/// «قرأتُ هذه المحادثة» — يُنادى حين تُفتح، فتنطفئ شارتُها.
///
/// **ويُطفئ خبرَها في الجرس معها، لأنهما صفوفٌ واحدة.** كلّ ردٍّ يُنشئ صفَّ إشعارٍ واحداً على
/// الخادم، والشارةُ عدُّ ما لم يُقرأ منها — فمَن قرأ الردود في مكانها قرأها، وبقاءُ خبرها فوق
/// الجرس بعد ذلك يجعل ذلك الرقم كذبةً صغيرةً تتكرّر حتى يتعلّم الناس تجاهله.
///
/// يجيب بعدد ما بقي غير مقروءٍ **في الحساب كلّه**، لا في هذه المحادثة — تلك صارت صفراً بالتعريف.
/// وهو ما يتيح تصحيح الشارتين بذهابٍ واحد.
class MarkThreadRead {
  const MarkThreadRead(this._repository);

  final CommentRepository _repository;

  Future<Either<Failure, int>> call(CommentSubject subject) =>
      _repository.markThreadRead(subject);
}
