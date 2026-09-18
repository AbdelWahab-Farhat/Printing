import 'package:dayaa/features/comments/models/comment.dart';

/// كلّ ملاحظات سجلٍّ واحد، **وهل بقي ما يُقال**.
///
/// النصف الثاني هو سبب وجود هذا الصنف بدل `List<Comment>` مجرّدة. تذكرة التصميم تنتهي — «بعد
/// الاعتماد لا يوجد مزيد» — والذي عليه أن يعرف ذلك هو الصندوق تحت القائمة، وهو يُرسم سواءٌ كان
/// فوقه صفٌّ واحد أم لا. والمحادثة المغلقة الفارغة لا صفَّ فيها يحمل الخبر، فيسافر بجوار الصفوف:
/// يرسله الخادم في `meta`، حيث تأتي أرقام الصفحات.
///
/// **والخادم هو الذي يقرّر، كما في `canEdit`.** محادثة العميل لا تُغلق أبداً، ومحادثة التذكرة
/// تُغلق بإغلاقها، ولا تُكتب أيٌّ من القاعدتين مرّتين — التطبيق يرسم ما يُقال له، ونقاط النهاية
/// ترفض على أي حال.
class CommentThread {
  const CommentThread({
    required this.comments,
    this.canComment = true,
    this.closedNote,
  });

  /// من نصفَي الغلاف: `data` هي القائمة، و`meta` هي ما يصحّ عن الخيط كلّه.
  ///
  /// **مفتوحةٌ ما لم يقل الخادم غير ذلك.** إصدارٌ أقدم من الواجهة لا يرسل `meta` أصلاً، وصندوقٌ
  /// يرفض أن يُفتح لأن مفتاحاً كان غائباً أسوأ من صندوقٍ يُفتح ويلقى رفضاً يستطيع عرضه.
  factory CommentThread.fromEnvelope(dynamic data, Map<String, dynamic> meta) {
    return CommentThread(
      comments: (data! as List)
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList(growable: false),
      canComment: meta['can_comment'] as bool? ?? true,
      closedNote: meta['closed_note'] as String?,
    );
  }

  /// الأحدث أولاً، تماماً كما أرسلها الخادم.
  final List<Comment> comments;

  /// هل الصندوق مفتوح. و`false` تُجمّد الخيط كلّه — لا إضافة، ولا تعديل ولا حذف، وهذان يصلان
  /// لكل صفٍّ على حدة كـ`canEdit` و`canDelete` بقيمة false.
  final bool canComment;

  /// لماذا أُغلقت، بكلمات السجلّ نفسه — «اعتُمد التصميم وأُغلقت المحادثة». و`null` ما دامت
  /// مفتوحة، ولا تُخترع هنا أبداً: سببٌ يكتبه التطبيق لنفسه تخمينٌ مطبوعٌ في صورة حقيقة.
  final String? closedNote;
}
