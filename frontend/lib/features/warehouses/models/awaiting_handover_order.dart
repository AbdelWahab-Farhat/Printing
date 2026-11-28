import 'package:flutter/foundation.dart';

/// One instant order still «جديدة» holding stock on a shelf — a line behind that shelf's
/// «بانتظار التسليم» (INSTANT-ORDERS-PLAN.md §4).
@immutable
class AwaitingHandoverOrder {
  const AwaitingHandoverOrder({
    required this.orderId,
    required this.code,
    required this.quantity,
    this.customerName,
    this.placedAt,
  });

  factory AwaitingHandoverOrder.fromJson(Map<String, dynamic> json) => AwaitingHandoverOrder(
    orderId: json['order_id'] as int,
    code: json['code'] as String,
    quantity: json['quantity'] as String,
    customerName: json['customer_name'] as String?,
    placedAt: json['placed_at'] == null ? null : DateTime.tryParse(json['placed_at'] as String),
  );

  final int orderId;
  final String code;

  /// As the server sent it, in the shelf's unit.
  final String quantity;
  final String? customerName;
  final DateTime? placedAt;
}
