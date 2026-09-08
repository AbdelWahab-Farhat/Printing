import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';

/// Tells the server to stop pushing to this device.
///
/// **At sign-out this is not optional.** One counter phone passes between employees; a
/// registration left behind delivers the previous user's notifications to the next one.
class ReleaseDeviceToken {
  const ReleaseDeviceToken(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call({required String token}) =>
      _repository.releaseDevice(token: token);
}
