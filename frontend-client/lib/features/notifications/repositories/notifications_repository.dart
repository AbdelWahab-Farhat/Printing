import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';

/// سجلُّ الأجهزة التي يصلها دفعُ العميل المسجَّل — ولا شيء غيره.
///
/// **أقصرُ من نظيره في تطبيق الموظفين عن قصد**: هناك صندوقُ إشعاراتٍ وجرسٌ وعدّاد، وهنا الدفعُ
/// وحده. ما يُخطَر به العميل (مرحلةُ طلبيته، ردُّ الدعم) له شاشتُه أصلاً، فالإشعار طَرقةٌ على
/// الباب لا نسخةٌ ثانية من المحتوى.
abstract interface class NotificationsRepository {
  /// يسجّل هذا الجهاز للعميل المسجَّل. عند الدخول، وعند كلّ فتحٍ بجلسةٍ محفوظة، وعند كلّ دورةٍ
  /// لتوكن FCM — والخادم يجعل التكرار آمناً (upsert على التوكن)، فلا يتذكّر التطبيقُ ما أرسل.
  Future<Either<Failure, String>> registerDevice({
    required String token,
    required String platform,
  });

  /// يوقف الدفع إلى هذا الجهاز. عند الخروج، **قبل** أن يُمسح رمزُ الدخول.
  Future<Either<Failure, String>> releaseDevice({required String token});
}
