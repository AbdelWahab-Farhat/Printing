import 'package:printing/features/orders/models/order_status.dart';

/// How many orders sit in each status right now.
///
/// The number beside each row of the status filter. Held as a map keyed by the *wire* value
/// rather than by [OrderStatus], so a status this build has never heard of still arrives and is
/// still counted into its queue — the same forward-compatibility [OrderStatus.unknown] buys for
/// the list itself.
///
/// A plain class, not Freezed: it is a map and a total, its JSON is one nested object rather
/// than a field list, and hand-writing `fromJson` is shorter than the annotations that would
/// generate it.
class OrderCounts {
  const OrderCounts({required this.byStatus, required this.total});

  const OrderCounts.empty() : byStatus = const <String, int>{}, total = 0;

  final Map<String, int> byStatus;
  final int total;

  factory OrderCounts.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'];

    return OrderCounts(
      byStatus: raw is Map<String, dynamic>
          ? raw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0))
          : const <String, int>{},
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// What to show beside one chip. «الكل» is the total; every other queue is the sum of the
  /// statuses it covers, because a queue is a group and the server counts by status.
  int forQueue(OrderQueue queue) {
    if (queue.statuses.isEmpty) return total;

    var sum = 0;
    for (final status in queue.statuses) {
      sum += byStatus[status.wire] ?? 0;
    }

    return sum;
  }
}
