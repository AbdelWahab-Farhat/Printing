part of 'internal_thread_cubit.dart';

/// ما يكون على شاشة المحادثة — كحالة محادثة الدعم: **الفشلُ في `loaded` يُقال بجانب المحادثة ولا
/// يأخذها**؛ [InternalThreadFailure] للقراءة التي لم تصل وحدها.
@freezed
sealed class InternalThreadState with _$InternalThreadState {
  const factory InternalThreadState.loading() = InternalThreadLoading;

  const factory InternalThreadState.failure(Failure failure) = InternalThreadFailure;

  const factory InternalThreadState.loaded({
    required InternalTicket ticket,

    /// كتابةٌ في الطريق — رسالة، تعديل، سحب، إغلاق، تحويل.
    @Default(false) bool isWorking,

    /// آخرُ كتابةٍ لم تأخذ، مقولةً بجانب محادثةٍ ما زالت هناك.
    Failure? lastFailure,

    /// الرسالةُ التي يُردّ عليها — تُقتبس فوق الردّ.
    ChatMessage? replyingTo,

    /// صوتٌ لم يصل.
    PendingVoice? unsentVoice,
  }) = InternalThreadLoaded;
}
