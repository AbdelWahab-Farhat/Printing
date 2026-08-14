import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warehouse_stock_summary.freezed.dart';
part 'warehouse_stock_summary.g.dart';

/// One warehouse in five numbers — what the screen says before anybody scrolls.
///
/// **[lowStockCount] and [outOfStockCount] overlap, and that is deliberate.** A shelf at zero
/// that somebody asked to be warned about is both, and each count is defined to match *exactly*
/// the filter its button opens — so a button never promises a number the list then contradicts.
///
/// The bar above the list needs the opposite property: three segments that add up to the whole
/// and never draw a line twice. That is what [lowOnlyCount] is for, and why [healthyCount]
/// arrives from the server as a leftover rather than being subtracted here.
@freezed
abstract class WarehouseStockSummary with _$WarehouseStockSummary {
  const factory WarehouseStockSummary({
    /// How many sizes have ever been on these shelves. A line at zero is still a line — its
    /// history is worth more than the tidiness of removing it.
    @JsonKey(name: 'total_lines') @Default(0) int totalLines,

    /// Every balance added together, as the string the server sent. A `double` here would be
    /// the first step towards arithmetic this app has no business doing.
    @JsonKey(name: 'total_quantity') @Default('0.000') String totalQuantity,

    /// Has an alert level and has fallen to it.
    @JsonKey(name: 'low_stock_count') @Default(0) int lowStockCount,

    /// Nothing left on the shelf, whether or not anybody asked to be warned about it.
    @JsonKey(name: 'out_of_stock_count') @Default(0) int outOfStockCount,

    /// Neither low nor empty.
    @JsonKey(name: 'healthy_count') @Default(0) int healthyCount,
  }) = _WarehouseStockSummary;

  const WarehouseStockSummary._();

  factory WarehouseStockSummary.fromJson(Map<String, dynamic> json) =>
      _$WarehouseStockSummaryFromJson(json);

  /// Whether there is anything here at all — an empty warehouse gets a sentence, not a bar.
  bool get hasLines => totalLines > 0;

  /// `'12450.000'` → `'12,450'`: the number this screen is opened for, at arm's length.
  String get totalQuantityLabel => groupedDecimal(totalQuantity);

  /// The bar's middle segment: low, but not *also* empty.
  ///
  /// Clamped, because a bar drawn backwards is not how anybody should discover that a summary
  /// stopped adding up.
  int get lowOnlyCount =>
      (totalLines - healthyCount - outOfStockCount).clamp(0, totalLines);
}
