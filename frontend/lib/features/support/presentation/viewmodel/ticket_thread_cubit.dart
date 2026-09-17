import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/usecases/support_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_thread_cubit.freezed.dart';
part 'ticket_thread_state.dart';

/// One thread: what was said, and the three things the desk can do about it.
///
/// **Every write answers with the whole ticket**, so nothing here patches the thread by hand:
/// the server returns it with the reply in it, the new assignee on it, or the closure stamped,
/// and this emits that. A screen that appended its own message locally would be guessing at the
/// id and the timestamp the server allocated — and would show a message that is not yet in the
/// database as though it were.
class TicketThreadCubit extends Cubit<TicketThreadState> {
  TicketThreadCubit({
    required int ticketId,
    required GetTicket get,
    required ReplyToTicket reply,
    required AssignTicket assign,
    required CloseTicket close,
  }) : _ticketId = ticketId,
       _get = get,
       _reply = reply,
       _assign = assign,
       _close = close,
       super(const TicketThreadState.loading());

  final int _ticketId;
  final GetTicket _get;
  final ReplyToTicket _reply;
  final AssignTicket _assign;
  final CloseTicket _close;

  /// Reads the thread. **This is what clears the unread badge**, server-side — the GET marks the
  /// desk's side read, so this runs because somebody opened the screen and for no other reason.
  Future<void> load() async {
    emit(const TicketThreadState.loading());

    final result = await _get(_ticketId);

    if (isClosed) return;

    emit(
      result.fold(
        TicketThreadState.failure,
        (ticket) => TicketThreadState.loaded(ticket: ticket),
      ),
    );
  }

  /// Sends a reply.
  ///
  /// **A failed send keeps the thread on screen** and reports beside it — losing a conversation
  /// because one request timed out is the worst thing this screen could do. The text the person
  /// typed stays in the field, which is the screen's business and not this Cubit's: clearing it
  /// on failure would throw away the sentence they are being asked to send again.
  Future<bool> send(String body) {
    final trimmed = body.trim();

    if (trimmed.isEmpty) return Future<bool>.value(false);

    return _write(() => _reply(_ticketId, body: trimmed));
  }

  /// Puts the ticket on somebody's desk, or [userId] null to put it back in the queue.
  Future<bool> assignTo(int? userId) => _write(() => _assign(_ticketId, userId: userId));

  /// Ends the conversation. Idempotent on the server, so a second press is not a failure.
  Future<bool> closeTicket() => _write(() => _close(_ticketId));

  /// The shape all three writes share: mark busy, send, and either put the server's ticket on
  /// screen or keep the one already there and say why the write did not take.
  ///
  /// Returns whether it took, so the screen can clear its field or pop only on success.
  Future<bool> _write(Future<Either<Failure, SupportTicket>> Function() send) async {
    final loaded = state;

    // Nothing to write onto, or a write already in flight. The second guard is what stops a
    // double tap on «إغلاق» from sending two requests.
    if (loaded is! TicketThreadLoaded || loaded.isWorking) return false;

    emit(loaded.copyWith(isWorking: true, lastFailure: null));

    final result = await send();

    if (isClosed) return false;

    // Re-read rather than reusing `loaded`: the state may have moved on across the await.
    final current = state;
    if (current is! TicketThreadLoaded) return false;

    return result.fold(
      (failure) {
        emit(current.copyWith(isWorking: false, lastFailure: failure));

        return false;
      },
      (ticket) {
        emit(current.copyWith(isWorking: false, ticket: ticket, lastFailure: null));

        return true;
      },
    );
  }
}
