import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'design_ticket_detail_cubit.freezed.dart';
part 'design_ticket_detail_state.dart';

/// One design ticket, and everything that can be done to it.
///
/// **Every write ends in a re-read, and three of them have no choice.** An upload and a verdict
/// answer with the *file row*, not with the ticket — so the new status, the new version list and,
/// on an approval, the design now sitting on the customer's account exist only on the server
/// until this asks for them again. Doing the same after an acceptance or an assignment keeps one
/// rule instead of several, and costs a request on actions nobody repeats.
///
/// **The failures are handed back rather than swallowed.** Every refusal this screen can meet is
/// a 422 with its own sentence — a race lost to another designer, naming them; a change request
/// with no words; a verdict on your own work; a ticket somebody closed from another device — and
/// each tells the person something different to do. Showing «حدث خطأ» instead would throw away a
/// message the server took care to word.
class DesignTicketDetailCubit extends Cubit<DesignTicketDetailState> {
  DesignTicketDetailCubit({
    required int ticketId,
    required GetDesignTicket getTicket,
    required AcceptDesignTicket acceptTicket,
    required AssignDesignTicket assignTicket,
    required CancelDesignTicket cancelTicket,
    required AttachDesignTicketFile attachFile,
    required RemoveDesignTicketAttachment removeAttachment,
    required SubmitDesignVersion submitVersion,
    required ReviewDesignVersion reviewVersion,
  }) : _id = ticketId,
       _getTicket = getTicket,
       _accept = acceptTicket,
       _assign = assignTicket,
       _cancel = cancelTicket,
       _attach = attachFile,
       _removeAttachment = removeAttachment,
       _submit = submitVersion,
       _review = reviewVersion,
       super(const DesignTicketDetailState.loading());

  final int _id;
  final GetDesignTicket _getTicket;
  final AcceptDesignTicket _accept;
  final AssignDesignTicket _assign;
  final CancelDesignTicket _cancel;
  final AttachDesignTicketFile _attach;
  final RemoveDesignTicketAttachment _removeAttachment;
  final SubmitDesignVersion _submit;
  final ReviewDesignVersion _review;

  Future<void> load() async {
    // What it already has is kept while the next read is in flight, so a pull-to-refresh does not
    // blank the screen the user is reading.
    emit(DesignTicketDetailState.loading(ticket: state.ticket));

    final result = await _getTicket(_id);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => DesignTicketDetailState.failure(failure, ticket: state.ticket),
        DesignTicketDetailState.ready,
      ),
    );
  }

  /// «قبول الطلب».
  ///
  /// **A lost race is the interesting outcome**, and it is a 422 naming whoever holds the ticket.
  /// Returned rather than swallowed so the screen can say «أخذها فلان» — which is the whole
  /// second half of «لا تضيع هوية المصمم الذي استلم الطلب».
  Future<Failure?> accept() => _write(() => _accept(_id));

  /// Hands it to a designer, or returns it to the shared pool — a null [designerId] is the pool,
  /// which is a queue rather than an absence.
  Future<Failure?> assign(int? designerId) => _write(() => _assign(_id, designerId: designerId));

  /// Calls the request off. The reason is required by the server and by the database under it.
  Future<Failure?> cancel(String reason) => _write(() => _cancel(_id, reason: reason));

  /// Adds one of the employee's reference files.
  Future<Failure?> attach({required String path, required String filename, String? note}) =>
      _write(() => _attach(_id, path: path, filename: filename, note: note));

  /// Removes one. **Only a brief** — naming a version is a 404, by design.
  Future<Failure?> removeAttachment(int attachmentId) =>
      _write(() => _removeAttachment(_id, attachmentId));

  /// Sends the designer's work up for review — the first version or the next one.
  Future<Failure?> submit({required String path, required String filename, String? note}) =>
      _write(() => _submit(_id, path: path, filename: filename, note: note));

  /// The verdict on the version currently under review.
  ///
  /// Approving closes the ticket and files the artwork on the customer's account, which is why
  /// the re-read afterwards matters: `approved_design` only exists after it.
  Future<Failure?> review(
    int versionId, {
    required DesignSubmissionStatus verdict,
    String? note,
  }) => _write(() => _review(_id, versionId, verdict: verdict, note: note));

  /// One write, then one re-read.
  ///
  /// **The re-read runs even when the write failed**, and that is deliberate rather than tidy: a
  /// refusal usually means somebody else moved the ticket — accepted it, cancelled it, judged the
  /// version — so the screen behind the message must show what is actually true now. A failure
  /// left on stale rows invites the user to try the same thing again.
  Future<Failure?> _write(Future<Either<Failure, Object>> Function() action) async {
    final current = state.ticket;

    if (current == null) return null;

    emit(DesignTicketDetailState.working(current));

    final result = await action();

    if (isClosed) return null;

    final failure = result.fold<Failure?>((f) => f, (_) => null);

    await load();

    return failure;
  }
}
