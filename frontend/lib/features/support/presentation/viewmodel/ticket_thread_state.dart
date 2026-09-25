part of 'ticket_thread_cubit.dart';

/// What can be on the thread screen.
///
/// **Three states, and `loaded` carries its own failure rather than becoming one.** A reply that
/// did not send must not take the conversation off the screen — the whole point of the screen is
/// the conversation, and replacing it with «حدث خطأ» over a timeout would lose what was said.
/// [TicketThreadFailure] is only for the read that never arrived, when there is nothing to show.
@freezed
sealed class TicketThreadState with _$TicketThreadState {
  const factory TicketThreadState.loading() = TicketThreadLoading;

  /// The read failed and there is no thread to draw.
  const factory TicketThreadState.failure(Failure failure) = TicketThreadFailure;

  const factory TicketThreadState.loaded({
    required SupportTicket ticket,

    /// A reply, an assignment or a closure in flight. Holds the buttons rather than greying the
    /// screen: what is on it is still true.
    @Default(false) bool isWorking,

    /// The last write that did not take, reported beside a thread that is still there.
    Failure? lastFailure,
  }) = TicketThreadLoaded;
}
