import 'package:dayaa/features/carrier/models/carrier_money_sync.dart';
import 'package:dayaa/features/orders/models/order.dart';

/// What `PATCH orders/{id}/delivery-payer` answered: the order as it now stands, whether Nawris
/// heard, and which other orders in the same parcel changed with it.
///
/// A plain class rather than a generated one, like [CarrierMoneySync]: it is read once, shown
/// once, and never stored.
class DeliveryPayerChange {
  const DeliveryPayerChange({required this.order, this.carrier, this.alsoChanged = const []});

  factory DeliveryPayerChange.fromJson(Map<String, dynamic> json) => DeliveryPayerChange(
    order: Order.fromJson(json['order'] as Map<String, dynamic>),
    carrier: switch (json['carrier']) {
      final Map<String, dynamic> carrier => CarrierMoneySync.fromJson(carrier),
      _ => null,
    },
    alsoChanged: [
      for (final code in (json['also_changed'] as List<dynamic>? ?? const [])) code.toString(),
    ],
  );

  final Order order;

  /// Null when no parcel was out; [CarrierMoneySync.warning] is set when Nawris refused.
  final CarrierMoneySync? carrier;

  /// The codes of the other orders sharing the parcel — their parcel holds one answer.
  final List<String> alsoChanged;
}
