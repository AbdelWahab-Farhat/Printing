import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dio/dio.dart';

/// تذاكر التصميم, as this app asks about them.
///
/// **The list is already narrowed to what the reader may see.** Without `design_tickets.view_all`
/// the server answers with the tickets they raised, the ones addressed to them, the ones they
/// took, and the unclaimed pool — and a colleague's ticket is a **404**, not a 403, on every
/// route that names one. There is nothing for the app to filter out, and nothing to interpret: a
/// 404 here means «ليست لك», not «غير موجودة».
///
/// **There is no `changeStatus`, and that is not an omission.** No endpoint sets a status: each
/// one is written by the action that earns it — [accept], [submitVersion], [reviewVersion],
/// [cancel]. A ticket can therefore never claim it was accepted with nobody's name against it.
///
/// Sorted newest first, always, and there is no sort parameter. Closed tickets are not buried:
/// the chip row above the list is what makes the historical record readable instead.
abstract interface class DesignTicketRepository {
  /// One page of them.
  ///
  /// [designer] takes a user id as a string, **`'me'`** or **`'none'`** — two of the three are
  /// not ids: «me» is only knowable on the server from the bearer token, and «none» — the shared
  /// pool — is a null a query string cannot otherwise carry.
  ///
  /// [search] matches the ticket's title, its code (`D7`), **or the customer's name** — which is
  /// the snapshot on the ticket, so searching by customer costs the reader no grant on customers.
  Future<Either<Failure, Paginated<DesignTicket>>> tickets({
    List<String> statuses = const <String>[],
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  /// How many sit in each status, under the same filters as the list.
  ///
  /// **`status` is not among them, by the server's own design**: the row answers «what *else* is
  /// there?», so narrowing it by the status already on screen would make every chip but one read
  /// zero. Every other filter is kept — hand the whole question over without stripping anything.
  Future<Either<Failure, DesignTicketCounts>> statusCounts({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  });

  /// One ticket with its brief, every attachment and every version ever uploaded — including the
  /// ones turned back, each with the note saying why. The only endpoint that sends those lists.
  Future<Either<Failure, DesignTicket>> ticket(int ticketId);

  /// Raising one.
  ///
  /// [assignedDesignerId] is optional and **null is the shared pool** — a real answer rather than
  /// a missing one: every designer is told, and the first to accept takes it.
  ///
  /// Naming a designer needs `design_tickets.assign`. Without it the server **drops the field and
  /// creates the ticket anyway** rather than refusing the whole request, so a screen that offers
  /// the picker to somebody who may not use it loses nothing but the preference.
  Future<Either<Failure, DesignTicket>> create({
    required int customerId,
    required String title,
    required String description,
    String? instructions,
    int? orderId,
    int? assignedDesignerId,
  });

  /// Correcting the words.
  ///
  /// **The customer cannot be changed and neither can the designer** — the first because files
  /// and a conversation hang off a ticket by the time anybody notices, the second because it is
  /// [assign] behind its own grant. Refused outright once the ticket is closed.
  Future<Either<Failure, DesignTicket>> update(
    int ticketId, {
    required String title,
    required String description,
    String? instructions,
  });

  /// Handing it to a designer, or returning it to the pool — `null` is the pool.
  ///
  /// **It does not start the work.** A ticket addressed to somebody who has not said yes is still
  /// «جديد»; the claim that work has begun is the designer's to make by accepting.
  Future<Either<Failure, DesignTicket>> assign(int ticketId, {required int? designerId});

  /// «قبول الطلب» — the designer takes it.
  ///
  /// **Exactly one acceptance is possible**, settled on the server by a conditional update rather
  /// than by a check. A designer who loses the race gets a 422 **naming whoever holds it**, which
  /// is the message to show as sent: it is the answer to «من أخذها؟».
  Future<Either<Failure, DesignTicket>> accept(int ticketId);

  /// Calling a request off. The reason is required.
  ///
  /// **Not a way to reject a design** — that is [reviewVersion] with `changes_requested`, which
  /// keeps the ticket alive. Versions already uploaded stay exactly where they are.
  Future<Either<Failure, DesignTicket>> cancel(int ticketId, {required String reason});

  /// Adding one of the employee's reference files.
  ///
  /// Allowed for as long as the ticket is open, not only at creation: «هذا مثال لما أقصده»
  /// arrives mid-revision at least as often as it arrives with the original request.
  Future<Either<Failure, DesignTicketFile>> attach(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  });

  /// Removing one. Hides it; the file itself is kept, because a designer may be working from it.
  ///
  /// **Only a brief can be removed** — naming a version is a 404, because a version is a
  /// statement in a conversation and deleting one would leave a change request pointing at
  /// nothing.
  Future<Either<Failure, Unit>> removeAttachment(int ticketId, int attachmentId);

  /// The designer's work.
  ///
  /// **The same call sends the first version and every revision** — a revision is a row, not a
  /// new ticket — and the version number is allocated by the server, never sent. Refused before
  /// the ticket has been accepted, and refused while another version is already under review.
  Future<Either<Failure, DesignTicketFile>> submitVersion(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  });

  /// The verdict.
  ///
  /// `approved` closes the ticket and files the artwork on the customer's account;
  /// `changes_requested` sends it back and **requires [note]**, because a change request with no
  /// words turns the history into a count.
  ///
  /// **Refused to whoever uploaded the version, even an administrator.** Read `canReview` on the
  /// ticket rather than a permission: it already answers this, so the buttons are never drawn for
  /// the person the server will refuse.
  Future<Either<Failure, DesignTicketFile>> reviewVersion(
    int ticketId,
    int versionId, {
    required String verdict,
    String? note,
  });
}
