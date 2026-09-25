import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';

/// One page of the customer's threads.
class BrowseTickets {
  const BrowseTickets(this._repository);

  final SupportRepository _repository;

  Future<Either<Failure, Paginated<SupportTicket>>> call({int page = 1, bool? openOnly}) =>
      _repository.tickets(page: page, openOnly: openOnly);
}
