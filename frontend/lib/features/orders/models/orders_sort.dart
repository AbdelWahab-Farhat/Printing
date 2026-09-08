/// Which end of the queue the orders list starts at.
///
/// **Two, and no more.** Sorting by total, by customer or by status was considered and left out:
/// a work queue is read in one dimension — time — and the other three are questions the filters
/// already answer better. A sort menu of six entries is six taps to find the two anybody uses.
///
/// The labels live here rather than arriving from the server, unlike a status's. There is no
/// server-side vocabulary to drift from: these two words describe what *this screen* does with a
/// list it already has, and the API knows them only as `newest` and `oldest`.
enum OrdersSort {
  /// What the list has always done — the order somebody rang about five minutes ago, first.
  newest('newest', 'الأحدث أولاً'),

  /// What has been waiting longest, read from the far end of the queue.
  oldest('oldest', 'الأقدم أولاً');

  const OrdersSort(this.wire, this.label);

  /// The value the API takes as `sort`.
  final String wire;

  final String label;

  /// The one the list falls back to, and the one that is never sent.
  static const OrdersSort fallback = OrdersSort.newest;
}
