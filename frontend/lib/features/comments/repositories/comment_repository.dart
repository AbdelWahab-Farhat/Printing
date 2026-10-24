import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/comments/models/comment.dart';
import 'package:dayaa/features/comments/models/comment_subject.dart';
import 'package:dayaa/features/comments/models/comment_thread.dart';

/// ما يستطيع التطبيق فعله بملاحظات الموظفين على سجلّ.
///
/// عقدٌ خاصٌّ به لا أربعُ دوالّ إضافية على `CustomerRepository` — وميزةٌ خاصّةٌ به الآن، لأن
/// النداءات الأربعة نفسها تخدم المورّد: كلّ ما هنا محصورٌ بسجلٍّ واحد ولا شيء منه يُصفَّح، بينما
/// مستودع السجلّ نفسه قائمةٌ تُبحث وتُصفَّح.
///
/// **وكلّ نداءٍ يأخذ [CommentSubject] لا معرّفاً.** الواجهة تُعشّش الملاحظات تحت مالكها، فالمعرّف
/// وحده لا يقول أيَّ بابٍ يُطرق.
abstract interface class CommentRepository {
  /// كلّ ملاحظات هذا السجلّ، الأحدث أولاً، **وهل ما تزال المحادثة مفتوحة**.
  ///
  /// قائمةٌ مجرّدة لا صفحة. الملاحظات تتراكم بسرعة الكلام، ودوّارةُ «حمّل المزيد» تحت قائمةٍ
  /// مكتملةٍ أصلاً كذبةٌ عن وجود مزيد.
  ///
  /// وحالُ الخيط نفسه تعود معها لأن المحادثة المغلقة الفارغة — تذكرةٌ اعتُمدت قبل أن يكتب أحدٌ
  /// كلمة — لا صفَّ فيها يحملها، والصندوق يُرسم على أي حال. انظر [CommentThread].
  Future<Either<Failure, CommentThread>> comments(CommentSubject subject);

  /// يترك ملاحظةً، ويجيب بالتي خزّنها الخادم.
  ///
  /// الكاتب لا يُرسل أبداً: الخادم يختم المستخدم المسجَّل، وهذا ما يجعل توقيع اسم شخصٍ آخر على
  /// جملةٍ مستحيلاً.
  Future<Either<Failure, Comment>> add(CommentSubject subject, {required String body});

  /// يعيد كتابة واحدة.
  ///
  /// يُرفض بـ403 لملاحظةٍ لم يكتبها هذا المستخدم، إلا أن يملك `comments.moderate` — وهو تماماً ما
  /// تقوله `canEdit` على الملاحظة أصلاً، فالشاشةُ التي ترسم أزرارها من تلك الراية لا تلقى الرفض
  /// عادةً.
  Future<Either<Failure, Comment>> edit(
    CommentSubject subject,
    int commentId, {
    required String body,
  });

  /// يحذف واحدة. حذفٌ ناعم على الخادم: القائمة تفقدها والسجلّ يحتفظ بها، ويبقى «من حذف
  /// الملاحظة؟» سؤالاً له جواب. ويجيب برسالة الخادم نفسها.
  Future<Either<Failure, String>> remove(CommentSubject subject, int commentId);
}
