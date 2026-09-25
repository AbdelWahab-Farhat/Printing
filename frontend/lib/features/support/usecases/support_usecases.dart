import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';

/// One file for the desk's verbs.
///
/// **Five classes rather than five files**, which is a departure from the one-per-file habit
/// elsewhere: each of these is a single call with no logic of its own, and the feature is small
/// enough that scattering them costs more to read than it buys. A use case that grows a rule —
/// the way `DesignRules` did — earns its own file then.
class BrowseTickets {
  const BrowseTickets(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, Paginated<SupportTicket>>> call({
    int page = 1,
    TicketStatus? status,
    int? assignedTo,
  }) => _repository.tickets(page: page, status: status, assignedTo: assignedTo);
}

/// **Not safe to call speculatively.** Reading a thread marks the desk's side read on the
/// server, so prefetching one would clear an unread badge nobody looked at.
class GetTicket {
  const GetTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call(int id) => _repository.ticket(id);
}

class ReplyToTicket {
  const ReplyToTicket(this._repository);

  final SupportRepository _repository;

  /// كلامٌ، أو ملفٌ بتعليقٍ اختياري.
  Future<Either<Failure, SupportTicket>> call(
    int id, {
    String? body,
    PickedFile? attachment,
  }) => _repository.reply(id, body: body, attachment: attachment);
}

class AssignTicket {
  const AssignTicket(this._repository);

  final SupportRepository _repository;

  /// [userId] null puts the ticket back in the unassigned queue.
  Future<Either<Failure, SupportTicket>> call(int id, {required int? userId}) =>
      _repository.assign(id, userId: userId);
}

class CloseTicket {
  const CloseTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call(int id) => _repository.close(id);
}

/// إعادةُ فتح ما أغلقه المكتب — الموظف لا يكتب في المغلقة إلا بعدها.
class ReopenTicket {
  const ReopenTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call(int id) => _repository.reopen(id);
}

/// المكتبُ حيّاً: كلُّ تذكرةٍ تتغيّر ساعةَ تتغيّر، و[resumed] حين يعود الاتصال بعد انقطاع.
class WatchTicketChanges {
  const WatchTicketChanges(this._repository);

  final SupportRepository _repository;

  Stream<TicketChange> call() => _repository.watchChanges();

  /// ما تغيّر في الانقطاع فات — من يرسم تذكرةً يعيد قراءتها هنا.
  Stream<void> get resumed => _repository.liveResumed;
}
