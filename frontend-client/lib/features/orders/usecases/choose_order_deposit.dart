import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';

/// يختار عربون طلبيةٍ قبلها المتجر بعد المراجعة (صاحب العمل، 2026-10-19).
///
/// **خطوة السلة، مؤجَّلة.** سلةٌ فيها وسيط أو «حسب الطلب» أُرسلت للمراجعة بلا عربون؛ حين تُقبل يُعرض
/// على العميل الاختيارُ نفسه — المكتب يتركها «بانتظار العربون»، والمحفظة تدفعه فتصير «عربون مدفوع».
/// والإلكتروني شحنٌ يكتمل أولاً ثم هذا من المحفظة.
class ChooseOrderDeposit {
  const ChooseOrderDeposit(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, CustomerOrderDetail>> call(int orderId, CheckoutDeposit deposit) =>
      _repository.chooseDeposit(orderId, deposit);
}
