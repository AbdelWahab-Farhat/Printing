import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';

/// How many purchase orders sit in each status right now.
///
/// What a supplier's screen reads «الجارية ٣ · المكتملة ٩ · الملغاة ١» from, in one call. Held
/// as a map keyed by the *wire* value rather than by [PurchaseOrderStatus], so a status this
/// build has never heard of still arrives with its number attached — the same forward
/// compatibility [PurchaseOrderStatus.unknown] buys for the list itself.
///
/// A plain class, not Freezed, for the same reasons `OrderCounts` is one: it is a map and a
/// total, its JSON is one nested object rather than a field list, and hand-writing `fromJson` is
/// shorter than the annotations that would generate it.
class PurchaseOrderCounts {
  const PurchaseOrderCounts({required this.byStatus, required this.total});

  const PurchaseOrderCounts.empty()
    : byStatus = const <String, int>{},
      total = 0;

  final Map<String, int> byStatus;

  /// The server's own sum, cancellations and all.
  ///
  /// **Read rather than added up**, so a status the server added after this build shipped is
  /// still inside the number. Summing [byStatus] here would quietly undercount, and an
  /// undercount that never says so is worse than a blank.
  final int total;

  factory PurchaseOrderCounts.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'];

    return PurchaseOrderCounts(
      byStatus: raw is Map<String, dynamic>
          ? raw.map(
              (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
            )
          : const <String, int>{},
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// How many orders sit across a group — «الجارية», «المكتملة», «الملغاة».
  ///
  /// **Added up here rather than asked for again.** The server already answered per status for
  /// this exact set, so a second and third request narrowed by status would return numbers this
  /// one already contains — and could disagree with it, since the two answers would describe two
  /// different moments.
  int forStatuses(Iterable<PurchaseOrderStatus> statuses) =>
      statuses.fold(0, (sum, status) => sum + (byStatus[status.wire] ?? 0));
}
