import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// Starts a conversation.
class OpenTicket {
  const OpenTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call({
    required String subject,
    required String body,
    int? orderId,
  }) => _repository.open(subject: subject, body: body, orderId: orderId);
}
