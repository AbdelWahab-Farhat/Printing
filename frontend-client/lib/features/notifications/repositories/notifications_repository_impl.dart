import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/features/notifications/repositories/notifications_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [NotificationsRepository] over HTTP — the only file in this feature importing `dio`.
class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, String>> registerDevice({
    required String token,
    required String platform,
  }) {
    return safeCommand(
      () => _dio.post(
        NotificationEndpoints.devices,
        data: <String, dynamic>{'token': token, 'platform': platform},
      ),
    );
  }

  /// التوكن في **جسم طلب DELETE**، وهذا غير مألوف فيستحقّ التنبيه: سلسلةٌ بهيئة بيانات اعتماد لا
  /// مكان لها في رابطٍ يُكتب في كلّ سجلِّ وصولٍ بين الهاتف والخادم.
  @override
  Future<Either<Failure, String>> releaseDevice({required String token}) {
    return safeCommand(
      () => _dio.delete(
        NotificationEndpoints.devices,
        data: <String, dynamic>{'token': token},
      ),
    );
  }
}
