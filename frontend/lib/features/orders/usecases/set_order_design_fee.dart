// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// «أجرة التصميم» on an order already taken. Docs/orders/ORDER-DESIGN-FEE.md.
///
/// [fee] is what the amount sheet answered, in ASCII digits; null (an emptied box) clears it,
/// which is sent as `'0'` because clearing is a decision the server records too.
class SetOrderDesignFee {
  const SetOrderDesignFee(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, {required String? fee}) {
    final amount = fee?.trim().replaceAll('٫', '.');

    return _repository.setDesignFee(
      orderId,
      fee: amount == null || amount.isEmpty ? '0' : amount,
    );
  }
}
