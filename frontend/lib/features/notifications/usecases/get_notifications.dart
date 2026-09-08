import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// One page of this account's mailbox, newest first.
class GetNotifications {
  const GetNotifications(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, Paginated<AppNotification>>> call({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 15,
  }) => _repository.list(unreadOnly: unreadOnly, page: page, perPage: perPage);
}
