import 'package:flutter/foundation.dart';

/// A question about the نواقص, and the words to put at the top of the answer.
///
/// A plain class rather than a Freezed model, exactly as `PurchaseOrdersFilter` is: it never
/// crosses the wire and is never stored. It travels as `extra` on one route.
///
/// **[assignedTo] is a `String` and not an id**, because two of its three values are not ids:
/// `me` is only knowable on the server from the bearer token, and `none` is a null a query string
/// cannot otherwise carry. «غير مُسنَد» is a queue a supervisor actually works from, which is why
/// it is a value rather than the absence of one.
@immutable
class ShortagesFilter {
  const ShortagesFilter({
    required this.title,
    this.statuses = const [],
    this.assignedTo,
    this.productId,
    this.orderId,
    this.customerId,
    this.source,
  });

  /// What to call the answer — «النواقص المسندة إليّ».
  final String title;

  /// Wire values. Empty means every status, completed ones included — see the list screen's own
  /// note on why «مكتمل» is not buried.
  final List<String> statuses;

  /// A user id as a string, `'me'`, or `'none'`. Null asks about everybody's.
  final String? assignedTo;

  final int? productId;
  final int? orderId;
  final int? customerId;

  /// `manual` or `order`. Null is both.
  final String? source;
}
