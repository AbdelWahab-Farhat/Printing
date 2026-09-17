import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dio/dio.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({
    int page = 1,
    TicketStatus? status,
    int? assignedTo,
  }) {
    return safePaginatedRequest(
      () => _dio.get<Map<String, dynamic>>(
        SupportEndpoints.tickets,
        queryParameters: {
          'page': page,
          // **The wire value, written out rather than `status.name`.** The Dart member is
          // `inProgress` and the server says `in_progress`; `name` would silently narrow the
          // queue to nothing, which reads as «لا تذاكر» rather than as a bug.
          'status': ?_wire(status),
          'assigned_to': ?assignedTo,
        },
      ),
      parseItem: SupportTicket.fromJson,
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> ticket(int id) {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(SupportEndpoints.ticket(id)),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> reply(int id, {required String body}) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        SupportEndpoints.messages(id),
        data: {'body': body},
      ),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> assign(int id, {required int? userId}) {
    return safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        SupportEndpoints.assignment(id),
        // **Sent even when null**, which is why this is not `?userId`: the server validates
        // `present`, and omitting the key is «لم أذكر» rather than «ارفعها عن المكتب». Null is
        // the instruction to unassign.
        data: {'assigned_to': userId},
      ),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> close(int id) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(SupportEndpoints.close(id)),
      parse: _one,
    );
  }

  /// One ticket out of an envelope's `data`.
  static SupportTicket _one(dynamic data) =>
      SupportTicket.fromJson(data as Map<String, dynamic>);

  /// The string the API filters on, or null for «no filter».
  ///
  /// [TicketStatus.unknown] is deliberately no filter: it is not a state the business has, and
  /// asking the server for it would return an empty queue that looks like an answer.
  static String? _wire(TicketStatus? status) => switch (status) {
    null || TicketStatus.unknown => null,
    TicketStatus.open => 'open',
    TicketStatus.inProgress => 'in_progress',
    TicketStatus.closed => 'closed',
  };
}
