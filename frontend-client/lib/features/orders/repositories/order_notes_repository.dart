import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';

/// ملاحظات الطلبية — ما كتبه المتجر عند مراجعتها ورفضها.
///
/// **مستودعٌ وحده لا دالّةٌ في `OrderRepository`**: ذاك تنفّذه أربع عشرة نسخةً مزيّفة في
/// الاختبارات وأدوات المعاينة، وكل دالّةٍ تُضاف إليه تكسرها كلها وهي لا شأن لها بالملاحظات.
abstract interface class OrderNotesRepository {
  /// ملاحظات طلبيةٍ من طلبيات العميل، من الأقدم.
  ///
  /// **وقراءتها تعلّمها مقروءة عند الخادم**، كفتح محادثةٍ في الدعم: لا نداء «قرأتها» منفصل.
  Future<Either<Failure, List<OrderNote>>> notes(int orderId);
}
