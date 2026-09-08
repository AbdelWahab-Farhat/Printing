import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Marks one notification read.
///
/// A 404 means the id is not this account's mail. Ordinary, not exceptional — see
/// [NotificationsRepository].
class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call(int id) => _repository.markRead(id);
}
