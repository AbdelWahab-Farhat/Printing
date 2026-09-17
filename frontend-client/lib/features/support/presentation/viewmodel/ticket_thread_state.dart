part of 'ticket_thread_cubit.dart';

/// Everything one conversation can be.
@freezed
sealed class TicketThreadState with _$TicketThreadState {
  const factory TicketThreadState.loading() = TicketThreadLoading;

  const factory TicketThreadState.loaded(
    SupportTicket ticket, {
    /// A reply is in flight. The thread stays on screen and the field locks — a conversation
    /// that vanishes behind a spinner every time somebody writes into it reads as broken.
    @Default(false) bool isSending,

    /// The reply that failed, cleared by the next attempt. The messages already there are
    /// still true.
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

  bool get isSending => switch (this) {
    TicketThreadLoaded(:final isSending) => isSending,
    _ => false,
  };

  /// Whether the field should accept anything. A closed thread still accepts a reply — **that
  /// reply reopens it**, which is the server's decision and the reason this is not `isOpen`.
  bool get canWrite => switch (this) {
    TicketThreadLoaded(:final isSending) => !isSending,
    _ => false,
  };
}
