import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/utils/digits.dart';
import 'package:printing/features/vendors/models/stock_arrival.dart';
import 'package:printing/features/warehouses/models/warehouse_stock.dart';

part 'purchase_order.freezed.dart';
part 'purchase_order.g.dart';

/// Where a purchase order is, and the only moves it may make from there.
///
/// **The app keeps its own copy of this map, and that is the one place this feature differs
/// from orders.** `OrderResource` publishes `available_transitions` already narrowed to what the
/// signed-in user may do, so the order screen holds no rules at all. `PurchaseOrderResource`
/// publishes only `status` — so the buttons here are drawn from [allowedNext], which mirrors
/// `PurchaseOrderStatus.php`. The server refuses anything wrong either way; this copy decides
/// only what is *offered*, and `purchase_order_status_contract_test.dart` reads the PHP so the
/// two cannot drift silently.
enum PurchaseOrderStatus {
  @JsonValue('new')
  fresh('new', 'جديد'),
  @JsonValue('arrived')
  arrived('arrived', 'قيد الاستلام'),
  @JsonValue('completed')
  completed('completed', 'مكتمل'),
  @JsonValue('cancelled')
  cancelled('cancelled', 'ملغى'),

  /// A status this build has never heard of. Reached through `unknownEnumValue`, so one new
  /// case on the server does not turn a whole page into a parse failure.
  unknown('', '');

  const PurchaseOrderStatus(this.wire, this.label);

  final String wire;

  /// Mirrors the server's own `label()`. Held here because, unlike an order, a purchase order
  /// does not travel with `status_label` on every screen that names a status — the picker in
  /// the filter has to name all four before any order is loaded.
  final String label;

  /// Mirrors `PurchaseOrderStatus::allowedNext()` exactly, including the move no button
  /// offers — see [offeredNext]. Kept faithful so the contract test compares like with like.
  List<PurchaseOrderStatus> get allowedNext => switch (this) {
    PurchaseOrderStatus.fresh => const [
      PurchaseOrderStatus.arrived,
      PurchaseOrderStatus.cancelled,
    ],
    PurchaseOrderStatus.arrived => const [
      PurchaseOrderStatus.completed,
      PurchaseOrderStatus.cancelled,
    ],
    _ => const [],
  };

  /// The moves a person may actually make — cancelling, and nothing else.
  ///
  /// **Two of the machine's moves are deliberately on no button, for different reasons.**
  ///
  /// «مكتمل» is refused by the endpoint. `allowedNext()` lists it because completion *is* a legal
  /// next state, but it is reached by receiving the last of the goods, and
  /// `ChangePurchaseOrderStatusRequest` accepts only `arrived` and `cancelled`. A button for it
  /// would ask the server for something it answers «لا يمكن تحويل أمر الشراء إلى هذه الحالة
  /// يدوياً», on a screen that offered it.
  ///
  /// «قيد الاستلام» is accepted by the endpoint, and nothing needs it. A shipment may be booked
  /// in straight from «جديد» — see [isReceivable] — and `ReceivePurchaseOrder` moves the order
  /// there itself the moment one posts. So a «إرسال للمورد» button opened nothing; all it did was
  /// end [isEditable] before any goods had turned up, which is a cost with no matching gain.
  ///
  /// So the map is mirrored faithfully above and narrowed here, in one place, with the reasons
  /// written down.
  List<PurchaseOrderStatus> get offeredNext => allowedNext
      .where((status) => status == PurchaseOrderStatus.cancelled)
      .toList(growable: false);

  /// Nothing follows, and nothing reopens it.
  bool get isFinal =>
      this == PurchaseOrderStatus.completed || this == PurchaseOrderStatus.cancelled;

  /// Whether the document and its lines may still be changed. «جديد» alone, mirroring
  /// `isEditable()` — once anything has arrived, the paperwork is what the shipment was checked
  /// against.
  bool get isEditable => this == PurchaseOrderStatus.fresh;

  /// Whether a shipment may still be booked in against it.
  ///
  /// **Including «جديد»**, which surprises people: there is no need to «send» an order before
  /// the goods turn up, and requiring it would have staff pressing a button to describe
  /// something that already happened.
  bool get isReceivable =>
      this == PurchaseOrderStatus.fresh || this == PurchaseOrderStatus.arrived;

  static PurchaseOrderStatus fromWire(String? wire) =>
      values.firstWhere((status) => status.wire == wire, orElse: () => unknown);

  /// Everything a person may filter by. [unknown] is what the app *reads*, never what it offers.
  static List<PurchaseOrderStatus> get choices =>
      values.where((status) => status != unknown).toList(growable: false);
}

/// Paperwork raised against a supplier: what we asked for, how much of it has turned up, and
/// what it costs.
///
/// **The cost is what we pay a vendor, which no catalogue can answer.** A sale is priced from
/// the product's own tiers; a purchase is priced by whoever we are buying from, so the cost is
/// typed per line and has no fallback to quote against. [totalAmount] is derived by the server
/// from those lines and never added up here.
@freezed
abstract class PurchaseOrder with _$PurchaseOrder {
  const factory PurchaseOrder({
    required int id,
    @JsonKey(name: 'vendor_id') required int vendorId,

    /// Present on every screen that lists or opens one; absent from the reply to a status
    /// change, which is why the detail screen re-reads rather than trusting what came back.
    ArrivalRef? vendor,

    /// Nullable: a warehouse can be deleted once it is empty, and an order that named it keeps
    /// its key pointing at nothing. Receiving refuses in that case rather than guessing.
    @JsonKey(name: 'warehouse_id') int? warehouseId,
    ArrivalRef? warehouse,

    @JsonKey(unknownEnumValue: PurchaseOrderStatus.unknown)
    required PurchaseOrderStatus status,

    /// The Arabic the server chose. Rendered as-is wherever *this* order is on screen, so a
    /// status added on the server still reads correctly here.
    @JsonKey(name: 'status_label') required String statusLabel,

    /// Plain `YYYY-MM-DD`, not a timestamp — the day the order was placed, not an instant.
    @JsonKey(name: 'order_date') required String orderDate,
    @JsonKey(name: 'expected_date') String? expectedDate,

    String? notes,

    /// What the whole order costs, summed by the server from its lines.
    ///
    /// Null on an order raised before cost tracking existed — which is «غير مسجّل», not «صفر»,
    /// and the screens say so rather than drawing a free purchase.
    @JsonKey(name: 'total_amount') String? totalAmount,

    /// Present when one order was fetched, and on the list. Absent from a status change.
    @Default(<PurchaseOrderItem>[]) List<PurchaseOrderItem> items,

    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _PurchaseOrder;

  const PurchaseOrder._();

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderFromJson(json);

  /// Who it was raised against, however much of them arrived with it.
  String get vendorName => vendor?.name ?? 'مورد #$vendorId';

  String get warehouseName => warehouse?.name ?? 'بلا مخزن';

  /// Whether anything at all has been booked in against it yet.
  bool get hasReceipts => items.any((item) => item.hasReceipts);

  /// The lines still owing something. What the receive screen opens on.
  List<PurchaseOrderItem> get outstanding =>
      items.where((item) => item.isOutstanding).toList(growable: false);
}

/// One line: a size, how much was ordered, and how much of it has turned up.
@freezed
abstract class PurchaseOrderItem with _$PurchaseOrderItem {
  const factory PurchaseOrderItem({
    required int id,
    @JsonKey(name: 'product_variant_id') required int productVariantId,
    @JsonKey(name: 'product_variant') StockVariant? variant,

    /// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
    /// one to show it is how a decimal quietly becomes `10.0`.
    @JsonKey(name: 'quantity_ordered') required String quantityOrdered,
    @JsonKey(name: 'quantity_received') required String quantityReceived,

    /// Computed by the server, never here — a client that subtracted would be a second opinion
    /// about arithmetic that decides whether a shipment is refused.
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,

    /// What one of these costs us, and what the line comes to.
    ///
    /// Null only on a line written before cost tracking existed. **Zero is a real answer** — a
    /// free replacement from the vendor costs nothing and is not the same as nobody having said.
    @JsonKey(name: 'unit_cost') String? unitCost,
    @JsonKey(name: 'total_cost') String? totalCost,

    /// What this line is counted in, snapshotted from the product when the line was written.
    /// Null on a line older than the column; the screens fall back to the variant's own unit.
    String? unit,
    @JsonKey(name: 'unit_label') String? unitLabel,
  }) = _PurchaseOrderItem;

  const PurchaseOrderItem._();

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemFromJson(json);

  String get title => variant == null
      ? 'مقاس #$productVariantId'
      : '${variant!.productName} · ${variant!.label}';

  String get orderedLabel => groupedDecimal(quantityOrdered);

  String get receivedLabel => groupedDecimal(quantityReceived);

  String get remainingLabel => groupedDecimal(quantityRemaining);

  /// What this line's numbers are counted in, and the words built from it.
  PurchaseLineUnit get lineUnit => PurchaseLineUnit(unitLabel);

  /// «٥٠٠ كيلوغرام», or a bare «٥٠٠» on a line older than the unit column.
  String get orderedWithUnit => lineUnit.amount(orderedLabel);

  String get receivedWithUnit => lineUnit.amount(receivedLabel);

  String get remainingWithUnit => lineUnit.amount(remainingLabel);

  /// «للكيلوغرام» — what a unit cost is *per*, as it reads after the amount.
  String get perUnitSuffix => lineUnit.per;

  /// «تكلفة الكيلوغرام (د.ل)» — the price box names the thing being priced.
  String get costFieldLabel => lineUnit.costField;

  /// «الكمية المطلوبة (كيلوغرام)».
  String get quantityFieldLabel => lineUnit.quantityField;

  bool get hasReceipts => (double.tryParse(quantityReceived) ?? 0) > 0;

  bool get isOutstanding => (double.tryParse(quantityRemaining) ?? 0) > 0;

  /// Whether a cost was ever recorded against this line.
  ///
  /// **False only on a line older than cost tracking.** A cost of *zero* is a recorded answer —
  /// a free replacement from the vendor — so it renders as «0» rather than «غير مسجّلة».
  bool get hasCost => unitCost != null;
}

/// What a purchase-order line is counted in, and every phrase this app builds out of it.
///
/// **A quantity on a buying screen without its unit is a number nobody can act on.** «٥٠٠»
/// against «الأكياس الشفافة السادة» is five hundred *kilograms* — that product is priced by
/// weight — and a buyer reading it as five hundred bags orders about a tonne of the wrong thing.
/// The server has always sent `unit_label`; this is what stops the screens dropping it.
///
/// **One place for the wording, and the Arabic is the reason.** Four surfaces print these — the
/// form's two boxes, the line on the order, the receiving sheet — and «لل» + «كيلوغرام» is
/// exactly the kind of join that comes out «لل كيلوغرام» on the fourth copy. It also keeps the
/// form and the saved line saying the same word: a form that asks in one unit and a screen that
/// reports the answer in another is the failure this exists to prevent.
///
/// A plain class rather than Freezed: it never crosses the wire and holds one nullable string.
@immutable
class PurchaseLineUnit {
  const PurchaseLineUnit(this.label);

  /// «كيلوغرام», «قطعة», or null on a line older than the unit column.
  final String? label;

  /// «٥٠٠ كيلوغرام», or a bare «٥٠٠» when there is no unit to name.
  ///
  /// **Bare, never guessed.** Falling back to «قطعة» is precisely how a weight comes to be read
  /// as a count, and it would be wrong silently.
  String amount(String value) => label == null ? value : '$value $label';

  /// «للكيلوغرام» — what a unit cost is *per*, as it reads after the amount. «للوحدة» when
  /// unknown: vague, but true of any unit.
  String get per => label == null ? 'للوحدة' : 'لل$label';

  /// «تكلفة الكيلوغرام (د.ل)».
  String get costField => label == null ? 'تكلفة الوحدة (د.ل)' : 'تكلفة ال$label (د.ل)';

  /// «الكمية المطلوبة (كيلوغرام)».
  ///
  /// The unit in brackets rather than inside the sentence: it is a note about what the box
  /// expects, not part of what is being asked for.
  String get quantityField => label == null ? 'الكمية المطلوبة' : 'الكمية المطلوبة ($label)';

  /// «الكمية التي وصلت (كيلوغرام)» — the box a storeman types a weighbridge figure into.
  String get receivedField =>
      label == null ? 'الكمية التي وصلت' : 'الكمية التي وصلت ($label)';

  @override
  bool operator ==(Object other) => other is PurchaseLineUnit && other.label == label;

  @override
  int get hashCode => label.hashCode;
}
