// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Recording what is missing from an order — which is recording what it costs.
///
/// A line is billed for what is left of it, at the price it was agreed at, so this is the one
/// call in the app that moves an invoice without touching a price or a quantity. It is also
/// reversible by nature: send a line's shortage back as nothing and the total returns to the
/// number it was, because the server derives it rather than adjusting it.
///
/// **What this owns is the difference between an empty box and a zero.** A box left blank means
/// «لا شيء ناقص من هذا البند» and travels as null so the server clears it; a typed `0` means the
/// clerk counted and found nothing missing, and travels as the number they typed. The two reach
/// the same invoice, but only one of them is an answer somebody gave, and turning it into a
/// blank would be editing it.
class SetOrderShortages {
  const SetOrderShortages(this._repository);

  final OrderRepository _repository;

  /// [shortages] is line id → what is missing from it, for **every line the caller showed**.
  Future<Either<Failure, Order>> call(
    int orderId, {
    required Map<int, String?> shortages,
  }) {
    return _repository.setShortages(
      orderId,
      shortages: {
        for (final entry in shortages.entries) entry.key: _typed(entry.value),
      },
    );
  }

  /// Null for a box nobody put a number in. Spaces are not a number.
  static String? _typed(String? value) {
    final trimmed = value?.trim();

    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
