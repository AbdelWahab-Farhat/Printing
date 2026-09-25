import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/files/picked_file.dart';
import 'package:dayaa_client/core/files/transfer_cancel.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/core/realtime/realtime_client.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fulfils [SupportRepository] over HTTP.
class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._dio, this._realtime, this._tokens);

  final Dio _dio;
  final RealtimeClient _realtime;
  final TokenStorage _tokens;

  /// قناتي، والرمزُ الذي عُرفت به — رمزٌ آخر عميلٌ آخر، فتُسأل من جديد.
  String? _channel;
  String? _channelToken;

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
  Future<Either<Failure, SupportTicket>> reply({
    required int id,
    String body = '',
    PickedFile? file,
    String? clientToken,
    void Function(double progress)? onProgress,
    TransferCancel? cancel,
  }) async {
    final token = CancelToken();
    if (cancel != null) unawaited(cancel.whenCancelled.then((_) => token.cancel()));

    final text = body.trim();
    final fields = <String, dynamic>{
      if (text.isNotEmpty) 'body': text,
      'client_token': ?clientToken,
    };

    return safeRequest<SupportTicket>(
      () async => _dio.post(
        SupportEndpoints.messages(id),
        // `multipart/form-data` للملف، لأن الخادم يقرأ بايتاته بـfinfo لا اسمه ولا ادّعاءه.
        data: file == null
            ? fields
            : FormData.fromMap({
                ...fields,
                'file': await MultipartFile.fromFile(file.path, filename: file.name),
              }),
        cancelToken: token,
        // صورةٌ من الكاميرا أو ملفُّ تصميم على اتصالٍ بطيء لا يُرفع في ثلاثين ثانية — مهلة
        // الطلبات العادية. تُمدّ لهذا الطلب وحده.
        options: file == null ? null : Options(sendTimeout: const Duration(minutes: 5)),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      ),
      // **The whole thread comes back, not just the message that was added.** A reply can
      // reopen a closed ticket, so the status beside the messages is part of the answer.
      parse: (data) => SupportTicket.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Stream<TicketChange> watchChanges() async* {
    final channel = await _myChannel();
    if (channel == null) return;

    yield* _realtime
        .privateEvents(channel, SupportEndpoints.changedEvent)
        .map(TicketChange.fromJson)
        // **حمولةٌ لا تُفهم تُسقط وحدها ولا تُسقط التيار**: خادمٌ أحدث من هذا الإصدار قد يرسل
        // شكلاً لا يعرفه، والرسالةُ التالية بعدها صحيحة.
        .handleError((Object error) {
          if (kDebugMode) debugPrint('⚠️ حدثٌ حيّ لم يُفهم: $error');
        });
  }

  @override
  Stream<void> get liveResumed => _realtime.resumed;

  /// اسمُ قناتي، من رقمي عند الخادم. **يُسأل مرةً لكل رمز دخول**، وبلا جلسةٍ لا قناة.
  Future<String?> _myChannel() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) return null;

    final known = _channel;
    if (known != null && token == _channelToken) return known;

    final result = await safeRequest<int>(
      () => _dio.get(AuthEndpoints.me),
      parse: (data) => (data as Map<String, dynamic>)['id'] as int,
    );

    return result.fold((_) => null, (id) {
      _channelToken = token;

      return _channel = SupportEndpoints.customerChannel(id);
    });
  }
}
