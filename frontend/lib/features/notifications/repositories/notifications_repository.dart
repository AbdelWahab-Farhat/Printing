import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';

/// Every account's own mailbox, and the device registry that lets a push reach it.
///
/// **Reading takes no permission and no id of anybody else's mail.** The scoping is done by the
/// server removing the surface rather than by a check, so there is no "whose notifications"
/// parameter here to get wrong — [list] is always *this* account's.
///
/// A foreign notification id answers **404, not 403**, and [markRead] passes that through as an
/// ordinary failure. It is not a bug to chase: a 403 would confirm the id names something real.
abstract interface class NotificationsRepository {
  /// Newest first. [unreadOnly] narrows to what has not been read yet.
  Future<Either<Failure, Paginated<AppNotification>>> list({
    bool unreadOnly,
    int page,
    int perPage,
  });

  /// What the bell draws. Deliberately its own cheap endpoint — the badge must never pay for a
  /// page of notifications to learn a number.
  Future<Either<Failure, UnreadCount>> unreadCount();

  Future<Either<Failure, String>> markRead(int id);

  Future<Either<Failure, String>> markAllRead();

  /// Registers this device against the signed-in account, so a push can find it.
  ///
  /// Called on sign-in, when the settings toggle goes on, and on every FCM token rotation —
  /// the same token arriving twice is the server's problem to make idempotent, not a reason
  /// for the app to remember what it last sent.
  Future<Either<Failure, String>> registerDevice({
    required String token,
    required String platform,
  });

  /// Drops this device's registration.
  ///
  /// **The one that must not be forgotten, at sign-out.** Skip it and a shared counter phone
  /// keeps receiving the previous employee's notifications — a live data leak in a shop where
  /// one phone passes between people, not an untidiness.
  Future<Either<Failure, String>> releaseDevice({required String token});

  /// Interrupts every phone in the company at once. Guarded by `notifications.broadcast`
  /// server-side, and throttled there too — a 429 is a rapid second send, not a fault.
  ///
  /// [roleId] null means everyone; otherwise just that role.
  Future<Either<Failure, String>> sendAnnouncement({
    required String title,
    required String body,
    int? roleId,
  });
}
