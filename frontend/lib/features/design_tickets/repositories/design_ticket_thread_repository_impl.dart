import 'package:dartz/dartz.dart';
import 'package:dayaa/core/chat/chat_message.dart';
import 'package:dayaa/core/chat/outgoing_chat_payload.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_thread.dart';
import 'package:dayaa/features/design_tickets/repositories/design_ticket_thread_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// ينفّذ [DesignTicketThreadRepository] فوق HTTP والمقبس — على شكل `InternalTicketsRepositoryImpl`.
class DesignTicketThreadRepositoryImpl implements DesignTicketThreadRepository {
  const DesignTicketThreadRepositoryImpl(this._dio, this._realtime);

  final Dio _dio;
  final RealtimeClient _realtime;

  @override
  Future<Either<Failure, DesignTicketThread>> thread(int ticketId) {
    return safeRequest(
      () => _dio.get<Map<String, dynamic>>(DesignTicketEndpoints.messages(ticketId)),
      parse: _thread,
    );
  }

  @override
  Future<Either<Failure, DesignTicketThread>> send(int ticketId, OutgoingChatMessage message) {
    return safeRequest(
      () async => _dio.post<Map<String, dynamic>>(
        DesignTicketEndpoints.messages(ticketId),
        data: await outgoingChatPayload(message),
      ),
      parse: _thread,
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> edit(int ticketId, int messageId, String body) {
    return safeRequest(
      () => _dio.patch<Map<String, dynamic>>(
        DesignTicketEndpoints.message(ticketId, messageId),
        data: {'body': body.trim()},
      ),
      parse: _message,
    );
  }

  @override
  Future<Either<Failure, ChatMessage>> retract(int ticketId, int messageId) {
    return safeRequest(
      () => _dio.delete<Map<String, dynamic>>(DesignTicketEndpoints.message(ticketId, messageId)),
      parse: _message,
    );
  }

  @override
  Future<Either<Failure, int>> markRead(int ticketId, {int? upToMessageId}) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(
        DesignTicketEndpoints.messagesRead(ticketId),
        data: {'up_to_message_id': ?upToMessageId},
      ),
      // `unread_total`: رقمُ الجرس كما صار، فلا يُسأل `unread-count` ثانيةً.
      parse: (data) => ((data! as Map<String, dynamic>)['unread_total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Stream<DesignTicketThreadChange> watch(int ticketId) => _realtime
      .privateEvents(DesignTicketEndpoints.channel(ticketId), DesignTicketEndpoints.changedEvent)
      .map(DesignTicketThreadChange.fromJson)
      // حمولةٌ لا تُفهم تُسقط وحدها ولا تُسقط التيار، كبثّ التذاكر الداخلية.
      .handleError((Object error) {
        if (kDebugMode) debugPrint('⚠️ حدثٌ حيّ لم يُفهم: $error');
      });

  @override
  Stream<void> get liveResumed => _realtime.resumed;

  static DesignTicketThread _thread(dynamic data) =>
      DesignTicketThread.fromJson(data as Map<String, dynamic>);

  static ChatMessage _message(dynamic data) => ChatMessage.fromJson(data as Map<String, dynamic>);
}
