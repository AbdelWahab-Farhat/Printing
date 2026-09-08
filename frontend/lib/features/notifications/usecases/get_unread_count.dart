import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/models/unread_count.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// The number on the bell.
class GetUnreadCount {
  const GetUnreadCount(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, UnreadCount>> call() => _repository.unreadCount();
}
