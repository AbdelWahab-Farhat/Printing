import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [SupportRepository] over HTTP.
class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<SupportTicket>>> tickets({int page = 1, bool? openOnly}) {
    return safePaginatedRequest<SupportTicket>(
      () => _dio.get(
        SupportEndpoints.tickets,
        queryParameters: <String, dynamic>{
          'page': page,
          // **Three states, not two.** The server reads the key's *absence* as «كل التذاكر»,
          // `1` as the live ones and `0` as the closed — which is why this is a `bool?` all the
          // way down rather than a `bool` that has to pick a side.
          if (openOnly != null) 'open': openOnly ? 1 : 0,
        },
      ),
      parseItem: SupportTicket.fromJson,
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> ticket(int id) {
    return safeRequest<SupportTicket>(
      () => _dio.get(SupportEndpoints.ticket(id)),
      parse: (data) => SupportTicket.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> open({
    required String subject,
    required String body,
    int? orderId,
  }) {
    return safeRequest<SupportTicket>(
      () => _dio.post(
        SupportEndpoints.tickets,
        data: <String, dynamic>{
          'subject': subject,
          'body': body,
          'order_id': ?orderId,
        },
      ),
      parse: (data) => SupportTicket.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, SupportTicket>> reply({required int id, required String body}) {
    return safeRequest<SupportTicket>(
      () => _dio.post(SupportEndpoints.messages(id), data: <String, dynamic>{'body': body}),
      // **The whole thread comes back, not just the message that was added.** A reply can
      // reopen a closed ticket, so the status beside the messages is part of the answer.
      parse: (data) => SupportTicket.fromJson(data as Map<String, dynamic>),
    );
  }
}
