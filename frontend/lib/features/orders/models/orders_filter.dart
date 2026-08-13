import 'package:flutter/foundation.dart';

/// A question about the orders, and the words to put at the top of the answer.
///
/// **Carried rather than re-derived, and the title is the reason.** A card on the home screen
/// knows it says «نواقص» because the server sent that word with the number; this app holds no
/// table of Arabic status names on purpose, so a screen opened from that card cannot look the
/// word up again — it has to be handed it.
///
/// A plain class rather than a Freezed model: it never crosses the wire and is never stored. It
/// travels as `extra` on one route.
@immutable
class OrdersFilter {
  const OrdersFilter({
    required this.title,
    this.statuses = const [],
    this.paymentStatuses = const [],
    this.customerId,
    this.from,
    this.to,
  });

  /// What to call the answer — «نواقص», «طلبات اليوم».
  final String title;

  /// Wire values. Empty means every status.
  final List<String> statuses;

  /// Wire values of `PaymentStatus`. Empty means every one of them.
  ///
  /// A **second axis that crosses** [statuses] rather than narrowing it — a card on the home
  /// screen reading «غير مدفوعة ١٢» opens every unpaid order, whatever stage each is at.
  final List<String> paymentStatuses;

  /// Whose orders these are. Null is the whole shop.
  ///
  /// **A third axis, and the only one the reader cannot check for themselves.** A wrong status
  /// shows up as a chip that disagrees with the title; a wrong *customer* produces a screen that
  /// looks perfectly correct and belongs to somebody else. So it travels with the title the same
  /// way the statuses do — set once, by the screen that already knows whose page it is on, and
  /// carried onto every page after the first.
  final int? customerId;

  /// Plain `Y-m-d` days in the shop's timezone; the server decides where each day begins.
  final String? from;
  final String? to;
}
