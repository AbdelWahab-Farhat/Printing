import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:flutter/foundation.dart';

/// One line as the server needs it to edit the invoice.
///
/// **[id] is what keeps a line the same line.** Sent, the server edits that row in place — its
/// price, its shortage and its stock draw stay with it. Null, the line is new. A line on the
/// order that is not sent at all is removed. See Docs/orders/ORDER-LINES-ADD-REMOVE.md §5.
///
/// **[unitPrice] only for a product priced «حسب الطلب».** For anything with listed prices the
/// catalogue's rate wins on the server and a number sent here is ignored, which is what stops an
/// edit quietly undercutting an agreed rate.
///
/// **[warehouseQuantity] only once the stock has left**, and only for a line sold in one unit and
/// stocked in another that is added or changes quantity: what should now leave the shelf, the
/// same figure «جاهزة للطباعة» asked for the first time.
@immutable
class InvoiceLineUpdate {
  const InvoiceLineUpdate({
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.id,
    this.unitPrice,
    this.warehouseQuantity,
  });

  final int? id;
  final int productId;
  final int variantId;
  final String quantity;
  final String? unitPrice;
  final String? warehouseQuantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'product_id': productId,
    'product_variant_id': variantId,
    'quantity': quantity,
    'unit_price': ?unitPrice,
    'warehouse_quantity': ?warehouseQuantity,
  };
}

/// Editing an open order: its lines, its discount, and where it is going.
///
/// `PUT /orders/{id}` edits the line set by id — a removed line is expressed by not sending it,
/// not by a delete call.
///
/// **Urgency is null unless this edit is about it.** The server reads a missing `is_urgent` as
/// «اتركها كما هي», which is what lets the additional-cost sheet write on its own without
/// calming down an order it never asked about.
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
    String? additionalCost,
    AdditionalCostReason? additionalCostReason,
    String? additionalCostNote,
    bool? isUrgent,
    ({int? id})? vendor,
  }) {
    // **An amount of nothing takes its reason with it.** The chips can be tapped before the box
    // is filled, and a reason on its own would be a category for money nobody is charging —
    // which the server refuses, correctly, with a message about a field the clerk did fill in.
    final charge = additionalCost == null ? null : _number(additionalCost);
    final isCharging = (double.tryParse(charge ?? '') ?? 0) > 0;

    return _repository.updateInvoice(
      orderId,
      lines: lines,
      discount: discount,
      cityId: cityId,
      regionId: regionId,
      recipientPhone: recipientPhone,
      additionalCost: charge,
      additionalCostReason: isCharging ? additionalCostReason : null,
      additionalCostNote: isCharging ? _text(additionalCostNote) : null,
      isUrgent: isUrgent,
      vendor: vendor,
    );
  }

  /// «١٠٫٥» as the keyboard produced it → `10.5`, and an empty box → `'0.00'`.
  ///
  /// Zero rather than null, because absent means «leave the charge alone» all the way down: a
  /// clerk clearing the box means «لا تكلفة إضافية», and that is a number, not a silence.
  static String _number(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '0.00';

    return Validators.toWesternDigits(trimmed).replaceAll(',', '.');
  }

  static String? _text(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
