import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/usecases/get_ticket.dart';
import 'package:dayaa_client/features/support/usecases/reply_to_ticket.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_thread_cubit.freezed.dart';
part 'ticket_thread_state.dart';

/// The ViewModel for one conversation.
///
/// **Loading the thread is what marks it read**, and the server does that on the same call — so
/// there is no «mark as read» to fire here, and no cursor for this app to get wrong.
class TicketThreadCubit extends Cubit<TicketThreadState> {
  TicketThreadCubit({
    required this.ticketId,
    required GetTicket get,
    required ReplyToTicket reply,
  }) : _get = get,
       _reply = reply,
       super(const TicketThreadState.loading());

  final int ticketId;
  final GetTicket _get;
  final ReplyToTicket _reply;

  Future<void> load() async {
    emit(const TicketThreadState.loading());

    final result = await _get(ticketId);

    if (isClosed) return;

    emit(result.fold(TicketThreadState.failure, TicketThreadState.loaded));
  }

  /// Sends a reply and redraws the thread from what came back.
  ///
  /// **Nothing is appended optimistically.** A message drawn before the server accepted it is a
  /// message the customer believes was sent, and support is the one place in this app where
  /// that belief is expensive. The whole ticket returns — including a status that may have
  /// reopened — so the thread is replaced rather than patched.
  Future<void> send(String body) async {
    final loaded = _loaded;

    if (loaded == null || loaded.isSending) return;

    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    emit(loaded.copyWith(isSending: true, lastFailure: null));

    final result = await _reply(id: ticketId, body: trimmed);

    if (isClosed) return;

    final current = _loaded;
    if (current == null) return;

    emit(
      result.fold(
        (failure) => current.copyWith(isSending: false, lastFailure: failure),
        (ticket) => TicketThreadState.loaded(ticket),
      ),
    );
  }

  /// The thread as it stands, for the screen to hand back to the list on its way out.
  SupportTicket? get ticket => _loaded?.ticket;

  TicketThreadLoaded? get _loaded => switch (state) {
    final TicketThreadLoaded loaded => loaded,
    _ => null,
  };
}
