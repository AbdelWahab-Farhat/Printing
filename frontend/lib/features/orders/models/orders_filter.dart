import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
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

  /// Which end of the queue the screen opens at, before anybody touches the button.
  ///
  /// **«جاهزة للطباعة» opens at the far end, and it is the only one that does.** That queue is
  /// not a list somebody browses — it is the pile the press works through, and the job that has
  /// been waiting longest is the one to pick up next. Opened newest-first, the oldest job in the
  /// shop sits behind however many pages have piled on top of it, which is the one place in the
  /// list nobody scrolls to.
  ///
  /// Every other card keeps «الأحدث أولاً»: «جاهزة» is a shelf somebody is asked about — «أين
  /// طلبية فلان؟» — and there the thing taken five minutes ago is the thing asked about.
  ///
  /// **Only when that status is the whole question.** A screen showing several statuses at once
  /// — the customer's «الطلبات الجارية» — is not the press's queue even when «جاهزة للطباعة» is
  /// among them, and turning it round there would reverse a list nobody asked to reverse.
  ///
  /// It decides where the screen *starts*, not where it stays: the button on it overrides this
  /// with one tap, and what the reader picks survives every page after.
  OrdersSort get initialSort =>
      statuses.length == 1 && statuses.first == OrderStatus.readyToPrint.wire
      ? OrdersSort.oldest
      : OrdersSort.fallback;
}
