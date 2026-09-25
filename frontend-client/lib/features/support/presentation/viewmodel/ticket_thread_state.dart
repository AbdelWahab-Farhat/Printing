part of 'ticket_thread_cubit.dart';

/// Everything one conversation can be.
@freezed
sealed class TicketThreadState with _$TicketThreadState {
  const factory TicketThreadState.loading() = TicketThreadLoading;

  const factory TicketThreadState.loaded(
    SupportTicket ticket, {
    /// ما كتبه العميل ولم يقبله الخادم بعد، بترتيب كتابته — فقاعاتٌ بساعة، أو بحلقة رفعٍ للملف،
    /// أو بعلامةٍ حمراء حين ترفض. انظر [OutgoingMessage].
    @Default(<OutgoingMessage>[]) List<OutgoingMessage> outbox,

    /// The last thing that failed, for the screen to say once. The messages already there are
    /// still true, and a message that failed to send stays in [outbox] with its reason.
    Failure? lastFailure,
  }) = TicketThreadLoaded;

  const factory TicketThreadState.failure(Failure failure) = TicketThreadFailure;
}

extension TicketThreadStateX on TicketThreadState {
  /// The thread as it stands, for the screen to hand back to the list on its way out.
  SupportTicket? get ticket => switch (this) {
    TicketThreadLoaded(:final ticket) => ticket,
    _ => null,
  };

  List<OutgoingMessage> get outbox => switch (this) {
    TicketThreadLoaded(:final outbox) => outbox,
    _ => const [],
  };

  /// رسالةٌ ما زالت في الطريق.
  bool get isSending => outbox.any((message) => message.status == OutgoingStatus.sending);

  /// Whether the field should accept anything. A closed thread still accepts a reply — **that
  /// reply reopens it**, which is the server's decision and the reason this is not `isOpen`.
  /// ولا تُقفل أثناء الإرسال: الرسائل تُصفّ وتُرسل بالترتيب، كما في كل تطبيق محادثة.
  bool get canWrite => this is TicketThreadLoaded;
}
