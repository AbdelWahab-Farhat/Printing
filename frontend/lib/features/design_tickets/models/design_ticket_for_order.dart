import 'package:dayaa/features/customers/models/customer.dart';
import 'package:flutter/foundation.dart';

/// «تصميم طلبية» — a design ticket opened from inside an order, and linked to it
/// (PRINT-COLORS.md §10).
///
/// The form reads the customer and the order from here and never asks for them. [brief] starts
/// the description with what the order is (its printed lines), and [colorsRequired] makes the
/// colours mandatory when the order goes through our press. On approval the design is added to
/// the order by the server.
@immutable
class DesignTicketForOrder {
  const DesignTicketForOrder({
    required this.customer,
    required this.orderId,
    required this.orderCode,
    this.brief = '',
    this.colorsRequired = false,
  });

  final Customer customer;
  final int orderId;
  final String orderCode;
  final String brief;
  final bool colorsRequired;
}
