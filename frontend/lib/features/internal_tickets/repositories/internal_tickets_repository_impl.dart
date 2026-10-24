import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/outgoing_chat_payload.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/repositories/internal_tickets_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class InternalTicketsRepositoryImpl implements InternalTicketsRepository {
  const InternalTicketsRepositoryImpl(this._dio, this._realtime);

  final Dio _dio;
  final RealtimeClient _realtime;

  @override
  Future<Either<Failure, Paginated<InternalTicket>>> tickets({
    required InternalTicketQuery query,
    String? search,
    int page = 1,
  }) {
    return safePaginatedRequest(
      () => _dio.get<Map<String, dynamic>>(
        InternalTicketEndpoints.tickets,
        queryParameters: query.toQuery(search: search, page: page),
      ),
      parseItem: InternalTicket.fromJson,
    );
  }

  @override
  Future<Either<Failure, InternalTicketsHome>> home() {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(InternalTicketEndpoints.home),
      parse: (data) => InternalTicketsHome.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<Colleague>>> colleagues() {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(InternalTicketEndpoints.colleagues),
      parse: (data) => [
        for (final row in data as List<dynamic>) Colleague.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<Either<Failure, List<InternalCategory>>> categories() {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(InternalTicketEndpoints.categories),
      parse: (data) => [
        for (final row in data as List<dynamic>)
          InternalCategory.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<Either<Failure, InternalTicket>> open(
    InternalTicketDraft draft, {
    List<PickedFile> images = const [],
  }) {
    final fields = <String, dynamic>{
      'assignee_id': draft.assigneeId,
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'priority': draft.priority.wire,
      'category_id': ?draft.categoryId,
      'customer_id': ?draft.customerId,
      'order_id': ?draft.orderId,
    };

    return safeRequest(
      () async => _dio.post<Map<String, dynamic>>(
        InternalTicketEndpoints.tickets,
        // **JSON بلا صور، وmultipart بها** — والصورُ تُقرأ من القرص وهي تُرسل، لا كاملةً في الذاكرة.
        // و`multiCompatible` يكتب `images[]=` لكل صورة — الصيغةُ الافتراضية تكرّر المفتاح بلا
        // قوسين، وPHP يرمي كلَّ القيم إلا الأخيرة (RULES §٦، القاعدة ٧).
        data: images.isEmpty
            ? fields
            : FormData.fromMap({
                ...fields,
                'images': [
                  for (final image in images)
                    await LocalFiles.multipart(image.path, filename: image.name),
                ],
              }, ListFormat.multiCompatible),
      ),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, InternalTicket>> ticket(int id) {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(InternalTicketEndpoints.ticket(id)),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, InternalTicket>> send(int id, OutgoingChatMessage message) {
    return safeRequest(
      () async => _dio.post<Map<String, dynamic>>(
        InternalTicketEndpoints.messages(id),
        data: await outgoingChatPayload(message),
      ),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> edit(int id, int messageId, String body) {
    return safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        InternalTicketEndpoints.message(id, messageId),
        data: {'body': body.trim()},
      ),
      parse: _message,
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> retract(int id, int messageId) {
    return safeRequest(
      () => _dio.delete<Map<String, dynamic>>(InternalTicketEndpoints.message(id, messageId)),
      parse: _message,
    );
  }

  @override
  Future<Either<Failure, Unit>> markRead(int id, {int? upToMessageId}) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        InternalTicketEndpoints.read(id),
        data: {'up_to_message_id': ?upToMessageId},
      ),
      parse: (_) => unit,
    );
  }

  @override
  Future<Either<Failure, InternalTicket>> close(int id) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(InternalTicketEndpoints.close(id)),
      parse: _one,
    );
  }

  @override
  Future<Either<Failure, InternalTicket>> transfer(int id, {required int newOwnerId}) {
    return safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        InternalTicketEndpoints.transfer(id),
        data: {'new_owner_id': newOwnerId},
      ),
      parse: _one,
    );
  }

  @override
  Stream<InternalTicketChange> watchTicket(int id) => _realtime
      .privateEvents(InternalTicketEndpoints.channel(id), InternalTicketEndpoints.changedEvent)
      .map(InternalTicketChange.fromJson)
      // حمولةٌ لا تُفهم تُسقط وحدها ولا تُسقط التيار، كبثّ الدعم.
      .handleError((Object error) {
        if (kDebugMode) debugPrint('⚠️ حدثٌ حيّ لم يُفهم: $error');
      });

  @override
  Stream<int> watchMine(int userId) => _realtime
      .privateEvents(
        InternalTicketEndpoints.staffChannel(userId),
        InternalTicketEndpoints.homeChangedEvent,
      )
      .map((payload) => (payload['ticket_id'] as num).toInt())
      .handleError((Object error) {
        if (kDebugMode) debugPrint('⚠️ إشارةٌ حيّة لم تُفهم: $error');
      });

  @override
  Stream<void> get liveResumed => _realtime.resumed;

  static InternalTicket _one(dynamic data) => InternalTicket.fromJson(data as Map<String, dynamic>);

  static ChatMessage _message(dynamic data) =>
      ChatMessage.fromJson(data as Map<String, dynamic>);
}
