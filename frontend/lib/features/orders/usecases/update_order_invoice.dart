import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:flutter/foundation.dart';

/// One line as the server needs it to re-price the invoice.
///
/// **No unit price.** The rate comes from the catalogue when the server prices the line, which
/// is what stops an edit from quietly undercutting an agreed rate — the same rule that makes
/// `unit_price` ignored on creation for any product with listed prices.
///
/// **And no shelf quantity.** `PUT /orders/{id}` no longer accepts one: what comes off the shelf
/// is asked for on the way into «جاهزة», and by then `Order.itemsAreEditable` is false — so this
/// payload can never reach a line that carries a measurement, and there is nothing to preserve
/// through the rebuild.
@immutable
class InvoiceLineUpdate {
  const InvoiceLineUpdate({
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  final int productId;
  final int variantId;
  final String quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product_id': productId,
    'product_variant_id': variantId,
    'quantity': quantity,
  };
}

/// Editing an open order: its lines, its discount, and where it is going.
///
/// `PUT /orders/{id}` replaces the whole set — the same contract a product's sizes follow — so
/// a removed line is expressed by sending the ones that remain, not by a delete call.
///
/// **Every argument is optional, because the parts close at different moments.** An order in
/// «جاهزة» has its lines shut and its address open, so the only honest way to express that edit
/// is to send the address and say nothing at all about the lines. The recipient's phone closes
/// with the address — see [OrderRepository.updateInvoice] for why it is a record.
class UpdateOrderInvoice {
  const UpdateOrderInvoice(this._repository);

  final OrderRepository _repository;

  Future<Either<Failure, Order>> call(
    int orderId, {
    List<InvoiceLineUpdate>? lines,
    String? discount,
    int? cityId,
    int? regionId,
    ({String? number})? recipientPhone,
  }) {
    return _repository.updateInvoice(
      orderId,
      lines: lines,
      discount: discount,
      cityId: cityId,
      regionId: regionId,
      recipientPhone: recipientPhone,
    );
  }
}
