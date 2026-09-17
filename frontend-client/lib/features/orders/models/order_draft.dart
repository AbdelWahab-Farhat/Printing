import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/foundation.dart';

/// One line of an order being composed, with the words to draw it by.
///
/// **A display type beside the wire type, not instead of it.** [NewOrderLine] is what the server
/// is sent and carries ids alone, exactly as `RequestOrderRequest` expects. But a basket that
/// reads «مقاس رقم ١٢» is a basket nobody can check before sending — so the screen that *knows*
/// the product's name carries it here, rather than the order screen asking the catalogue again
/// for something it was just told.
@immutable
class OrderDraftLine {
  const OrderDraftLine({
    required this.line,
    required this.title,
    this.subtitle,
    this.orderGroup = 'shared',
  });

  /// What is actually sent.
  final NewOrderLine line;

  /// «كيس شحن فلاير».
  final String title;

  /// «٣٠×٤٠ · الكمية ١٠٠٠».
  final String? subtitle;

  /// Which basket this line belongs to — carried from the product so the cart can compare
  /// without asking the catalogue again. An opaque token; see `Product.orderGroup`.
  final String orderGroup;

  OrderDraftLine copyWith({
    NewOrderLine? line,
    String? title,
    String? subtitle,
    String? orderGroup,
  }) => OrderDraftLine(
    line: line ?? this.line,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    orderGroup: orderGroup ?? this.orderGroup,
  );
}
