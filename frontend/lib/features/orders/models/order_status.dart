import 'package:freezed_annotation/freezed_annotation.dart';

/// Where an order is in the workshop, as the app understands it.
///
/// **An order on screen always shows the server's `status_label`, never [label].** The split
/// matters: the backend can add a fifteenth status tomorrow and this app will show it with the
/// right Arabic and a neutral chip instead of failing to parse the whole list — see [unknown].
///
/// [label] exists for the one screen that has no order in hand to read a word from: the filter
/// sheet, which must name a status that nothing in the list is currently sitting in — that is
/// the whole point of a row reading zero. `PaymentStatus` carries its own Arabic for exactly the
/// same reason. `order_status_contract_test.dart` reads `OrderStatus.php` and fails if any word
/// here drifts from the word over there.
///
/// Mirrors `OrderStatus.php`. The transition *rules* deliberately do not: the server sends
/// `available_transitions` already narrowed to what the signed-in user may do, so a copy of the
/// map here would be a second source of truth with nothing keeping it honest.
enum OrderStatus {
  // The six the workshop lives in, in the order the home board draws them — two cards to a row,
  // each row a pair: جديدة/نواقص، قيد التصميم/جاهزة للطباعة، قيد الطباعة/جاهزة. Copied from
  // `OrderStatus.php`'s declaration order so the filter sheet reads down the way the board does.
  // It is *not* the order the state machine walks; the server sends the moves, so this app never
  // needs that one.
  @JsonValue('new')
  taken('new', 'جديدة'),
  @JsonValue('shortage')
  shortage('shortage', 'نواقص'),
  @JsonValue('designing')
  designing('designing', 'قيد التصميم'),

  /// Prepped and weighed by the warehouse, waiting for the press to pick it up.
  ///
  /// The handover between two departments — see `OrderStatus.php`. It is also where the stock
  /// leaves the shelf, but nothing here needs to know that: the sheet draws whatever fields the
  /// server describes for the move.
  @JsonValue('ready_to_print')
  readyToPrint('ready_to_print', 'جاهزة للطباعة'),
  @JsonValue('printing')
  printing('printing', 'قيد الطباعة'),

  /// The job is with an outside vendor, being made. Only وسيط orders reach it — see
  /// OUTSOURCED-PRODUCTS.md §4. It is not «قيد الطباعة» under another name: one status, one
  /// word, and the server sends the word.
  @JsonValue('manufacturing')
  manufacturing('manufacturing', 'قيد التصنيع'),
  @JsonValue('ready')
  ready('ready', 'جاهزة'),
  @JsonValue('office_pickup')
  officePickup('office_pickup', 'استلام مكتب'),
  @JsonValue('out_for_delivery')
  outForDelivery('out_for_delivery', 'جاري التوصيل'),
  @JsonValue('returned_courier')
  returnedCourier('returned_courier', 'راجع لدى المندوب'),
  @JsonValue('returned_carrier')
  returnedCarrier('returned_carrier', 'راجع لدى شركة التوصيل'),
  @JsonValue('returned_office')
  returnedOffice('returned_office', 'راجع مكتب'),
  @JsonValue('resend')
  resend('resend', 'إعادة إرسال'),
  @JsonValue('cancelled')
  cancelled('cancelled', 'إلغاء تام'),

  // The two that are over, last — the same order `OrderStatus.php` declares, so the filter
  // sheet reads down in the order the home board does. What still needs doing comes first.
  @JsonValue('delivered')
  delivered('delivered', 'تم الاستلام'),
  @JsonValue('settled')
  settled('settled', 'تم التسوية'),

  /// A status this build of the app has never heard of.
  ///
  /// Reached through `@JsonKey(unknownEnumValue:)`. Without it, one new status on the server
  /// turns every list containing one order into a parse failure — a whole screen lost to a row
  /// the user could otherwise have read perfectly well, since the label came with it.
  unknown('unknown', 'غير معروفة');

  const OrderStatus(this.wire, this.label);

  /// Exactly the string the API sends.
  final String wire;

  /// The Arabic the filter sheet prints. Never used for an order that is in hand — see the note
  /// on this enum.
  final String label;

  /// The rows the filter offers, in the order the home board draws them.
  ///
  /// [unknown] is left out: it is this app's own invention for a status the server added after
  /// this build shipped, and sending it as a filter would ask for something that does not exist.
  static List<OrderStatus> get filterable =>
      values.where((status) => status != OrderStatus.unknown).toList(growable: false);

  /// Whether nobody in the shop still owes this order a decision.
  ///
  /// The customer has it, the money is agreed, or it was written off. Mirrors
  /// `OrderStatus::isClosed()` on the server, which draws the same line — and
  /// `order_status_groups_test.dart` reads that method and fails if the two drift.
  ///
  /// **«تم الاستلام» counts as finished even though it still has a move to make.** The move is
  /// about money, not bags: the order is out of the workshop and out of everyone's queue, which
  /// is the question this getter answers. [unknown] answers `false` for the honest reason — a
  /// status this build has never heard of is not one it may declare over.
  bool get isFinished => switch (this) {
    OrderStatus.delivered || OrderStatus.settled || OrderStatus.cancelled => true,
    _ => false,
  };

  /// Everything still in somebody's hands — «الطلبات الجارية».
  ///
  /// **Derived from [isFinished] rather than listed.** Two hand-written lists over fourteen
  /// statuses are two things to keep in step, and the one that drifts is always the one nobody
  /// reads. A status added to this enum tomorrow joins this queue by default, which is the right
  /// default: new work is work until somebody says otherwise.
  ///
  /// The three returns and «إعادة إرسال» are in it. A parcel coming back is not an ending — it
  /// goes out again or it is written off, and both are decisions somebody still owes.
  static List<OrderStatus> get inProgress => filterable
      .where((status) => !status.isFinished)
      .toList(growable: false);

  /// What actually reached the customer — «الطلبات المستلمة».
  ///
  /// **«تم التسوية» is in it.** Settled means the bags were handed over *and* the money was
  /// agreed, so a settled order is a received one by definition; leaving it out would drain this
  /// list as orders were settled, which is the opposite of what the word says. «إلغاء تام» is
  /// out for the matching reason — it reached nobody.
  static List<OrderStatus> get received => filterable
      .where((status) => status.isFinished && status != OrderStatus.cancelled)
      .toList(growable: false);

  /// What was written off — «الطلبات الملغاة».
  ///
  /// **Its own box, beside the other two rather than folded into either.** It is not in
  /// progress — nobody will work on it — and not received — it reached nobody. Left without an
  /// entry it was reachable only by opening «كل الطلبات» and filtering, which is a search for
  /// something people ask about directly: «كم طلبية ألغينا لهذا العميل؟».
  ///
  /// Written as a filter over the cancellations rather than as `[cancelled]`, so a second kind
  /// of cancellation added later lands here instead of quietly falling out of all three groups.
  /// See VENDOR-PURCHASE-ORDERS-SECTION.md §١.
  static List<OrderStatus> get cancellations => filterable
      .where((status) => status == OrderStatus.cancelled)
      .toList(growable: false);

  /// Which family of colours the chip draws from.
  ///
  /// Grouped rather than one colour per status: twelve distinct colours is not a legend anyone
  /// learns, and the question a person actually asks of a list is "is this still in the
  /// workshop, on its way, come back, or finished".
  OrderStatusTone get tone => switch (this) {
    OrderStatus.taken => OrderStatusTone.fresh,
    // In the workshop's hands and moving: prepped is no longer untouched, and it is a long way
    // from being finished goods.
    OrderStatus.readyToPrint ||
    OrderStatus.designing ||
    OrderStatus.printing ||
    // On a vendor's bench rather than our press, but the same answer to «هل هي في يد أحد؟».
    OrderStatus.manufacturing => OrderStatusTone.working,
    OrderStatus.ready => OrderStatusTone.ready,
    OrderStatus.shortage => OrderStatusTone.attention,
    OrderStatus.officePickup || OrderStatus.outForDelivery => OrderStatusTone.moving,
    OrderStatus.delivered || OrderStatus.settled => OrderStatusTone.done,
    OrderStatus.returnedCourier ||
    OrderStatus.returnedCarrier ||
    OrderStatus.returnedOffice => OrderStatusTone.returned,
    // On our shelf and going out again — the same colour as anything else waiting to leave.
    OrderStatus.resend => OrderStatusTone.ready,
    OrderStatus.cancelled => OrderStatusTone.cancelled,
    OrderStatus.unknown => OrderStatusTone.neutral,
  };
}

/// The four-and-a-bit families a status chip is drawn from.
enum OrderStatusTone {
  fresh,
  working,
  ready,
  attention,
  moving,
  done,
  returned,
  cancelled,
  neutral,
}

// The filter used to offer *queues* rather than statuses — «قيد التنفيذ» standing for two,
// «رواجع» for four — on the reasoning that staff think in groups. It was removed: the words on
// the sheet were words the rest of the system never uses, so «رواجع ٤» could not be reconciled
// with any status on any card, and a queue that bundled four statuses made «ما الذي ينتظر عند
// شركة التوصيل؟» a question the filter could not ask at all. One vocabulary, everywhere.
