import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/vendors/models/stock_arrival.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
      this == PurchaseOrderStatus.completed ||
      this == PurchaseOrderStatus.cancelled;

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

  /// Everything still owed a move — «أوامر الشراء الجارية».
  ///
  /// **Derived from [isFinal] rather than listed**, so a fifth status added to this enum joins
  /// this queue by default. That is the right default: a new state is work until somebody says
  /// otherwise, and two hand-written lists over one machine are two things to keep in step.
  ///
  /// **«جديد» is in it**, which is the decision worth writing down: a draft nobody sent is stock
  /// the shop decided to buy and has not bought, and one forgotten there for a month is exactly
  /// what this queue exists to surface. See VENDOR-PURCHASE-ORDERS-SECTION.md §١.
  static List<PurchaseOrderStatus> get inProgress =>
      choices.where((status) => !status.isFinal).toList(growable: false);

  /// What arrived in full — «أوامر الشراء المكتملة».
  ///
  /// «مكتمل» alone. Named apart from the case it contains because a static getter cannot share
  /// a name with an enum constant; it is a group of one today and stays a group because the
  /// screens ask it as one.
  static List<PurchaseOrderStatus> get fulfilled =>
      choices.where((status) => status == completed).toList(growable: false);

  /// What was called off — «أوامر الشراء الملغاة».
  ///
  /// **Its own box, beside the other two rather than folded into either.** It is not in progress
  /// — nobody will work on it — and not completed — nothing arrived. Written as a filter over
  /// every cancellation rather than as `[cancelled]`, so a second kind of cancellation added
  /// later lands here instead of quietly disappearing from all three groups.
  static List<PurchaseOrderStatus> get cancellations =>
      choices.where((status) => status == cancelled).toList(growable: false);
}

/// Paperwork raised against a supplier: what we asked for, how much of it has turned up, and
/// what it costs.
///
/// **The cost is what we pay a vendor, which no catalogue can answer.** A sale is priced from
/// the product's own tiers; a purchase is priced by whoever we are buying from, so the cost is
/// typed per line and has no fallback to quote against. [totalAmount] is derived by the server
/// from those lines and never added up here.
///
/// **And the invoice is not the whole cost.** Delivery, unloading and customs are charged on the
/// order rather than on any one line, so the server holds them in [additionalCosts] and spreads
/// them across the lines in proportion to what each is worth — see [PurchaseOrderItem]'s
/// `final` figures. That is the number a job's margin is worked out against, so it is the number
/// the screens lead with.
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
    ///
    /// **Already inclusive of [totalAdditionalCost].** Each line's `final_total_cost` carries its
    /// allocated share, and this is the sum of those — so the two are never added together on
    /// screen, only shown as a total and the part of it that was not goods.
    @JsonKey(name: 'total_amount') String? totalAmount,

    /// Delivery, unloading, customs — what the order cost beyond the goods themselves, summed
    /// by the server from [additionalCosts].
    @JsonKey(name: 'total_additional_cost') String? totalAdditionalCost,

    /// The order-level costs one by one, as they were typed.
    ///
    /// **Sent with the list as well as with a single order**, so the edit form always opens on
    /// the full current set — which matters, because saving replaces the set wholesale and a
    /// form that opened on half of it would delete the rest.
    @JsonKey(name: 'additional_costs')
    @Default(<PurchaseOrderAdditionalCost>[])
    List<PurchaseOrderAdditionalCost> additionalCosts,

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

  /// Whether anything beyond the goods was charged on this order.
  ///
  /// Read off the list rather than off [totalAdditionalCost]: most orders have none, and a
  /// «التكاليف الإضافية» section drawn empty — or a «٠ د.ل» row — is a question on every screen
  /// that has no answer worth reading.
  bool get hasAdditionalCosts => additionalCosts.isNotEmpty;
}

/// One order-level cost not tied to any line — delivery, unloading, customs.
///
/// **Spread across the lines by the server, not shown as a separate bill.** Each line's
/// `final_total_cost` already carries its share; this is the itemised split, kept so the detail
/// screen can answer «why is this line dearer than the invoice said».
@freezed
abstract class PurchaseOrderAdditionalCost with _$PurchaseOrderAdditionalCost {
  const factory PurchaseOrderAdditionalCost({
    required int id,
    required String name,

    /// A string like every other money field here: `'10.00'` as the server stored it.
    required String amount,
  }) = _PurchaseOrderAdditionalCost;

  const PurchaseOrderAdditionalCost._();

  factory PurchaseOrderAdditionalCost.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderAdditionalCostFromJson(json);

  /// `'10.00'` → `'10'`, ready for a widget.
  String get amountLabel => groupedDecimal(amount);
}

/// One line: a shelf, how much was ordered, and how much of it has turned up.
///
/// **A line names a stock item, not a product's size — and there is exactly one line per item.**
/// «كيس شحن سادة 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows and one pile of bags, so
/// buying "both" is buying one thing twice. The server now carries a unique index
/// (`purchase_order_items_one_line_per_item`) as well as the `distinct` rule that used to stand
/// alone, so a second line for the same shelf is refused rather than quietly stored — which is why
/// the form refuses to build one in the first place.
@freezed
abstract class PurchaseOrderItem with _$PurchaseOrderItem {
  const factory PurchaseOrderItem({
    required int id,
    @JsonKey(name: 'stock_item_id') required int stockItemId,

    /// The shelf itself, in the six fields the server flattens it into — **borrowed from the
    /// warehouse model rather than copied**, because a purchase-order line, an arrival line and a
    /// balance row all meet the identical shape, and three classes holding it would be three
    /// things to keep in step. It carries no `product_name` and no `image_url`, deliberately:
    /// two products draw on one pile.
    ///
    /// Nullable because it is `whenLoaded`, though every purchase order the API publishes carries
    /// it — `PurchaseOrderListQuery` and the show endpoint both eager-load `items.stockItem`. A
    /// missing key draws a fallback rather than failing the page.
    @JsonKey(name: 'stock_item') StockItemRef? stockItem,

    /// Strings, like every quantity in this app: `'10.000'` as the server stored it. Parsing
    /// one to show it is how a decimal quietly becomes `10.0`.
    @JsonKey(name: 'quantity_ordered') required String quantityOrdered,
    @JsonKey(name: 'quantity_received') required String quantityReceived,

    /// Computed by the server, never here — a client that subtracted would be a second opinion
    /// about arithmetic that decides whether a shipment is refused.
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,

    /// What the vendor charged for this line, and that divided by the quantity.
    ///
    /// **[baseTotalCost] is the one that was typed**; the server derives [baseUnitCost] from it,
    /// never the other way around. Null only on a line written before cost tracking existed.
    /// **Zero is a real answer** — a free replacement from the vendor costs nothing and is not
    /// the same as nobody having said.
    @JsonKey(name: 'base_total_cost') String? baseTotalCost,
    @JsonKey(name: 'base_unit_cost') String? baseUnitCost,

    /// This line's share of the order's delivery, unloading and customs, worked out by the
    /// server in proportion to what the line is worth.
    @JsonKey(name: 'allocated_additional_cost') String? allocatedAdditionalCost,

    /// The landed cost — [baseTotalCost] plus [allocatedAdditionalCost].
    ///
    /// **This is what the goods actually cost us**, and what every screen leads with. Null on a
    /// line the allocator never ran over, where the base figures are all there is.
    @JsonKey(name: 'final_unit_cost') String? finalUnitCost,
    @JsonKey(name: 'final_total_cost') String? finalTotalCost,

    /// What this line is counted in, snapshotted from the **stock item** when the line was
    /// written — `CreatePurchaseOrder` force-fills it from `stockItem->unit` and never trusts a
    /// unit sent by a client, so a request cannot post one the shelf disagrees with.
    ///
    /// Null on a line older than the column, and everything built from it then says nothing
    /// rather than guessing — see [PurchaseLineUnit].
    String? unit,
    @JsonKey(name: 'unit_label') String? unitLabel,
  }) = _PurchaseOrderItem;

  const PurchaseOrderItem._();

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemFromJson(json);

  /// «كيس شحن 25*35» — the server's own `display_name`, drawn as sent.
  ///
  /// **No product name, deliberately.** Two products draw on this line's shelf, so naming either
  /// of them would be picking one arbitrarily — and a buyer chasing a delivery would quote a
  /// product the vendor was never sold.
  String get title => stockItem?.displayName ?? 'مادة #$stockItemId';

  /// `S7` — the shelf's own code, in the space a product name and photograph used to occupy. The
  /// one part of a line safe to read down a phone line to a supplier.
  ///
  /// Null on a line that arrived without its item: nothing to print beats a code invented here.
  String? get itemCode => stockItem?.code;

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

  /// «الكمية المطلوبة (كيلوغرام)».
  String get quantityFieldLabel => lineUnit.quantityField;

  bool get hasReceipts => (double.tryParse(quantityReceived) ?? 0) > 0;

  bool get isOutstanding => (double.tryParse(quantityRemaining) ?? 0) > 0;

  /// Whether a cost was ever recorded against this line.
  ///
  /// **False only on a line older than cost tracking.** A cost of *zero* is a recorded answer —
  /// a free replacement from the vendor — so it renders as «0» rather than «غير مسجّلة».
  bool get hasCost => baseTotalCost != null;

  /// What one of these really cost, ready for a widget.
  ///
  /// **The landed figure when there is one, the base when there is not.** A line the allocator
  /// never ran over has no `final_unit_cost`, and its base cost is a true answer — printing it
  /// beats printing nothing on paperwork somebody is trying to check against a quote.
  String get unitCostLabel =>
      groupedDecimal(finalUnitCost ?? baseUnitCost ?? '0');

  /// What the whole line really cost, on the same rule as [unitCostLabel].
  String get totalCostLabel =>
      groupedDecimal(finalTotalCost ?? baseTotalCost ?? '0');

  /// What the vendor invoiced for this line, before anything was spread onto it.
  String get baseTotalCostLabel => groupedDecimal(baseTotalCost ?? '0');

  /// This line's share of the order's additional costs.
  String get allocatedCostLabel =>
      groupedDecimal(allocatedAdditionalCost ?? '0');

  /// Whether any of the order's additional costs landed here.
  ///
  /// **Zero is not worth splitting out.** Most orders carry no delivery or customs at all, and
  /// «الأساسي ٧٥ د.ل + إضافي ٠ د.ل» on every line of every one of them is a sentence that says
  /// the price twice and explains nothing.
  bool get hasAllocatedCost =>
      (double.tryParse(allocatedAdditionalCost ?? '0') ?? 0) > 0;
}

/// What a purchase-order line is counted in, and every phrase this app builds out of it.
///
/// **A quantity on a buying screen without its unit is a number nobody can act on.** «٥٠٠»
/// against «لفة نايلون شفاف» is five hundred *kilograms* — that shelf is counted by weight — and
/// a buyer reading it as five hundred rolls orders about a tonne of the wrong thing. The server
/// sends `unit_label` on every line; this is what stops the screens dropping it.
///
/// **The unit is the shelf's, not the product's.** It used to be snapshotted from the product's
/// `stock_unit`, which two products sharing one pile could disagree about; that column is gone and
/// `stock_items.unit` replaced it. `pricing_unit` — what the *customer* is charged by — is a
/// different question and is deliberately not this.
///
/// **One place for the wording, and the Arabic is the reason.** Three surfaces print these — the
/// form's quantity box, the line on the order, the receiving sheet — and «لل» + «كيلوغرام» is
/// exactly the kind of join that comes out «لل كيلوغرام» on the third copy. It also keeps the
/// form and the saved line saying the same word: a form that asks in one unit and a screen that
/// reports the answer in another is the failure this exists to prevent.
///
/// The cost box is deliberately *not* here: it asks for the line's total, which is money and not
/// a quantity, so it names no unit at all.
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

  /// «الكمية المطلوبة (كيلوغرام)».
  ///
  /// The unit in brackets rather than inside the sentence: it is a note about what the box
  /// expects, not part of what is being asked for.
  String get quantityField =>
      label == null ? 'الكمية المطلوبة' : 'الكمية المطلوبة ($label)';

  /// «الكمية التي وصلت (كيلوغرام)» — the box a storeman types a weighbridge figure into.
  String get receivedField =>
      label == null ? 'الكمية التي وصلت' : 'الكمية التي وصلت ($label)';

  @override
  bool operator ==(Object other) =>
      other is PurchaseLineUnit && other.label == label;

  @override
  int get hashCode => label.hashCode;
}
