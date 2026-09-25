import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_order.freezed.dart';
part 'customer_order.g.dart';

/// Where an order has got to, in words a customer can act on.
///
/// **Eight stages where the workshop has nineteen statuses, and the collapsing happens on the
/// server.** «قيد التصنيع» would tell a customer we did not make their bags ourselves; «نواقص»
/// that our shelf was empty; «انتظار العربون» is the shop arguing about money through a status
/// label. None of it reaches this app — see `CustomerOrderStage` in the backend.
///
/// So this enum is reading a decision, not making one, and it carries no mapping of its own.
/// `unknown` exists only so a stage added after this build shipped cannot crash the list.
/// **Every case carries its `@JsonValue`, including the ones that look like they do not need
/// it.** `json_serializable` encodes an enum by its *Dart member name* unless told otherwise, so
/// `underReview` was being matched against the server's `under_review` and `onTheWay` against
/// `on_the_way` — neither matched, both fell to [unknown], and the one visible consequence was
/// that «بانتظار المراجعة»'s explanation on the order screen never appeared for the stage it
/// was written for. It failed quietly because `unknownEnumValue` is doing its job: a stage the
/// app cannot name still draws, with the server's Arabic in it.
///
/// The single-word cases are spelled out too, for the same reason a spelling that happens to
/// agree today is not a spelling anybody checked.
enum OrderStage {
  @JsonValue('under_review')
  underReview,
  @JsonValue('preparing')
  preparing,
  @JsonValue('designing')
  designing,
  @JsonValue('producing')
  producing,
  @JsonValue('ready')
  ready,
  @JsonValue('on_the_way')
  onTheWay,
  @JsonValue('delivered')
  delivered,
  @JsonValue('returned')
  returned,
  @JsonValue('cancelled')
  cancelled,

  /// The shop would not take this request.
  ///
  /// **Its own stage rather than «ملغاة», because they are not the same news.** «ملغاة» is an
  /// order the shop took and then wrote off; this one was never taken. Folding them would tell
  /// somebody their order was cancelled when nothing was ever agreed, and leave them no way to
  /// tell «بدأنا ثم توقفنا» from «لم نستطع قبول هذا».
  @JsonValue('rejected')
  rejected,

  /// A stage added to the API after this build. Drawn with the label the server sent.
  unknown,
}

/// ما تُضيَّق إليه «طلباتي»: «كل الحالات»، ثم كل مرحلةٍ وحدها (طلب المستخدم، 2026-09-25).
///
/// **المراحل العشر كلها، بترتيب ما تمرّ به الطلبية** — من «بانتظار المراجعة» إلى «تم الاستلام»،
/// ثم النهايات الثلاث الأخرى. كانت الاختيارات أربعاً تجمع المراحل في أسئلة («قيد التنفيذ»
/// و«مكتملة»)، فلم يكن يُعرف منها أين طلبيةٌ بعينها. الآن كل اختيارٍ مرحلةٌ واحدة، تصل الخادم
/// `stage=` بلغة التطبيق، ولا يتعلّم التطبيق حالات الورشة التسع عشرة. تُختار من ورقةٍ سفلية —
/// انظر `StageFilterField`.
///
/// **الكلمات هنا لا من الطلبية**، لأن الاختيار لا طلبية في يده تقرأ منها كلمتها — واختيارٌ لا
/// طلبية خلفه هو بالضبط الذي قد يُسأل عنه. ولذلك يمسكها `orders_filter_test` بكلمات الخادم
/// نفسها، مقروءةً من `CustomerOrderStage.php`.
enum OrdersFilter {
  all(label: 'كل الحالات'),
  underReview(label: 'بانتظار المراجعة', stage: OrderStage.underReview),
  preparing(label: 'قيد التجهيز', stage: OrderStage.preparing),
  designing(label: 'قيد التصميم', stage: OrderStage.designing),
  producing(label: 'قيد الإنتاج', stage: OrderStage.producing),
  ready(label: 'جاهزة', stage: OrderStage.ready),
  onTheWay(label: 'جاري التوصيل', stage: OrderStage.onTheWay),
  delivered(label: 'تم الاستلام', stage: OrderStage.delivered),
  returned(label: 'مرتجعة', stage: OrderStage.returned),
  cancelled(label: 'ملغاة', stage: OrderStage.cancelled),
  rejected(label: 'مرفوضة', stage: OrderStage.rejected);

  const OrdersFilter({required this.label, this.stage});

  final String label;

  /// المرحلة المختارة، وnull لـ«كل الحالات».
  final OrderStage? stage;

  /// قيمة `stage=` كما يأخذها الـ API، أو null لـ«كل الحالات».
  ///
  /// **الاسم الذي على السلك لا اسم العضو في Dart** — انظر الملاحظة على [OrderStage] عن
  /// `@JsonValue` الذي كان ناقصاً من اثنين منها.
  String? get stageParameter => switch (stage) {
    null => null,
    OrderStage.underReview => 'under_review',
    OrderStage.preparing => 'preparing',
    OrderStage.designing => 'designing',
    OrderStage.producing => 'producing',
    OrderStage.ready => 'ready',
    OrderStage.onTheWay => 'on_the_way',
    OrderStage.delivered => 'delivered',
    OrderStage.returned => 'returned',
    OrderStage.cancelled => 'cancelled',
    OrderStage.rejected => 'rejected',
    OrderStage.unknown => null,
  };

  /// هل ما زالت الطلبية تنتمي إلى القائمة بعد أن تحرّكت.
  ///
  /// يغذّي `PagedCubit.belongs`، فالطلبية التي تغادر حالتها وهي على الشاشة تغادر القائمة معها:
  /// اختيارٌ يبقي ما لم يعد يطابقه كاذبٌ حتى التحديث التالي.
  bool admits(CustomerOrder order) => stage == null || order.stage == stage;
}

/// One line of «طلباتي».
@freezed
abstract class CustomerOrder with _$CustomerOrder {
  const factory CustomerOrder({
    required int id,

    /// «1228» — what the customer reads out when they ring.
    required String code,

    @JsonKey(unknownEnumValue: OrderStage.unknown)
    @Default(OrderStage.unknown)
    OrderStage stage,

    /// **Always drawn instead of translating [stage] here.** The Arabic travels with the value,
    /// so a stage added to the business appears correctly without an app release.
    @JsonKey(name: 'stage_label') required String stageLabel,

    @JsonKey(name: 'is_open') @Default(true) bool isOpen,

    /// The sentence the card draws under the line — «نراجع طلبيتك ونؤكّدها خلال ساعات العمل».
    ///
    /// **Also the server's, and for the same reason as [stageLabel].** A `switch` over
    /// [OrderStage] written here would be a second copy of a mapping the backend keeps in one
    /// place, and a stage added to the business would arrive with no sentence. Null for the
    /// stages that are over: nothing reassuring is owed about a delivered order.
    @JsonKey(name: 'stage_hint') String? stageHint,

    /// «كيس شحن فلاير ٣٠×٤٠ و٢ أخرى» — built by the server so the list draws without opening
    /// every order to write a subtitle.
    String? summary,

    @JsonKey(name: 'items_count') int? itemsCount,

    /// A decimal string, like every amount in this app — **and null while the shop has not
    /// priced every line**, which is what [isAwaitingQuote] says in one word. The card draws
    /// «يُحدَّد بعد المراجعة» rather than a figure smaller than the real one.
    String? total,

    @JsonKey(name: 'is_awaiting_quote') @Default(false) bool isAwaitingQuote,

    // ── ما ترسمه البطاقة ─────────────────────────────────────────────────────
    // بطاقة «طلباتي» على شكل بطاقة تطبيق الموظفين (طلب المستخدم، 2026-09-25)، وهذه خاناتها.
    // **كلها اختيارية**: التطبيق قد يصل الهاتف قبل أن يُنشر الخادم الذي يرسلها، والبطاقة ترسم
    // «—» حيث لا جواب بدل أن تُسقط القائمة كلها.

    /// ما دُفع. **فارغٌ ما دام بندٌ بلا سعر**، كـ[total] وللسبب نفسه.
    @JsonKey(name: 'paid_amount') String? paidAmount,

    /// ما بقي على العميل. فارغٌ كذلك ما دام بندٌ بلا سعر.
    String? balance,

    /// المدينة كما سجّلتها الطلبية، لا كما هي اليوم.
    @JsonKey(name: 'city_name') String? cityName,

    @JsonKey(name: 'recipient_phone') String? recipientPhone,
    @JsonKey(name: 'fulfilment_type') String? fulfilmentType,

    /// «توصيل» أو «استلام من المكتب»، بكلمة الخادم.
    @JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,

    /// البنود، لذيل البطاقة.
    @Default(<OrderLine>[]) List<OrderLine> items,

    @JsonKey(name: 'placed_at') DateTime? placedAt,
  }) = _CustomerOrder;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) =>
      _$CustomerOrderFromJson(json);
}

/// One line of an order.
@freezed
abstract class OrderLine with _$OrderLine {
  const factory OrderLine({
    required int id,
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'variant_label') String? variantLabel,
    required String quantity,

    /// «قطعة» أو «كيلو»: «٣٠٠» وحدها لا تقول ٣٠٠ ماذا.
    @JsonKey(name: 'pricing_unit_label') String? pricingUnitLabel,

    /// **Null until the shop quotes it.** A product priced «حسب الطلب» is ordered without a
    /// price — the app is never told one and must not invent one — and a zero here would read
    /// as «مجاناً» on the customer's own screen.
    @JsonKey(name: 'unit_price') String? unitPrice,
    @JsonKey(name: 'line_total') String? lineTotal,

    /// صورة المنتج كما هي في الكتالوج اليوم — تصل مع الطلبية المفتوحة وحدها، و«طلباتي» لا
    /// يصلها المفتاح. null ترسم شكل الكيس مكانها (`ProductThumbnail`).
    @JsonKey(name: 'product_image_url') String? productImageUrl,
  }) = _OrderLine;

  factory OrderLine.fromJson(Map<String, dynamic> json) => _$OrderLineFromJson(json);
}

/// One step of the order's journey, as the customer reads it.
///
/// **The stages reached, not the transitions recorded.** The workshop writes a row for every
/// move — «جاهزة للطباعة» at 14:05, «قيد الطباعة» at 14:40 — and five of those collapse into
/// «قيد التجهيز». The server folds them and keeps the moment each stage was *first* reached, so
/// this list draws one tick per thing that happened.
@freezed
abstract class OrderTimelineEntry with _$OrderTimelineEntry {
  const factory OrderTimelineEntry({
    required String stage,
    @JsonKey(name: 'stage_label') required String stageLabel,
    @JsonKey(name: 'reached_at') DateTime? reachedAt,
  }) = _OrderTimelineEntry;

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) =>
      _$OrderTimelineEntryFromJson(json);
}

/// المرحلة التي بلغتها خطوة المسار، مقروءةً بالقاموس نفسه الذي تُقرأ به `stage` على الطلبية.
///
/// **القاموس المولَّد لا نسخةٌ ثانية منه.** `stage` هنا نصّ السلك كما هو (`'under_review'`)،
/// وقراءته بـ`switch` مكتوبٍ باليد نسخةٌ ثالثة من أسماءٍ مكتوبة مرتين أصلاً (`@JsonValue`
/// و`OrdersFilter.stageParameter`). ومرحلةٌ لا يعرفها هذا الإصدار تُقرأ [OrderStage.unknown].
extension OrderTimelineEntryStage on OrderTimelineEntry {
  OrderStage get orderStage =>
      $enumDecode(_$OrderStageEnumMap, stage, unknownValue: OrderStage.unknown);
}

/// An order, opened.
@freezed
abstract class CustomerOrderDetail with _$CustomerOrderDetail {
  const factory CustomerOrderDetail({
    required int id,
    required String code,

    @JsonKey(unknownEnumValue: OrderStage.unknown)
    @Default(OrderStage.unknown)
    OrderStage stage,
    @JsonKey(name: 'stage_label') required String stageLabel,
    @JsonKey(name: 'is_open') @Default(true) bool isOpen,
    @JsonKey(name: 'stage_hint') String? stageHint,

    /// Why the shop would not take this request.
    ///
    /// **The only reason string that reaches this app.** An order's `cancellation_reason` is
    /// written for the accountant about something the shop took and wrote off, and it stays on
    /// the staff side. This one is the shop's answer to the person who placed the order. Null on
    /// every order that was not refused.
    @JsonKey(name: 'rejection_reason') String? rejectionReason,

    /// The snapshot the order carries, not a live lookup — a renamed district must not rewrite
    /// where an old order said it was headed.
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'region_name') String? regionName,
    @JsonKey(name: 'address_details') String? addressDetails,
    @JsonKey(name: 'recipient_name') String? recipientName,
    @JsonKey(name: 'recipient_phone') String? recipientPhone,
    @JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,

    @Default(<OrderLine>[]) List<OrderLine> items,

    /// Every number here is one the customer is owed an answer about. What the goods cost the
    /// shop is not among them and never arrives.
    @JsonKey(name: 'items_total') String? itemsTotal,
    @JsonKey(name: 'delivery_price') String? deliveryPrice,
    @JsonKey(name: 'design_fee') String? designFee,
    String? discount,

    /// **Null while the shop has not quoted every line.**
    ///
    /// A product priced «حسب الطلب» reaches an order with no price, and the server sends null
    /// rather than the figure it has — that figure is the sum of the priced lines only, and
    /// showing it would quote a number smaller than what will actually be asked for. The screen
    /// draws «يُحدَّد بعد المراجعة» instead; see [isAwaitingQuote].
    String? total,
    @JsonKey(name: 'paid_amount') String? paidAmount,
    String? balance,

    /// Whether any line is still waiting to be priced.
    ///
    /// **The decided answer, sent rather than inferred.** Working it out from a handful of
    /// nulls would make every screen re-derive the same rule, and get it subtly different.
    @JsonKey(name: 'is_awaiting_quote') @Default(false) bool isAwaitingQuote,

    @Default(<OrderTimelineEntry>[]) List<OrderTimelineEntry> timeline,

    @JsonKey(name: 'placed_at') DateTime? placedAt,
  }) = _CustomerOrderDetail;

  factory CustomerOrderDetail.fromJson(Map<String, dynamic> json) =>
      _$CustomerOrderDetailFromJson(json);
}

/// One line of an order being placed.
@freezed
abstract class NewOrderLine with _$NewOrderLine {
  const factory NewOrderLine({
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_variant_id') required int productVariantId,
    required String quantity,
  }) = _NewOrderLine;

  factory NewOrderLine.fromJson(Map<String, dynamic> json) => _$NewOrderLineFromJson(json);
}

/// What this app sends to place an order.
///
/// **Short, and every absence is deliberate.** No customer id — it comes from the token. No unit
/// price — the server prices every line. No discount, no vendor, no tracking number: those are
/// staff decisions behind permissions a customer does not hold. See `RequestOrderRequest` in the
/// backend for the full list and the reason for each.
///
/// ولا اسمَ مستلمٍ ولا عنوانَ حرّاً: المستلم هو العميل نفسه، والوجهة مدينةٌ ومنطقةٌ ومتجر.
@freezed
abstract class NewOrder with _$NewOrder {
  const factory NewOrder({
    @JsonKey(name: 'city_id') required int cityId,
    required List<NewOrderLine> items,
    @JsonKey(name: 'region_id') int? regionId,
    @JsonKey(name: 'customer_shop_id') int? customerShopId,
    @JsonKey(name: 'recipient_phone') String? recipientPhone,
    @JsonKey(name: 'design_ids') @Default(<int>[]) List<int> designIds,

    /// What the customer wants to say about the order. It lands in the order's note prefixed
    /// «ملاحظة العميل:», so whoever reviews it can see at a glance whose words they are.
    @JsonKey(name: 'customer_note') String? customerNote,
  }) = _NewOrder;

  factory NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);
}
