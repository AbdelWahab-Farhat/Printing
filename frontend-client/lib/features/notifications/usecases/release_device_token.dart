import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/notifications/repositories/notifications_repository.dart';

/// يطلب من الخادم أن يكفّ عن الدفع إلى هذا الجهاز.
///
/// **عند الخروج ليس اختيارياً.** هاتفٌ يتنقّل بين حسابين — محلٌّ وصاحبه، أو هاتفٌ بيع — تبقى
/// عليه طلبياتُ العميل السابق وردودُ دعمه إن بقي تسجيلُه.
class ReleaseDeviceToken {
  const ReleaseDeviceToken(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, String>> call({required String token}) =>
      _repository.releaseDevice(token: token);
}
