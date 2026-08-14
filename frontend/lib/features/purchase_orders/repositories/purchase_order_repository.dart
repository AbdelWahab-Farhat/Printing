import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order_counts.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';

/// One line of an order as the server needs it.
///
/// A plain class rather than a Freezed model: it never comes back, is never stored and is never
/// compared. It exists so a call takes one argument per line instead of three parallel lists.
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.productVariantId,
    required this.quantity,
    required this.baseTotalCost,
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

  /// What the line costs us in total, as typed. **Required by the server on every line**, with
  /// no catalogue to fall back on: a sale is priced from the product's tiers, but what we pay a
  /// vendor is only ever something a person knows.
  ///
  /// **The line's total, not a per-unit price.** The server divides it by [quantity] to get
  /// `base_unit_cost` and never the other way around — sending a unit price here would multiply
  /// the order's cost by its own quantity, silently.
  ///
  /// `'0'` is a legitimate answer — a free replacement — so this is never omitted to mean
  /// «unknown». There is no such thing here.
  final String baseTotalCost;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'product_variant_id': productVariantId,
    'quantity_ordered': quantity,
    'base_total_cost': baseTotalCost,
  };
}

/// One order-level cost as the server needs it — delivery, unloading, customs.
class PurchaseOrderAdditionalCostLine {
  const PurchaseOrderAdditionalCostLine({
    required this.name,
    required this.amount,
    this.id,
  });

  /// **Absent means "new", and a cost left out of the list is removed** — the same replace-in-
  /// full contract [PurchaseOrderLine] follows.
  final int? id;

  final String name;

  /// As typed, normalised to ASCII digits.
  final String amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'name': name,
    'amount': amount,
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
  /// One page of the list.
  ///
  /// [statuses] holds wire values and takes a **group** rather than one status, because the
  /// queues a supplier's screen offers are groups: «الجارية» is `new` and `arrived` together.
  /// Empty asks for every state.
  ///
  /// [search] matches the vendor's name, the warehouse's name, or — for a number — the order's
  /// own id. Null asks for all of them; the two narrow together rather than replacing each other.
  Future<Either<Failure, Paginated<PurchaseOrder>>> purchaseOrders({
    int? vendorId,
    int? warehouseId,
    List<String> statuses,
    String? search,
    int page,
    int perPage,
  });

  /// How many orders stand in each status, under the same filters the list takes.
  ///
  /// Deliberately takes the vendor but not the statuses: counts narrowed to the group already
  /// chosen would every one of them equal the list's own length.
  Future<Either<Failure, PurchaseOrderCounts>> statusCounts({
    int? vendorId,
    String? search,
  });

  Future<Either<Failure, PurchaseOrder>> purchaseOrder(int purchaseOrderId);

  Future<Either<Failure, PurchaseOrder>> create({
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,

    /// Empty rather than null when there are none: the server reads an absent list and an empty
    /// one the same way, and one shape here is one fewer thing for a caller to get wrong.
    List<PurchaseOrderAdditionalCostLine> additionalCosts,
    String? expectedDate,
    String? notes,
  });

  /// Rewrites the document, its lines and its additional costs. Refused by the server unless the
  /// order is «جديد».
  ///
  /// **Both lists replace what is stored.** Whatever is not sent is deleted, so a caller always
  /// sends the full current set — see [PurchaseOrderLine.id].
  Future<Either<Failure, PurchaseOrder>> update(
    int purchaseOrderId, {
    required int vendorId,
    required int warehouseId,
    required String orderDate,
    required List<PurchaseOrderLine> items,
    List<PurchaseOrderAdditionalCostLine> additionalCosts,
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
