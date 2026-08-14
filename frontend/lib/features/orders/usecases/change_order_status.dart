// dartz exports an `Order` of its own (its ordering typeclass, which this app never
// uses). Hidden rather than prefixed, so the model keeps the name the domain calls it.
import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';

/// Moving an order through the workshop.
///
/// **The rules are not re-stated here, on purpose.** Which moves are legal, which need a reason
/// and which the signed-in user may make are all decided on the server and arrive with the order
/// as `available_transitions`. A copy of that map in the app would be a second source of truth
/// that nothing keeps honest — and the one that drifts is always the one guarding the button.
///
/// What this class does own is the trimming: a reason of spaces is no reason, and sending one
/// would satisfy a required-field check while telling the next reader nothing.
class ChangeOrderStatus {
  const ChangeOrderStatus(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(
    int orderId, {
    required OrderStatus status,
    String? reason,
    Map<String, Object?> fields = const {},
  }) {
    final trimmed = reason?.trim();

    return _repository.changeStatus(
      orderId,
      status: status,
      reason: trimmed != null && trimmed.isNotEmpty ? trimmed : null,
      // Empty answers are dropped rather than sent as null: an optional field the user left
      // alone is a field they did not fill, and `{"notes": null}` says something else.
      fields: {
        for (final entry in fields.entries)
          if (!_isEmpty(entry.value)) entry.key: entry.value,
      },
    );
  }

  static bool _isEmpty(Object? value) => switch (value) {
    null => true,
    String(:final isEmpty) => isEmpty,
    Iterable(:final isEmpty) => isEmpty,
    _ => false,
  };
}
