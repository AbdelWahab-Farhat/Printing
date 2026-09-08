import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [NotificationsRepository] over HTTP — the only file in this feature importing `dio`.
class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<AppNotification>>> list({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 15,
  }) {
    return safePaginatedRequest<AppNotification>(
      () => _dio.get(
        NotificationEndpoints.list,
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Sent only when narrowing. The server reads it with `boolean()`, so an explicit
          // `false` would work too — but an absent parameter is what "no filter" means, and it
          // keeps the request URL honest about what was asked for.
          if (unreadOnly) 'unread': true,
        },
      ),
      parseItem: AppNotification.fromJson,
    );
  }

  @override
  Future<Either<Failure, UnreadCount>> unreadCount() {
    return safeRequest<UnreadCount>(
      () => _dio.get(NotificationEndpoints.unreadCount),
      parse: (data) => UnreadCount.fromJson(data as Map<String, dynamic>),
    );
  }

  /// [safeCommand] rather than [safeRequest]: the answer is the message, not a body.
  ///
  /// A 404 here is the ordinary refusal for somebody else's notification, and travels back as a
  /// plain [Failure] like any other — there is nothing special for a caller to detect.
  @override
  Future<Either<Failure, String>> markRead(int id) {
    return safeCommand(() => _dio.post(NotificationEndpoints.read(id)));
  }

  @override
  Future<Either<Failure, String>> markAllRead() {
    return safeCommand(() => _dio.post(NotificationEndpoints.readAll));
  }

  @override
  Future<Either<Failure, String>> registerDevice({
    required String token,
    required String platform,
  }) {
    return safeCommand(
      () => _dio.post(
        NotificationEndpoints.devices,
        data: <String, dynamic>{'token': token, 'platform': platform},
      ),
    );
  }

  /// The token travels in the **body of a DELETE**, which is unusual enough to note: it is a
  /// credential-shaped string and has no business sitting in a URL, where it would land in every
  /// access log between here and the server.
  @override
  Future<Either<Failure, String>> releaseDevice({required String token}) {
    return safeCommand(
      () => _dio.delete(
        NotificationEndpoints.devices,
        data: <String, dynamic>{'token': token},
      ),
    );
  }

  @override
  Future<Either<Failure, String>> sendAnnouncement({
    required String title,
    required String body,
    int? roleId,
  }) {
    return safeCommand(
      () => _dio.post(
        NotificationEndpoints.announcements,
        data: <String, dynamic>{
          'title': title,
          'body': body,
          // Omitted, not null, when it is for everyone: the rule is `sometimes|nullable`, so
          // both are accepted — but an absent key is what «الجميع» means and reads that way in
          // a request log. The `?` drops the pair entirely when the value is null.
          'role_id': ?roleId,
        },
      ),
    );
  }
}
