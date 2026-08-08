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
  @JsonValue('new')
  taken('new', 'جديدة'),
  @JsonValue('designing')
  designing('designing', 'قيد التصميم'),
  @JsonValue('printing')
  printing('printing', 'قيد الطباعة'),
  @JsonValue('ready')
  ready('ready', 'جاهزة'),
  @JsonValue('shortage')
  shortage('shortage', 'نواقص'),
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

  /// The rows the filter offers, in the order the state machine walks them.
  ///
  /// [unknown] is left out: it is this app's own invention for a status the server added after
  /// this build shipped, and sending it as a filter would ask for something that does not exist.
  static List<OrderStatus> get filterable =>
      values.where((status) => status != OrderStatus.unknown).toList(growable: false);

  /// Which family of colours the chip draws from.
  ///
  /// Grouped rather than one colour per status: twelve distinct colours is not a legend anyone
  /// learns, and the question a person actually asks of a list is "is this still in the
  /// workshop, on its way, come back, or finished".
  OrderStatusTone get tone => switch (this) {
    OrderStatus.taken => OrderStatusTone.fresh,
    OrderStatus.designing || OrderStatus.printing => OrderStatusTone.working,
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
