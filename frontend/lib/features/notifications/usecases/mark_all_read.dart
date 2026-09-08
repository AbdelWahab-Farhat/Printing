import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Empties the badge in one call.
class MarkAllRead {
  const MarkAllRead(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call() => _repository.markAllRead();
}
