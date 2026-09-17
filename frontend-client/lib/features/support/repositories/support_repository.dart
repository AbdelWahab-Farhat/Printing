import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';

/// Reaching a person.
abstract interface class SupportRepository {
  /// The customer's own threads, most recently active first.
  ///
  /// [openOnly] null means everything; `true` the live ones, `false` the closed.
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({int page, bool? openOnly});

  /// One thread, oldest message first.
  ///
  /// **Reading it marks it read** — the server does that on this call, which is why there is no
  /// «mark as read» endpoint for this app to forget on the screen where it matters.
  Future<Either<Failure, SupportTicket>> ticket(int id);

  /// Starts a conversation. [orderId] must be one of the customer's own orders — the server
  /// resolves it through them, so somebody else's id is a 404 rather than a ticket quietly
  /// attached to a stranger's order.
  Future<Either<Failure, SupportTicket>> open({
    required String subject,
    required String body,
    int? orderId,
  });

  /// Replies.
  ///
  /// **A reply to a closed ticket reopens it**, and that is the server's decision, not this
  /// app's: a thread somebody is still writing into is closed on paper and open in fact, and
  /// that gap is where a customer gets ignored.
  Future<Either<Failure, SupportTicket>> reply({required int id, required String body});
}
