import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_arrival.freezed.dart';
part 'stock_arrival.g.dart';

/// شحنة توريد — what one vendor sent, on one document, into one warehouse.
///
/// **Written once and never edited**, exactly like the ledger rows it produces: posting one
/// writes a `stock_movements` row per line and moves the receiving warehouse's balance in the
/// same transaction. Correcting a mistake is a stocktake adjustment against the warehouse, not
/// an edit here — which is why this feature has no update and no delete, and why the server does
/// not even publish an `updated_at` for the app to believe in.
@freezed
abstract class StockArrival with _$StockArrival {
  const factory StockArrival({
    required int id,

    @JsonKey(name: 'vendor_id') required int vendorId,
    ArrivalRef? vendor,

    /// Which purchase order this shipment was fulfilling, null when it was unplanned — which
    /// most arrivals are.
    ///
    /// A plain id and not a nested object, because that is what the server publishes: the order
    /// is read through `GET /purchase-orders/{id}`, the same way every other `*_id` in this API
    /// works.
    @JsonKey(name: 'purchase_order_id') int? purchaseOrderId,

    /// Nullable, and not an oversight: a warehouse can be deleted once it is empty, and the
    /// purchase history that passed through it has to survive that. The document keeps its
    /// lines and its ledger rows; only the pointer goes.
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    ArrivalRef? warehouse,

    @JsonKey(name: 'invoice_number') String? invoiceNumber,
    String? notes,

    /// Stamped by the server from the authenticated user — never sent by this app.
    @JsonKey(name: 'received_by') required int receivedBy,
    @JsonKey(name: 'received_by_user') ArrivalRef? receivedByUser,

    @Default(<StockArrivalItem>[]) List<StockArrivalItem> items,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _StockArrival;

  const StockArrival._();

  factory StockArrival.fromJson(Map<String, dynamic> json) =>
      _$StockArrivalFromJson(json);

  /// «فاتورة INV-1001», or the document's own number when the supplier sent none.
  String get title => invoiceNumber == null || invoiceNumber!.isEmpty
      ? 'شحنة #$id'
      : 'فاتورة $invoiceNumber';

  /// How many lines the document has — the count worth showing on a row, since the quantities
  /// are in different units and cannot be added together.
  int get lineCount => items.length;
}

/// One line: how much of one stock item this shipment brought, and the ledger row it wrote.
@freezed
abstract class StockArrivalItem with _$StockArrivalItem {
  const factory StockArrivalItem({
    required int id,

    /// A decimal the server sent — `'200.000'`. Kept as a `String` because parsing it into a
    /// `double` to hold it is the first step towards arithmetic this app has no business doing:
    /// a balance moves because a *movement* explains it, never because a client computed it.
    required String quantity,

    /// **Which shelf, not which product's size.** «كيس شحن سادة 25*35» and «كيس شحن مطبوع
    /// 25*35» are two catalogue rows and one pile of bags, so a shipment is booked against the
    /// pile — see [StockItemRef].
    @JsonKey(name: 'stock_item_id') required int stockItemId,

    /// Reuses the shelf model's own summary — the server flattens a stock item to the same six
    /// fields wherever it appears, and a second class holding them would be a second thing to
    /// keep in step. **There is no `product_name` and no `image_url` in it**: a pile is not one
    /// product's, so naming or picturing one of the two products sharing it would tell the
    /// storekeeper the wrong thing. [StockItemRef.code] and [StockItemRef.displayName] are what
    /// stand in their place.
    ///
    /// Nullable because it is `whenLoaded`, though every arrival the API publishes today carries
    /// it: `StockArrivalListQuery` eager-loads `items.stockItem`. A missing key draws a fallback
    /// rather than failing the page.
    @JsonKey(name: 'stock_item') StockItemRef? stockItem,

    /// What this line cost, carried down from the purchase order it fulfilled.
    ///
    /// **Null for a plain arrival**, which is the ordinary case: goods that turned up without
    /// paperwork have no agreed price to inherit, and inventing one here would put a number on
    /// a shipment nobody priced.
    @JsonKey(name: 'unit_cost') String? unitCost,
    @JsonKey(name: 'total_cost') String? totalCost,

    /// The ledger row this line produced. What makes «هذا السطر، أي حركة كتب؟» answerable
    /// without re-deriving it from dates and quantities.
    @JsonKey(name: 'stock_movement_id') required int stockMovementId,
  }) = _StockArrivalItem;

  const StockArrivalItem._();

  factory StockArrivalItem.fromJson(Map<String, dynamic> json) =>
      _$StockArrivalItemFromJson(json);

  /// `'200.000'` reads as a quantity to a database and as noise to a storekeeper: `'200'`.
  String get quantityLabel => groupedDecimal(quantity);

  /// «كيس شحن 25*35» — composed by the server and drawn as sent.
  ///
  /// **No product name, deliberately.** A pile is not one product's: «كيس شحن سادة» and «كيس شحن
  /// مطبوع» both draw on this line's shelf, so naming either of them here would be picking one
  /// arbitrarily and telling the storekeeper the wrong thing.
  String get title => stockItem?.displayName ?? 'مقاس #$stockItemId';

  /// `S7` — the shelf's own code, in the space the product photograph used to occupy.
  ///
  /// Null on a line that arrived without its item, where there is nothing to print rather than
  /// a code invented from the id.
  String? get itemCode => stockItem?.code;
}

/// An id and the name it had — the shape the server flattens the vendor, the warehouse and the
/// receiving employee into alike.
///
/// One class for all three rather than three identical ones: they are the same two fields, read
/// for the same purpose (draw the name, tap through to the record), and naming them apart would
/// be three files to change the day the server adds a third field to any of them.
@freezed
abstract class ArrivalRef with _$ArrivalRef {
  const factory ArrivalRef({required int id, required String name}) =
      _ArrivalRef;

  factory ArrivalRef.fromJson(Map<String, dynamic> json) =>
      _$ArrivalRefFromJson(json);
}
