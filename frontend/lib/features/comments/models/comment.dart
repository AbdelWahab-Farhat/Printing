import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// شيءٌ واحد كتبه موظّفٌ عن سجلّ.
///
/// الأشياء التي تصحّ عن الشخص ولا حقلَ لها في النموذج — «يفضّل التسليم صباحاً»، «لا يردّ إلا على
/// واتساب» — وهي التي تُقال شفاهاً اليوم وترحل مع سامعها. انظر `CommentResource` لشكلها على
/// الشبكة.
///
/// **و[canEdit] و[canDelete] جوابا الخادم، لا تخمينَي هذا التطبيق.** القاعدة «كاتبُها أو مشرف»،
/// وتُحسب لكلّ قارئٍ على الخادم وتُرسل مع كل صفّ. وإعادةُ حسابها هنا نسخةٌ ثانية من قاعدة صلاحيات
/// تنحرف يوم تتغيّر الأولى — ونقاط النهاية ترفض الطلب على أي حال، فهاتان تقرّران ما *يُرسم* لا ما
/// *يجوز* أبداً.
@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required int id,
    /// عمّاذا هي، بالاسم القصير للخادم نفسه — `customer`، `vendor`. يبقى رغم أن كل شاشةٍ تعرف
    /// أصلاً على صفحة مَن هي: ملاحظةٌ تُتداول بلا شاشتها ملاحظةٌ لا تستطيع أن تقول لمن تتبع.
    @JsonKey(name: 'commentable_type') required String commentableType,
    @JsonKey(name: 'commentable_id') required int commentableId,
    required String body,
    required CommentAuthor author,
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// متى أُعيدت كتابتها آخر مرّة. و`null` معناها «كما كُتبت» — والملاحظة التي تغيّرت تقول ذلك،
    /// لأن جملةً تصير صامتةً جملةً أخرى أسوأ من لا جملة.
    @JsonKey(name: 'edited_at') DateTime? editedAt,

    @JsonKey(name: 'can_edit') @Default(false) bool canEdit,
    @JsonKey(name: 'can_delete') @Default(false) bool canDelete,
  }) = _Comment;

  const Comment._();

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  bool get wasEdited => editedAt != null;
}

/// مَن كتبها.
///
/// الاسم يسافر مع الملاحظة بدل أن يُبحث عنه بالمعرّف: كلّ شاشةٍ تعرض ملاحظةً تعرض الاسم، وتطبيقٌ
/// يجلب اسماً لكل صفّ تطبيقٌ يُصدر N طلباً ليرسم قائمة. وهو قابلٌ للعدم لأن الملاحظة تُنسب إلى
/// صفّ مستخدم، وليس في هذا التطبيق شاشةٌ تستطيع أن تَعِد بأن الاسم حُمّل.
@freezed
abstract class CommentAuthor with _$CommentAuthor {
  const factory CommentAuthor({required int id, String? name}) = _CommentAuthor;

  const CommentAuthor._();

  factory CommentAuthor.fromJson(Map<String, dynamic> json) => _$CommentAuthorFromJson(json);

  /// ما يُطبع فوق الملاحظة حين لا يصل الاسم — «موظف» بدل سطرٍ فارغ يُقرأ ملاحظةً لم يكتبها
  /// أحد.
  String get displayName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : 'موظف';
}
