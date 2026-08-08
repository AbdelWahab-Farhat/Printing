import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/purchase_orders/models/purchase_order.dart';
import 'package:printing/features/vendors/models/stock_arrival.dart';

/// One line of an order as the server needs it.
///
/// A plain class rather than a Freezed model: it never comes back, is never stored and is never
/// compared. It exists so a call takes one argument per line instead of three parallel lists.
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.productVariantId,
    required this.quantity,
    this.id,
  });

  /// The existing line's id, when one is being corrected.
  ///
  /// **Absent means "new", and a line left out of the list is removed** — the same replace-in-
  /// full contract an order's items follow. A line that lost its id on the way through would be
  /// deleted and recreated, taking its `quantity_received` with it.
  final int? id;

  final int productVariantId;

  /// As typed, normalised to ASCII digits. Never parsed here.
  final String quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'product_variant_id': productVariantId,
    'quantity_ordered': quantity,
  };
}

/// One line of a shipment being booked in.
class ReceivedLine {
  const ReceivedLine({required this.productVariantId, required this.quantity});

  final int productVariantId;
  final String quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product_variant_id': productVariantId,
    'quantity': quantity,
  };
}

/// What the app can ask and tell about the paperwork raised against suppliers.
abstract interface class PurchaseOrderRepository {
  /// [status] is a wire value; null asks for every state.
  Future<Either<Failure, Paginated<PurchaseOrder>>> purchaseOrders({
    int? vendorId,
    int? warehouseId,
    String? status,
    int page,
    int perPage,
  });

  Future<Either<Failure, PurchaseOrder>> purchaseOrder(int purchaseOrderId);

  Future<Either<Failure, PurchaseOrder>> create({
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    String? expectedDate,
    String? notes,
  });

  /// Rewrites the document and its lines. Refused by the server unless the order is «جديد».
  Future<Either<Failure, PurchaseOrder>> update(
    int purchaseOrderId, {
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    String? expectedDate,
    String? notes,
  });

  /// Sends it to the supplier, or writes it off.
  ///
  /// Only those two: «مكتمل» is reached by receiving the last of the goods, and the server
  /// refuses it here.
  Future<Either<Failure, PurchaseOrder>> changeStatus(
    int purchaseOrderId, {
    required PurchaseOrderStatus status,
  });

  /// Books a shipment in against the order, which is what actually moves stock.
  ///
  /// **Answers with the arrival, not with the order** — so a caller that needs the order's new
  /// `quantity_received` and status has to read it again. That is the server's shape, and
  /// pretending otherwise here would mean inventing numbers.
  Future<Either<Failure, StockArrival>> receiveArrival(
    int purchaseOrderId, {
    required List<ReceivedLine> items,
    String? invoiceNumber,
    String? notes,
  });
}
