import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';

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

  factory StockArrival.fromJson(Map<String, dynamic> json) => _$StockArrivalFromJson(json);

  /// «فاتورة INV-1001», or the document's own number when the supplier sent none.
  String get title => invoiceNumber == null || invoiceNumber!.isEmpty
      ? 'شحنة #$id'
      : 'فاتورة $invoiceNumber';

  /// How many lines the document has — the count worth showing on a row, since the quantities
  /// are in different units and cannot be added together.
  int get lineCount => items.length;
}

/// One line: how much of one size this shipment brought, and the ledger row it wrote.
@freezed
abstract class StockArrivalItem with _$StockArrivalItem {
  const factory StockArrivalItem({
    required int id,

    /// A decimal the server sent — `'200.000'`. Kept as a `String` for the same reason
    /// [WarehouseStock.quantity] is: parsing it into a `double` is the first step towards
    /// arithmetic this app has no business doing.
    required String quantity,

    @JsonKey(name: 'product_variant_id') required int productVariantId,

    /// Reuses the shelf model's own summary — the server flattens a variant to the same five
    /// fields wherever it appears, and a second class holding them would be a second thing to
    /// keep in step.
    @JsonKey(name: 'product_variant') StockVariant? variant,

    /// The ledger row this line produced. What makes «هذا السطر، أي حركة كتب؟» answerable
    /// without re-deriving it from dates and quantities.
    @JsonKey(name: 'stock_movement_id') required int stockMovementId,
  }) = _StockArrivalItem;

  const StockArrivalItem._();

  factory StockArrivalItem.fromJson(Map<String, dynamic> json) => _$StockArrivalItemFromJson(json);

  /// `'200.000'` reads as a quantity to a database and as noise to a storekeeper: `'200'`.
  String get quantityLabel => trimDecimals(quantity);

  String get title =>
      variant == null ? 'مقاس #$productVariantId' : '${variant!.productName} · ${variant!.label}';
}

/// An id and the name it had — the shape the server flattens the vendor, the warehouse and the
/// receiving employee into alike.
///
/// One class for all three rather than three identical ones: they are the same two fields, read
/// for the same purpose (draw the name, tap through to the record), and naming them apart would
/// be three files to change the day the server adds a third field to any of them.
@freezed
abstract class ArrivalRef with _$ArrivalRef {
  const factory ArrivalRef({required int id, required String name}) = _ArrivalRef;

  factory ArrivalRef.fromJson(Map<String, dynamic> json) => _$ArrivalRefFromJson(json);
}
