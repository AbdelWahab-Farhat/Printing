import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// Replies to a thread. A reply to a closed one reopens it — the server's decision, and the
/// refreshed ticket says so.
class ReplyToTicket {
  const ReplyToTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call({required int id, required String body}) =>
      _repository.reply(id: id, body: body);
}
