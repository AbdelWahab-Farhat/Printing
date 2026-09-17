import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_counts.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_repository.dart';
import 'package:dio/dio.dart';

/// One page of the تذاكر التصميم list.
class GetDesignTickets {
  const GetDesignTickets(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, Paginated<DesignTicket>>> call({
    List<DesignTicketStatus> statuses = const <DesignTicketStatus>[],
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
    int page = 1,
  }) {
    return _repository.tickets(
      // Wire values, and never [DesignTicketStatus.unknown]: its wire is the empty string, which
      // the server would read as a status it cannot parse.
      statuses: [
        for (final wanted in statuses)
          if (wanted != DesignTicketStatus.unknown) wanted.wire,
      ],
      designer: designer,
      requestedBy: requestedBy,
      customerId: customerId,
      orderId: orderId,
      search: search,
      page: page,
    );
  }
}

/// The numbers behind the chip row.
///
/// **It takes no status**, and that is the row's whole shape: it answers «what else is there?»,
/// so narrowing it by the status already on screen would make every chip but one read zero.
class GetDesignTicketCounts {
  const GetDesignTicketCounts(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicketCounts>> call({
    String? designer,
    String? requestedBy,
    int? customerId,
    int? orderId,
    String? search,
  }) {
    return _repository.statusCounts(
      designer: designer,
      requestedBy: requestedBy,
      customerId: customerId,
      orderId: orderId,
      search: search,
    );
  }
}

/// One ticket, with its attachments and every version.
class GetDesignTicket {
  const GetDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call(int ticketId) => _repository.ticket(ticketId);
}

/// Raising a request for artwork.
class CreateDesignTicket {
  const CreateDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call({
    required int customerId,
    required String title,
    required String description,
    String? instructions,
    int? orderId,
    int? assignedDesignerId,
  }) {
    return _repository.create(
      customerId: customerId,
      title: title,
      description: description,
      instructions: instructions,
      orderId: orderId,
      assignedDesignerId: assignedDesignerId,
    );
  }
}

/// Correcting the words of an open request.
class UpdateDesignTicket {
  const UpdateDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call(
    int ticketId, {
    required String title,
    required String description,
    String? instructions,
  }) {
    return _repository.update(
      ticketId,
      title: title,
      description: description,
      instructions: instructions,
    );
  }
}

/// Routing a ticket to a designer, or returning it to the shared pool.
class AssignDesignTicket {
  const AssignDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call(int ticketId, {required int? designerId}) =>
      _repository.assign(ticketId, designerId: designerId);
}

/// «قبول الطلب».
class AcceptDesignTicket {
  const AcceptDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call(int ticketId) => _repository.accept(ticketId);
}

/// Calling a request off, with the reason it requires.
class CancelDesignTicket {
  const CancelDesignTicket(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicket>> call(int ticketId, {required String reason}) =>
      _repository.cancel(ticketId, reason: reason);
}

/// Adding one of the employee's reference files.
class AttachDesignTicketFile {
  const AttachDesignTicketFile(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicketFile>> call(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) {
    return _repository.attach(
      ticketId,
      path: path,
      filename: filename,
      note: note,
      onProgress: onProgress,
    );
  }
}

/// Removing one. Only a brief — a version is never deleted.
class RemoveDesignTicketAttachment {
  const RemoveDesignTicketAttachment(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, Unit>> call(int ticketId, int attachmentId) =>
      _repository.removeAttachment(ticketId, attachmentId);
}

/// Sending the designer's work up for review — the first version or the next one.
class SubmitDesignVersion {
  const SubmitDesignVersion(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicketFile>> call(
    int ticketId, {
    required String path,
    required String filename,
    String? note,
    ProgressCallback? onProgress,
  }) {
    return _repository.submitVersion(
      ticketId,
      path: path,
      filename: filename,
      note: note,
      onProgress: onProgress,
    );
  }
}

/// The verdict on one version.
///
/// **The note is required with `changesRequested` and this does not check it** — the server's 422
/// carries the Arabic message and lands under the field, which is the answer the reviewer needs.
/// A check here would only duplicate a rule that has to exist there anyway.
class ReviewDesignVersion {
  const ReviewDesignVersion(this._repository);

  final DesignTicketRepository _repository;

  Future<Either<Failure, DesignTicketFile>> call(
    int ticketId,
    int versionId, {
    required DesignSubmissionStatus verdict,
    String? note,
  }) {
    return _repository.reviewVersion(
      ticketId,
      versionId,
      verdict: switch (verdict) {
        DesignSubmissionStatus.approved => 'approved',
        DesignSubmissionStatus.changesRequested => 'changes_requested',
        // Neither is a verdict a person may send: `proposed` is where a version arrives, and
        // `unknown` names nothing. Sent as-is so the server refuses it in its own words rather
        // than this layer inventing a message for a call that should never have been made.
        _ => '',
      },
      note: note,
    );
  }
}
