part of 'comments_cubit.dart';

/// كلّ ما يمكن أن تكونه شاشة الملاحظات.
///
/// **[loaded] لا تُغادَر بعد بلوغها أبداً.** الإضافة والتعديل والحذف كلّها تُبقي القائمة على
/// الشاشة وتُعلّم الصفّ المتحرّك وحده — وصفحةٌ تبيضّ إلى دوّارةٍ لأن جملةً تُحفظ سلبت المستخدمَ ما
/// كان يقرؤه. و[failure] للقراءة الأولى وحدها، حين لا يوجد ما يُحتفظ به.
@freezed
sealed class CommentsState with _$CommentsState {
  const factory CommentsState.loading() = CommentsLoading;

  const factory CommentsState.loaded({
    required List<Comment> comments,

    /// هل بقي ما يُقال هنا — جواب الخادم، محمولاً على القائمة.
    ///
    /// **حقيقةٌ عن الخيط لا عن ملاحظةٍ بعينها.** محادثة تذكرة التصميم تنتهي بانتهائها، والذي عليه
    /// أن يعرف ذلك هو الصندوق: والخيط المغلق الفارغ لا صفَّ فيه يُقرأ منه. وهي `true` للعميل
    /// وللمورّد دائماً.
    @Default(true) bool canComment,

    /// لماذا أُغلقت، بكلمات السجلّ نفسه. و`null` ما دامت مفتوحة.
    String? closedNote,

    /// معرّفات الملاحظات التي يُعاد كتابتها أو تُحذف الآن. مجموعةٌ لا معرّفاً واحداً لأن صفّين قد
    /// يُعمل عليهما معاً وعلى كلٍّ منهما أن يُظهر حاله.
    @Default(<int>{}) Set<int> busy,

    /// `true` ما دامت ملاحظةٌ *جديدة* في طريقها إلى الأعلى. منفصلةٌ عن [busy] المفهرسة بالمعرّف —
    /// وملاحظةٌ لم توجد بعدُ لا معرّف لها.
    @Default(false) bool isAdding,
  }) = CommentsLoaded;

  const factory CommentsState.failure(Failure failure) = CommentsFailure;
}

extension CommentsStateX on CommentsState {
  /// الملاحظات، كلّما وُجدت — بما في ذلك أثناء حفظ إحداها.
  List<Comment>? get comments => switch (this) {
    CommentsLoaded(:final comments) => comments,
    _ => null,
  };

  bool get isAdding => switch (this) {
    CommentsLoaded(:final isAdding) => isAdding,
    _ => false,
  };

  /// هل يُرسم الصندوق. مفتوحٌ حتى يقول الخادم غير ذلك — بما في ذلك والقراءة الأولى ما تزال
  /// خارجة، فلا يرتجف شيءٌ مغلقاً ثم مفتوحاً.
  bool get canComment => switch (this) {
    CommentsLoaded(:final canComment) => canComment,
    _ => true,
  };

  String? get closedNote => switch (this) {
    CommentsLoaded(:final closedNote) => closedNote,
    _ => null,
  };

  /// هل هذه الملاحظة بعينها في منتصف طلبها، وهو ما يُخفّت صفَّها ويعطّل أزرارها دون أن يمسّ بقية
  /// القائمة.
  bool isBusy(int commentId) => switch (this) {
    CommentsLoaded(:final busy) => busy.contains(commentId),
    _ => false,
  };
}
