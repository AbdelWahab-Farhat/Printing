import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:printing/features/vendors/models/stock_arrival.dart';

/// One page of the purchase orders list.
class GetPurchaseOrders {
  const GetPurchaseOrders(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, Paginated<PurchaseOrder>>> call({
    int? vendorId,
    int? warehouseId,
    PurchaseOrderStatus? status,
    int page = 1,
  }) {
    return _repository.purchaseOrders(
      vendorId: vendorId,
      warehouseId: warehouseId,
      // The wire value, and never [PurchaseOrderStatus.unknown]: its wire is the empty string,
      // which the server would read as a status it cannot parse.
      status: status == null || status == PurchaseOrderStatus.unknown ? null : status.wire,
      page: page,
    );
  }
}

/// One purchase order, with its lines.
class GetPurchaseOrder {
  const GetPurchaseOrder(this._repository);

  final PurchaseOrderRepository _repository;

  Future<Either<Failure, PurchaseOrder>> call(int purchaseOrderId) =>
      _repository.purchaseOrder(purchaseOrderId);
}

/// One line as the form holds it: the quantity is still text, because that is what was typed.
class DraftLine {
  const DraftLine({
    required this.productVariantId,
    required this.quantity,
    required this.unitCost,
    this.id,
    this.title,
  });

  final int? id;
  final int productVariantId;
  final String quantity;

  /// What we pay the vendor for one of them, as typed. Required on every line — see
  /// [PurchaseOrderLine.unitCost] for why there is nothing to fall back to.
  final String unitCost;

  /// What to show while the form is open. Never sent.
  final String? title;
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
          unitCost: _number(line.unitCost),
        ),
    ];

    if (id == null) {
      return _repository.create(
        vendorId: vendorId,
        warehouseId: warehouseId,
        orderDate: orderDate,
        items: lines,
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
          ReceivedLine(productVariantId: entry.key, quantity: _number(entry.value)),
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
