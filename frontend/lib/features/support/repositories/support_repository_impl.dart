import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:dayaa/features/support/models/support_ticket.dart';
import 'package:dayaa/features/support/models/ticket_change.dart';
import 'package:dayaa/features/support/repositories/support_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SupportRepositoryImpl implements SupportRepository {
  const SupportRepositoryImpl(this._dio, this._realtime);

  final Dio _dio;
  final RealtimeClient _realtime;

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
  Future<Either<Failure, SupportTicket>> reply(
    int id, {
    String? body,
    PickedFile? attachment,
  }) {
    final text = body?.trim();

    return safeRequest(
      () async => _dio.post<Map<String, dynamic>>(
        SupportEndpoints.messages(id),
        // **JSON للكلام، وmultipart حين يكون ملفاً** — والملف يُقرأ من القرص وهو يُرسل: صورةٌ
        // بخمسةٍ وعشرين ميغابايت في الذاكرة كاملةً تُسقط التطبيق على هاتفٍ متوسط.
        data: attachment == null
            ? {'body': text}
            : FormData.fromMap(<String, dynamic>{
                'file': await MultipartFile.fromFile(attachment.path, filename: attachment.name),
                // يُحذف فارغاً ولا يُرسل نصاً فارغاً: التعليقُ اختياريٌّ مع الملف.
                if (text != null && text.isNotEmpty) 'body': text,
              }),
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

  @override
  Future<Either<Failure, SupportTicket>> reopen(int id) {
    return safeRequest(
      () => _dio.post<Map<String, dynamic>>(SupportEndpoints.reopen(id)),
      parse: _one,
    );
  }

  @override
  Stream<TicketChange> watchChanges() => _realtime
      .privateEvents(SupportEndpoints.deskChannel, SupportEndpoints.changedEvent)
      .map(TicketChange.fromJson)
      // **حمولةٌ لا تُفهم تُسقط وحدها ولا تُسقط التيار.** خادمٌ أحدث من هذا الإصدار قد يرسل
      // شكلاً لا يعرفه، والرسالةُ التالية بعدها صحيحة.
      .handleError((Object error) {
        if (kDebugMode) debugPrint('⚠️ حدثٌ حيّ لم يُفهم: $error');
      });

  @override
  Stream<void> get liveResumed => _realtime.resumed;

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
