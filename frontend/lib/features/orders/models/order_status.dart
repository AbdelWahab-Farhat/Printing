import 'package:freezed_annotation/freezed_annotation.dart';

/// Where an order is in the workshop, as the app understands it.
///
/// **The app parses this for grouping and colour; it never uses it for the words on screen.**
/// Every order carries `status_label` from the server, and that is what is rendered. The split
/// matters: the backend can add a thirteenth status tomorrow and this app will show it with the
/// right Arabic and a neutral chip instead of failing to parse the whole list — see [unknown].
///
/// Mirrors `OrderStatus.php`. The transition *rules* deliberately do not: the server sends
/// `available_transitions` already narrowed to what the signed-in user may do, so a copy of the
/// map here would be a second source of truth with nothing keeping it honest.
enum OrderStatus {
  @JsonValue('new')
  taken('new'),
  @JsonValue('designing')
  designing('designing'),
  @JsonValue('printing')
  printing('printing'),
  @JsonValue('ready')
  ready('ready'),
  @JsonValue('shortage')
  shortage('shortage'),
  @JsonValue('office_pickup')
  officePickup('office_pickup'),
  @JsonValue('out_for_delivery')
  outForDelivery('out_for_delivery'),
  @JsonValue('delivered')
  delivered('delivered'),
  @JsonValue('settled')
  settled('settled'),
  @JsonValue('returned_courier')
  returnedCourier('returned_courier'),
  @JsonValue('returned_carrier')
  returnedCarrier('returned_carrier'),
  @JsonValue('returned_office')
  returnedOffice('returned_office'),
  @JsonValue('resend')
  resend('resend'),
  @JsonValue('cancelled')
  cancelled('cancelled'),

  /// A status this build of the app has never heard of.
  ///
  /// Reached through `@JsonKey(unknownEnumValue:)`. Without it, one new status on the server
  /// turns every list containing one order into a parse failure — a whole screen lost to a row
  /// the user could otherwise have read perfectly well, since the label came with it.
  unknown('unknown');

  const OrderStatus(this.wire);

  /// Exactly the string the API sends.
  final String wire;

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
enum OrderStatusTone { fresh, working, ready, attention, moving, done, returned, cancelled, neutral }

/// The chips above the orders list.
///
/// Not the same list as [OrderStatus], and that is the point: staff think in *queues*, not in
/// statuses. «قيد التنفيذ» is three statuses and «رواجع» is another three, and asking someone to
/// tap each one separately to see the work in the workshop would be making them do the grouping
/// the screen should have done.
enum OrderQueue {
  all('الكل', <OrderStatus>[]),
  taken('جديدة', [OrderStatus.taken]),
  inProgress('قيد التنفيذ', [OrderStatus.designing, OrderStatus.printing]),
  ready('جاهزة', [OrderStatus.ready]),
  shortage('نواقص', [OrderStatus.shortage]),
  moving('عند العميل', [OrderStatus.officePickup, OrderStatus.outForDelivery]),
  // A re-send belongs here rather than beside «جاهزة»: the parcel is one that came back, and
  // the person working this queue is working the shelf of returns.
  returned('رواجع', [
    OrderStatus.returnedCourier,
    OrderStatus.returnedCarrier,
    OrderStatus.returnedOffice,
    OrderStatus.resend,
  ]),
  delivered('تم الاستلام', [OrderStatus.delivered]),
  settled('تم التسوية', [OrderStatus.settled]),
  cancelled('ملغاة', [OrderStatus.cancelled]);

  const OrderQueue(this.label, this.statuses);

  final String label;
  final List<OrderStatus> statuses;

  /// What goes on the wire as `status[]`. Empty for «الكل», which sends nothing at all.
  List<String> get wires => statuses.map((s) => s.wire).toList(growable: false);
}
