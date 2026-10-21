import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Recording the vendor's cost for a وسيط line that went past «جاهزة» without one.
///
/// **A gap being filled, not a figure being corrected.** «جاهزة» asks for the cost now and
/// refuses the move without it; this exists for the orders that passed it before it did. The
/// server takes it once per line and refuses a second time — see OUTSOURCED-PRODUCTS.md §6.2.
class RecordVendorCost {
  const RecordVendorCost(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(int orderId, int itemId, {required String unitCost}) {
    // `٠٫٨` is what a Libyan keyboard produces; the server's `numeric` rule is ASCII-only. The
    // validator's converter rather than `normaliseAmount`, which drops the Persian digits the
    // sheet's box admits.
    return _repository.recordVendorCost(
      orderId,
      itemId,
      unitCost: Validators.toWesternDigits(unitCost.trim()),
    );
  }
}
