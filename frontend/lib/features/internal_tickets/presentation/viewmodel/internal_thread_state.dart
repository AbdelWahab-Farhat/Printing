part of 'internal_thread_cubit.dart';

/// رسالةٌ صوتية لم تصل — تبقى فوق صندوق الكتابة بزرّين: «أعد الإرسال» و«احذفها».
///
/// **التسجيلُ لا يُرمى لأن الشبكة سقطت**: خمسُ دقائق من الكلام لا يُطلب من أحدٍ أن يقولها ثانيةً.
/// والرمزُ نفسه في الإعادة ([clientToken])، فإن كانت الأولى قد وصلت فعلاً لم تُكتب ثانية.
@freezed
abstract class PendingVoice with _$PendingVoice {
  const factory PendingVoice({
    required String path,
    required int durationSeconds,
    required List<int> waveform,
    required String clientToken,
    int? replyToMessageId,
  }) = _PendingVoice;
}

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
    InternalMessage? replyingTo,

    /// صوتٌ لم يصل.
    PendingVoice? unsentVoice,
  }) = InternalThreadLoaded;
}
