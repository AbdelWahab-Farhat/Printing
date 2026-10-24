part of 'design_ticket_thread_cubit.dart';

/// ما يكون على شاشة محادثة التذكرة — كحالة محادثة التذاكر الداخلية: **الفشلُ في `loaded` يُقال
/// بجانب المحادثة ولا يأخذها**؛ [DesignTicketThreadFailure] للقراءة التي لم تصل وحدها.
@freezed
sealed class DesignTicketThreadState with _$DesignTicketThreadState {
  const factory DesignTicketThreadState.loading() = DesignTicketThreadLoading;

  const factory DesignTicketThreadState.failure(Failure failure) = DesignTicketThreadFailure;

  const factory DesignTicketThreadState.loaded({
    required DesignTicketThread thread,

    /// كتابةٌ في الطريق — رسالة، تعديل، سحب.
    @Default(false) bool isWorking,

    /// آخرُ كتابةٍ لم تأخذ، مقولةً بجانب محادثةٍ ما زالت هناك.
    Failure? lastFailure,

    /// الرسالةُ التي يُردّ عليها — تُقتبس فوق الردّ.
    ChatMessage? replyingTo,

    /// صوتٌ لم يصل.
    PendingVoice? unsentVoice,
  }) = DesignTicketThreadLoaded;
}
