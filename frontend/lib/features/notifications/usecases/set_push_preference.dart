import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Turns one push switch on or off for an employee. The bell is never switched off.
class SetPushPreference {
  const SetPushPreference(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, List<PushPreferenceGroup>>> call({
    required int userId,
    required String type,
    required String scope,
    required bool push,
  }) => _repository.setPushPreference(userId: userId, type: type, scope: scope, push: push);
}
