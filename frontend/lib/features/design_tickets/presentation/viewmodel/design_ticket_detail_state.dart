part of 'design_ticket_detail_cubit.dart';

/// Everything the ticket screen can be.
///
/// **Each case carries the ticket it already has**, which is what lets a refusal put the user
/// back on the screen they were reading rather than on a spinner or an error page — and the
/// refusals are the point here. Only the very first load has nothing to show.
@freezed
sealed class DesignTicketDetailState with _$DesignTicketDetailState {
  const factory DesignTicketDetailState.loading({DesignTicket? ticket}) =
      DesignTicketDetailLoading;

  const factory DesignTicketDetailState.ready(DesignTicket ticket) = DesignTicketDetailReady;

  /// A write is in flight — an acceptance, an upload, a verdict, an assignment, a cancellation.
  /// The ticket stays on screen and the buttons lock.
  const factory DesignTicketDetailState.working(DesignTicket ticket) = DesignTicketDetailWorking;

  const factory DesignTicketDetailState.failure(Failure failure, {DesignTicket? ticket}) =
      DesignTicketDetailFailure;
}

extension DesignTicketDetailStateX on DesignTicketDetailState {
  /// What is on screen, whatever else is happening. Null only before the first read lands.
  DesignTicket? get ticket => switch (this) {
    DesignTicketDetailLoading(:final ticket) => ticket,
    DesignTicketDetailReady(:final ticket) => ticket,
    DesignTicketDetailWorking(:final ticket) => ticket,
    DesignTicketDetailFailure(:final ticket) => ticket,
  };

  bool get isWorking => this is DesignTicketDetailWorking;
}
