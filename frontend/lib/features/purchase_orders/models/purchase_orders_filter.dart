import 'package:flutter/foundation.dart';

/// A question about the purchase orders, and the words to put at the top of the answer.
///
/// **Carried rather than re-derived, and the vendor is the reason.** A wrong status shows up as
/// a title that disagrees with the rows under it; a wrong *vendor* produces a screen that looks
/// perfectly correct and belongs to somebody else. So it is set once, by the screen that already
/// knows whose supplier page it is on, and carried onto every page after the first.
///
/// A plain class rather than a Freezed model, exactly as `OrdersFilter` is: it never crosses the
/// wire and is never stored. It travels as `extra` on one route.
@immutable
class PurchaseOrdersFilter {
  const PurchaseOrdersFilter({
    required this.title,
    this.statuses = const [],
    this.vendorId,
  });

  /// What to call the answer — «أوامر الشراء الجارية · مطبعة الصفا».
  final String title;

  /// Wire values. Empty means every status, cancellations included.
  final List<String> statuses;

  /// Whose orders these are. Null is every supplier.
  final int? vendorId;
}
