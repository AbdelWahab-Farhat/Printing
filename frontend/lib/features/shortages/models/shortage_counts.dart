import 'package:dayaa/features/shortages/models/shortage.dart';

/// How many shortages sit in each status right now.
///
/// What the chip row above the list reads «جديد ١٢ · جاري البحث ٧ · غير متوفر ٣ · مكتمل ٢٥»
/// from, in one call. Held as a map keyed by the *wire* value rather than by [ShortageStatus], so
/// a status this build has never heard of still arrives with its number attached — the same
/// forward compatibility [ShortageStatus.unknown] buys for the list itself.
///
/// **Every status is present, zeros included.** A missing key would leave the caller choosing
/// between a blank and a zero, and the two mean different things.
///
/// A plain class, not Freezed, for the same reasons `PurchaseOrderCounts` is one: it is a map and
/// a total, its JSON is one nested object rather than a field list, and hand-writing `fromJson`
/// is shorter than the annotations that would generate it.
class ShortageCounts {
  const ShortageCounts({required this.byStatus, required this.total});

  const ShortageCounts.empty() : byStatus = const <String, int>{}, total = 0;

  final Map<String, int> byStatus;

  /// The server's own sum.
  ///
  /// **Read rather than added up**, so a status the server added after this build shipped is
  /// still inside the number. Summing [byStatus] here would quietly undercount, and an undercount
  /// that never says so is worse than a blank.
  final int total;

  factory ShortageCounts.fromJson(Map<String, dynamic> json) {
    final raw = json['counts'];

    return ShortageCounts(
      byStatus: raw is Map<String, dynamic>
          ? raw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0))
          : const <String, int>{},
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// How many sit in one status — zero for a status the server did not mention.
  int forStatus(ShortageStatus status) => byStatus[status.wire] ?? 0;
}
