import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order_counts.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';

/// One page of the purchase orders list.
class GetPurchaseOrders {
  const GetPurchaseOrders(this._repository);

  final PurchaseOrderRepository _repository;

  /// [status] is the one chip somebody tapped; [statuses] is a whole group — «الجارية» — asked
  /// for by a screen that already knows which one it wants. Passing both narrows to the
  /// intersection the server computes, which no caller has a reason to want, so callers pass one.
  Future<Either<Failure, Paginated<PurchaseOrder>>> call({
    int? vendorId,
    int? warehouseId,
    PurchaseOrderStatus? status,
    List<PurchaseOrderStatus> statuses = const <PurchaseOrderStatus>[],
    String? search,
    int page = 1,
  }) {
    return _repository.purchaseOrders(
      vendorId: vendorId,
      warehouseId: warehouseId,
      search: search,
      // Wire values, and never [PurchaseOrderStatus.unknown]: its wire is the empty string,
      // which the server would read as a status it cannot parse.
      statuses: [
        for (final wanted in [status, ...statuses])
          if (wanted != null && wanted != PurchaseOrderStatus.unknown)
            wanted.wire,
      ],
      page: page,
    );
  }
}

/// How many purchase orders stand in each status — the numbers on a supplier's screen.
class GetPurchaseOrderCounts {
  const GetPurchaseOrderCounts(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, PurchaseOrderCounts>> call({
    int? vendorId,
    String? search,
  }) => _repository.statusCounts(vendorId: vendorId, search: search);
}

/// One purchase order, with its lines.
class GetPurchaseOrder {
  const GetPurchaseOrder(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, PurchaseOrder>> call(int purchaseOrderId) =>
      _repository.purchaseOrder(purchaseOrderId);
}

/// One line as the form holds it: both numbers are still text, because that is what was typed.
class DraftLine {
  const DraftLine({
    required this.productVariantId,
    required this.quantity,
    required this.baseTotalCost,
    this.id,
    this.title,
  });

  final int? id;
  final int productVariantId;
  final String quantity;

  /// What the whole line costs us, as typed. Required on every line — see
  /// [PurchaseOrderLine.baseTotalCost] for why there is nothing to fall back to, and why it is
  /// the line's total rather than a unit price.
  final String baseTotalCost;

  /// What to show while the form is open. Never sent.
  final String? title;
}

/// One order-level cost as the form holds it — delivery, unloading, customs.
class DraftAdditionalCost {
  const DraftAdditionalCost({
    required this.name,
    required this.amount,
    this.id,
  });

  /// Absent on a cost being added; present on one being corrected.
  final int? id;

  final String name;
  final String amount;

  /// Whether there is anything here to send.
  ///
  /// **An empty row is not a cost.** The editor adds blank rows the way the line list does, and
  /// one left behind would be refused by `additional_costs.2.name.required` — an index that is
  /// not a thing on screen.
  bool get isBlank => name.trim().isEmpty && amount.trim().isEmpty;
}

/// Raises a purchase order, or corrects one.
///
/// **One use case for both**, because it is one form — and because the quantity conversion
/// below would otherwise be written twice.
class SavePurchaseOrder {
  const SavePurchaseOrder(this._repository);

  final PurchaseOrderRepository _repository;

  /// [id] null raises a new order; anything else corrects that one.
  Future<Either<Failure, PurchaseOrder>> call({
    int? id,
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<DraftLine> items,
    List<DraftAdditionalCost> additionalCosts = const [],
    String? expectedDate,
    String? notes,
  }) {
    final lines = [
      for (final line in items)
        PurchaseOrderLine(
          // Carried through, so the server corrects the line rather than replacing it — and
          // its `quantity_received` survives the edit.
          id: line.id,
          productVariantId: line.productVariantId,
          quantity: _number(line.quantity),
          baseTotalCost: _number(line.baseTotalCost),
        ),
    ];

    final costs = [
      for (final cost in additionalCosts)
        if (!cost.isBlank)
          PurchaseOrderAdditionalCostLine(
            id: cost.id,
            name: cost.name.trim(),
            amount: _number(cost.amount),
          ),
    ];

    if (id == null) {
      return _repository.create(
        vendorId: vendorId,
        warehouseId: warehouseId,
        orderDate: orderDate,
        items: lines,
        additionalCosts: costs,
        expectedDate: _blankToNull(expectedDate),
        notes: _blankToNull(notes),
      );
    }

    return _repository.update(
      id,
      vendorId: vendorId,
      warehouseId: warehouseId,
      orderDate: orderDate,
      items: lines,
      additionalCosts: costs,
      expectedDate: _blankToNull(expectedDate),
      notes: _blankToNull(notes),
    );
  }
}

/// Sends an order to the supplier, or writes it off.
class ChangePurchaseOrderStatus {
  const ChangePurchaseOrderStatus(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, PurchaseOrder>> call(
    int purchaseOrderId, {
    required PurchaseOrderStatus status,
  }) {
    return _repository.changeStatus(purchaseOrderId, status: status);
  }
}

/// Books a shipment in against an order.
///
/// **Lines with nothing in them are dropped before sending.** The receive screen opens with a
/// box per outstanding line, and a shipment that brought only two of five sizes is the ordinary
/// case — sending the empty three would be refused for a quantity of zero, on a screen whose
/// user filled in exactly what turned up.
class ReceivePurchaseOrderArrival {
  const ReceivePurchaseOrderArrival(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, StockArrival>> call(
    int purchaseOrderId, {
    required Map<int, String> quantities,
    String? invoiceNumber,
    String? notes,
  }) {
    final lines = [
      for (final entry in quantities.entries)
        if (_isPositive(entry.value))
          ReceivedLine(
            productVariantId: entry.key,
            quantity: _number(entry.value),
          ),
    ];

    return _repository.receiveArrival(
      purchaseOrderId,
      items: lines,
      invoiceNumber: _blankToNull(invoiceNumber),
      notes: _blankToNull(notes),
    );
  }

  static bool _isPositive(String input) {
    final parsed = double.tryParse(_number(input));

    return parsed != null && parsed > 0;
  }
}

/// Arabic-Indic digits to ASCII, and a comma to a decimal point.
///
/// `٢٥` is what a Libyan keyboard produces and every numeric rule on the server is ASCII-only.
/// Converted here, in the one layer a test can reach without a widget tree.
String _number(String input) =>
    Validators.toWesternDigits(input.trim()).replaceAll(',', '.');

String? _blankToNull(String? value) {
  final trimmed = value?.trim();

  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
