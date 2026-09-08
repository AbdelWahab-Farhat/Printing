import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Tells the server this device may be pushed to.
///
/// Called from exactly one place — `PushService` — at sign-in, when the settings toggle goes on,
/// and on every FCM token rotation.
class RegisterDeviceToken {
  const RegisterDeviceToken(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call({
    required String token,
    required String platform,
  }) => _repository.registerDevice(token: token, platform: platform);
}
