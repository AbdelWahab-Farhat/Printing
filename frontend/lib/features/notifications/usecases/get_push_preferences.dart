import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// An employee's push switches, for the group notifications they can receive.
class GetPushPreferences {
  const GetPushPreferences(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, List<PushPreferenceGroup>>> call(int userId) =>
      _repository.pushPreferences(userId);
}
