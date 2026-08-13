import 'package:flutter/foundation.dart';

/// The order the customer list is read in.
///
/// Wire values, spelled as `CustomerSort` spells them on the server. This app keeps no second
/// vocabulary for anything the API names — see `OrderStatus.wire`.
enum CustomersSort {
  /// Newest first. The register, and what the tab opens on.
  newest('newest'),

  /// The longest since their last order, first — «الزبائن اللي ليهم فترة ماطلبوش».
  ///
  /// The customers who never ordered come last on this sort, and every row it returns carries
  /// `last_order_at` so the card can show the number the list was sorted by.
  leastRecentOrder('least_recent_order');

  const CustomersSort(this.wire);

  final String wire;
}

/// The two questions the filter sheet asks about a customer's orders.
///
/// A plain immutable class rather than a Freezed model: it never crosses the wire and is never
/// stored. Equality is hand-written and is load-bearing — `CustomersCubit.applyFilter` uses it
/// to tell a tap that changed something from a tap that did not.
@immutable
class CustomersFilter {
  const CustomersFilter({this.hasOrders, this.leastRecentOrderFirst = false});

  /// Whether the list is narrowed by whether they have ever ordered, and which way.
  ///
  /// **Three states, and null is one of them**: null is everybody, `false` is «زبائن بدون طلب»,
  /// `true` is «لديهم طلبات». A `bool` with a default would have made the third state
  /// unsayable, and `has_orders=0` sent for «الكل» is a filter rather than the absence of one.
  ///
  /// Sent to the API under its own name. A cancelled order still counts as one, exactly as it
  /// does in the number on the card; a deleted one does not. That rule lives on the server, and
  /// this field does not restate it.
  final bool? hasOrders;

  /// «الأقدم طلباً» — the customer nobody has heard from for longest, at the top.
  final bool leastRecentOrderFirst;

  CustomersSort get sort =>
      leastRecentOrderFirst ? CustomersSort.leastRecentOrder : CustomersSort.newest;

  /// Whether the list is showing anything other than its plain self — what the filter button
  /// is drawn from. A sort counts: the rows are in an order somebody chose, and the button is
  /// the only thing on the screen that says so.
  bool get isNarrowed => hasOrders != null || leastRecentOrderFirst;

  /// Both of them read the orders, so the whole sheet is hidden from anybody who may not see
  /// them — the server refuses either question with a 403, and a button that opens a refusal is
  /// worse than no button.
  static const CustomersFilter none = CustomersFilter();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomersFilter &&
          other.hasOrders == hasOrders &&
          other.leastRecentOrderFirst == leastRecentOrderFirst;

  @override
  int get hashCode => Object.hash(hasOrders, leastRecentOrderFirst);
}
