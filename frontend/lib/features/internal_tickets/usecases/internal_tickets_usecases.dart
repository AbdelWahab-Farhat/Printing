import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';

/// أفعالُ التذاكر الداخلية في ملفٍّ واحد، كأفعال الدعم: كلٌّ منها نداءٌ واحد بلا قاعدةٍ خاصة،
/// وتفريقُها في ملفات يكلّف قراءةً أكثر مما يشتري. فعلٌ تنبت له قاعدة يأخذ ملفّه يومها.
class BrowseInternalTickets {
  const BrowseInternalTickets(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, Paginated<InternalTicket>>> call({
    required InternalTicketQuery query,
    String? search,
    int page = 1,
  }) => _repository.tickets(query: query, search: search, page: page);
}

class GetInternalTicketsHome {
  const GetInternalTicketsHome(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicketsHome>> call() => _repository.home();
}

class GetColleagues {
  const GetColleagues(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, List<Colleague>>> call() => _repository.colleagues();
}

class GetInternalCategories {
  const GetInternalCategories(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, List<InternalCategory>>> call() => _repository.categories();
}

class OpenInternalTicket {
  const OpenInternalTicket(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicket>> call(
    InternalTicketDraft draft, {
    List<PickedFile> images = const [],
  }) => _repository.open(draft, images: images);
}

/// **لا يُنادى استباقاً**: قراءةُ المحادثة تعلّمها مقروءةً على الخادم.
class GetInternalTicket {
  const GetInternalTicket(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicket>> call(int id) => _repository.ticket(id);
}

class SendInternalMessage {
  const SendInternalMessage(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicket>> call(int id, OutgoingChatMessage message) =>
      _repository.send(id, message);
}

class EditInternalMessage {
  const EditInternalMessage(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, ChatMessage>> call(int id, int messageId, String body) =>
      _repository.edit(id, messageId, body);
}

class RetractInternalMessage {
  const RetractInternalMessage(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, ChatMessage>> call(int id, int messageId) =>
      _repository.retract(id, messageId);
}

class MarkInternalTicketRead {
  const MarkInternalTicketRead(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, Unit>> call(int id, {int? upToMessageId}) =>
      _repository.markRead(id, upToMessageId: upToMessageId);
}

class CloseInternalTicket {
  const CloseInternalTicket(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicket>> call(int id) => _repository.close(id);
}

class TransferInternalTicket {
  const TransferInternalTicket(this._repository);

  final InternalTicketsRepository _repository;

  Future<Either<Failure, InternalTicket>> call(int id, {required int newOwnerId}) =>
      _repository.transfer(id, newOwnerId: newOwnerId);
}

/// التذاكرُ حيّة: محادثةٌ واحدة ([ticket])، وإشاراتُ ما أنا طرفٌ فيه ([mine])، و[resumed] حين يعود
/// الاتصال بعد انقطاع.
class WatchInternalTickets {
  const WatchInternalTickets(this._repository);

  final InternalTicketsRepository _repository;

  Stream<InternalTicketChange> ticket(int id) => _repository.watchTicket(id);

  Stream<int> mine(int userId) => _repository.watchMine(userId);

  Stream<void> get resumed => _repository.liveResumed;
}
