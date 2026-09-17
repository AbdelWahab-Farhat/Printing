import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// One thread, opened — **which is also what marks it read**, on the server.
class GetTicket {
  const GetTicket(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, SupportTicket>> call(int id) => _repository.ticket(id);
}
