import 'package:printing/features/orders/models/order_payment.dart';
import 'package:printing/features/orders/models/order_status.dart';

/// How many orders sit in each status right now.
///
/// The number beside each row of the status filter. Held as a map keyed by the *wire* value
/// rather than by [OrderStatus], so a status this build has never heard of still arrives with
/// its number attached — the same forward-compatibility [OrderStatus.unknown] buys for the list
/// itself.
///
/// A plain class, not Freezed: it is a map and a total, its JSON is one nested object rather
/// than a field list, and hand-writing `fromJson` is shorter than the annotations that would
/// generate it.
class OrderCounts {
  const OrderCounts({
    required this.byStatus,
    required this.total,
    this.byPaymentStatus = const <String, int>{},
  });

  const OrderCounts.empty()
    : byStatus = const <String, int>{},
      byPaymentStatus = const <String, int>{},
      total = 0;

  final Map<String, int> byStatus;

  /// How many orders stand unpaid, part-paid, paid and overpaid.
  ///
  /// **A second axis, not a subset of the first.** «جاهزة» says nothing about whether an order
  /// is paid, so these numbers describe the same orders along a line that crosses the statuses
  /// above — which is exactly why the filter offers both and never merges them.
  final Map<String, int> byPaymentStatus;

  final int total;

  factory OrderCounts.fromJson(Map<String, dynamic> json) {
    return OrderCounts(
      byStatus: _tally(json['counts']),
      byPaymentStatus: _tally(json['payment_counts']),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, int> _tally(Object? raw) => raw is Map<String, dynamic>
      ? raw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0))
      : const <String, int>{};

  /// What to show beside one row of the filter. Null is «الكل», which is the total the server
  /// sent rather than a sum this app adds up — the server counted the same set the list came
  /// from, and re-deriving the total here would drift the moment a status was added.
  int forStatus(OrderStatus? status) => status == null ? total : byStatus[status.wire] ?? 0;

  /// What to show beside one payment row. Keyed by the wire value for the same reason the
  /// statuses are: a state this build has never heard of still arrives and is still counted.
  int forPaymentStatus(PaymentStatus status) => byPaymentStatus[status.wire] ?? 0;

  /// How many orders sit across a group of statuses — «الطلبات الجارية», «المستلمة».
  ///
  /// **Added up here rather than asked for again.** The server already answered per status for
  /// this exact set of orders, so a second and third request narrowed by status would return
  /// numbers this one already contains — and could disagree with it, since the two answers would
  /// describe two different moments.
  ///
  /// A status missing from [byStatus] contributes zero, which is what a server that stopped
  /// sending a key would mean. [total] is deliberately *not* built this way: see the note on it.
  int forStatuses(Iterable<OrderStatus> statuses) => statuses.fold(
    0,
    (sum, status) => sum + (byStatus[status.wire] ?? 0),
  );
}
