import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_thread_repository.dart';

/// أفعالُ محادثة التذكرة في ملفٍّ واحد، كأفعال التذاكر الداخلية: كلٌّ منها نداءٌ واحد بلا قاعدةٍ
/// خاصة. فعلٌ تنبت له قاعدة يأخذ ملفّه يومها.

/// **لا يُنادى استباقاً**: قراءةُ المحادثة تعلّمها مقروءةً على الخادم.
class GetDesignTicketThread {
  const GetDesignTicketThread(this._repository);

  final DesignTicketThreadRepository _repository;

  Future<Either<Failure, DesignTicketThread>> call(int ticketId) => _repository.thread(ticketId);
}

class SendDesignTicketMessage {
  const SendDesignTicketMessage(this._repository);

  final DesignTicketThreadRepository _repository;

  Future<Either<Failure, DesignTicketThread>> call(int ticketId, OutgoingChatMessage message) =>
      _repository.send(ticketId, message);
}

class EditDesignTicketMessage {
  const EditDesignTicketMessage(this._repository);

  final DesignTicketThreadRepository _repository;

  Future<Either<Failure, ChatMessage>> call(int ticketId, int messageId, String body) =>
      _repository.edit(ticketId, messageId, body);
}

class RetractDesignTicketMessage {
  const RetractDesignTicketMessage(this._repository);

  final DesignTicketThreadRepository _repository;

  Future<Either<Failure, ChatMessage>> call(int ticketId, int messageId) =>
      _repository.retract(ticketId, messageId);
}

class MarkDesignTicketThreadRead {
  const MarkDesignTicketThreadRead(this._repository);

  final DesignTicketThreadRepository _repository;

  Future<Either<Failure, int>> call(int ticketId, {int? upToMessageId}) =>
      _repository.markRead(ticketId, upToMessageId: upToMessageId);
}

/// المحادثةُ حيّة: ما يتغيّر فيها ([thread])، و[resumed] حين يعود الاتصال بعد انقطاع.
class WatchDesignTicketThread {
  const WatchDesignTicketThread(this._repository);

  final DesignTicketThreadRepository _repository;

  Stream<DesignTicketThreadChange> thread(int ticketId) => _repository.watch(ticketId);

  Stream<void> get resumed => _repository.liveResumed;
}
