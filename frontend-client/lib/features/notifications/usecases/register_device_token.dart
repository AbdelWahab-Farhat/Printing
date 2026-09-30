import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/notifications/repositories/notifications_repository.dart';

/// يخبر الخادم أنّ هذا الجهاز يُدفَع إليه.
///
/// يُستدعى من مكانٍ واحد — `PushService` — عند الدخول، وعند فتح التطبيق بجلسةٍ محفوظة، وعند كلّ
/// دورةٍ لتوكن FCM.
class RegisterDeviceToken {
  const RegisterDeviceToken(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call({
    required String token,
    required String platform,
  }) => _repository.registerDevice(token: token, platform: platform);
}
