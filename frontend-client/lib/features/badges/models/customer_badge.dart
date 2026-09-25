/// Something waiting for the customer, drawn as a number on the tile it belongs to.
///
/// **This enum mirrors the server's `CustomerBadge` and is pinned to it** by
/// `customer_badge_contract_test`. The wire spelling is what the API keys its answer by, and a
/// spelling that happens to agree today is not one anybody checked — this app has already
/// shipped an enum whose cases silently matched nothing, and the only visible symptom was a
/// notice that never appeared.
///
/// **A key this build has never heard of is ignored, not crashed on.** The server may grow a
/// badge before the app does, and an older build must keep drawing the ones it knows.
enum CustomerBadge {
  /// Replies from the shop the customer has not read.
  support('support');

  const CustomerBadge(this.wire);

  /// What the API calls it. **Written out rather than taken from [name]**, which would encode
  /// the Dart spelling and break the moment a case is named differently from its key.
  final String wire;

  /// The badge this key names, or null when the server has one this build does not know.
  static CustomerBadge? fromWire(String wire) {
    for (final badge in values) {
      if (badge.wire == wire) return badge;
    }

    return null;
  }
}

/// Every badge and its count, as the app holds it.
///
/// A plain map rather than a model per badge: the answer is `{key: count}` and it grows by
/// gaining keys, so a class with a field each would need editing for every new badge — which is
/// the one thing this design exists to avoid.
extension CustomerBadgeCounts on Map<CustomerBadge, int> {
  /// What to draw on one tile. **Zero and absent are the same thing** — a badge nobody has
  /// counted is not a badge worth showing.
  int countOf(CustomerBadge badge) => this[badge] ?? 0;

  bool has(CustomerBadge badge) => countOf(badge) > 0;
}
