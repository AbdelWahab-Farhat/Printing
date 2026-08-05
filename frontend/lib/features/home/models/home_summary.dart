import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_summary.freezed.dart';
part 'home_summary.g.dart';

/// The numbers the home screen opens on.
///
/// One object rather than four counts and a list passed around separately: they are read
/// together, they go stale together, and a screen showing yesterday's order count beside
/// today's customer count is worse than showing neither.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    @JsonKey(name: 'total_orders') required int totalOrders,
    @JsonKey(name: 'customers_count') required int customersCount,
    @JsonKey(name: 'daily_orders') required int dailyOrders,
    @JsonKey(name: 'monthly_orders') required int monthlyOrders,

    /// How the work in progress is split up.
    ///
    /// A list, not a field per status, because the set of statuses is the business's to change:
    /// adding "بانتظار الطباعة" should be a row from the server, not a release of the app.
    @Default(<OrderStatusCount>[]) List<OrderStatusCount> statuses,
  }) = _HomeSummary;

  const HomeSummary._();

  factory HomeSummary.fromJson(Map<String, dynamic> json) => _$HomeSummaryFromJson(json);

  /// Nothing has happened yet — a brand-new shop, not a failure to load.
  bool get isEmpty => totalOrders == 0 && customersCount == 0;
}

/// One status and how many orders sit in it.
@freezed
abstract class OrderStatusCount with _$OrderStatusCount {
  const factory OrderStatusCount({
    /// The machine name to switch on once these become our own statuses — `pending`,
    /// `rejected`. Kept apart from [label] so the UI never compares against Arabic text.
    required String status,

    /// The Arabic label to show, sent by the server so the app holds no translation table.
    required String label,

    required int count,
  }) = _OrderStatusCount;

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusCountFromJson(json);
}
