import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sales_statistics.freezed.dart';
part 'sales_statistics.g.dart';

/// حجم المبيعات وحركة الأكياس over one period, exactly as the server computed it.
///
/// **The opposite of [ProfitAndLossSummary] in the one way that matters.** That report warns at
/// length that its parts need not add up — three cost figures from one table, a total from
/// another. Here every figure is folded up from a single grouped row set, so
///
///   * [byType]'s values sum exactly to [SalesValue.total]
///   * [byType]'s weights sum exactly to [WeightComparison.totalKg]
///   * [WeightComparison.plainKg] + [WeightComparison.printedKg] = [WeightComparison.totalKg],
///     per row and overall
///
/// **That is a guarantee about the server's arithmetic, not an invitation to redo it here.**
/// Every figure is taken from the key that carries it — [WeightComparison.printedSharePercent]
/// above all, which is the server's own division and is never recomputed from two weights.
///
/// Money and weights are `String`s end to end: money at two decimals, weights at three. The
/// server builds this as a plain array rather than a Resource, so there is no `whenLoaded`
/// anywhere in it — **every key is always present**, nothing is nullable, and an empty period
/// reads as `'0.00'` / `'0.000'` / `0` rather than as a gap. [byType] is `[]` in that case,
/// never null.
///
/// Mirrors `SalesStatisticsQuery::__invoke()`.
@freezed
abstract class SalesStatistics with _$SalesStatistics {
  const factory SalesStatistics({
    required StatisticsPeriod period,
    @JsonKey(name: 'sales_value') required SalesValue salesValue,
    @JsonKey(name: 'by_type') required List<BagTypeRow> byType,
    @JsonKey(name: 'weight_comparison') required WeightComparison weightComparison,

    /// How many printed bags that was, by the piece — **kept apart from the weights beside it**.
    ///
    /// A different unit answering a different question, and the figure the printing engineer's
    /// share will one day be computed from. Plain bags are absent from it by construction.
    @JsonKey(name: 'printed_pieces') required PrintedPieces printedPieces,

    /// How many orders the whole board is actually about.
    ///
    /// **The honest denominator**, and the same job `ordersRecognized` does on الأرباح والخسائر:
    /// without it an all-zero board is unreadable, because it could mean the shop sold nothing
    /// or it could mean the period was typed wrong. Only orders carrying at least one bag are
    /// counted — an order of nothing but ستيكرات contributed nothing above and would inflate it.
    @JsonKey(name: 'orders_counted') required int ordersCounted,
  }) = _SalesStatistics;

  const SalesStatistics._();

  factory SalesStatistics.fromJson(Map<String, dynamic> json) => _$SalesStatisticsFromJson(json);

  /// Whether the board is about anything at all.
  ///
  /// Zero is not a failure and not an empty screen — it is a period in which nothing was
  /// delivered or settled, and saying so in words is more use than five blocks of `'0.00'`.
  bool get hasCountedOrders => ordersCounted > 0;
}

/// The window the board actually covers, echoed back by the server.
///
/// **Held as `String`s, never as `DateTime`s.** They are display echoes of the two dates that
/// were sent, and round-tripping one through a `DateTime` is how a plain day grows a timezone
/// offset it never had.
///
/// **These are UTC day boundaries**, while the orders list asks its own questions in the shop's
/// timezone — so an order delivered just after midnight in طرابلس sits inside the month there and
/// outside it here. The presets are computed from the phone's clock; **this echo is what the
/// figures are labelled with**, never the values the app sent.
@freezed
abstract class StatisticsPeriod with _$StatisticsPeriod {
  const factory StatisticsPeriod({required String from, required String to}) = _StatisticsPeriod;

  const StatisticsPeriod._();

  factory StatisticsPeriod.fromJson(Map<String, dynamic> json) => _$StatisticsPeriodFromJson(json);

  /// «من 2026-03-01 إلى 2026-03-31» — both ends inclusive, whole days.
  String get label => 'من $from إلى $to';
}

/// قيمة المبيعات — what was sold, in dinars, split سادة/مطبوع.
///
/// [total] is [plain] plus [printed] and the server sends all three anyway. It is rendered from
/// its own key rather than added up here: the guarantee is that they agree, not that this app
/// should be the one doing the addition.
@freezed
abstract class SalesValue with _$SalesValue {
  const factory SalesValue({
    required String plain,
    required String printed,
    required String total,
  }) = _SalesValue;

  factory SalesValue.fromJson(Map<String, dynamic> json) => _$SalesValueFromJson(json);
}

/// One material's row in «مبيعات الأكياس حسب النوع».
///
/// **[type] is the shelf's material, not the product's heading** — «كيس شحن مطبوع» and «كيس شحن
/// سادة» are two catalogue rows drawing on one pile, and they arrive here as one row carrying its
/// own split.
///
/// **The labels are untidy and the app must not tidy them.** Several read «أكياس شفافه -» with a
/// trailing dash, because those shelves were auto-created from product names. Trimming it in Dart
/// would hide a naming problem that also shows on the inventory screens; the fix belongs in the
/// data. Render what the server sends.
@freezed
abstract class BagTypeRow with _$BagTypeRow {
  const factory BagTypeRow({
    required String type,
    required String value,
    @JsonKey(name: 'weight_kg') required String weightKg,
    @JsonKey(name: 'plain_kg') required String plainKg,
    @JsonKey(name: 'printed_kg') required String printedKg,

    /// Printed pieces on this material only; a plain row carries `0`.
    required int pieces,
  }) = _BagTypeRow;

  const BagTypeRow._();

  factory BagTypeRow.fromJson(Map<String, dynamic> json) => _$BagTypeRowFromJson(json);

  /// Whether this material was ever weighed.
  ///
  /// **A row with real value and no weight is correct, not a bug** — أكياس ورقية عادية is stocked
  /// by the piece, so it earns money and weighs nothing. The row is drawn like any other and its
  /// `0.000` is drawn as a figure rather than as «—»: its value is part of the total above it,
  /// and hiding it would make the table stop adding up.
  bool get hasWeight => (num.tryParse(weightKg) ?? 0) > 0;
}

/// السادة مقابل المطبوع — the same period measured on the scale rather than at the till.
@freezed
abstract class WeightComparison with _$WeightComparison {
  const factory WeightComparison({
    @JsonKey(name: 'plain_kg') required String plainKg,
    @JsonKey(name: 'printed_kg') required String printedKg,
    @JsonKey(name: 'total_kg') required String totalKg,

    /// «كم نسبة المطبوع؟» — the server's own division, to one decimal place.
    ///
    /// **Never recomputed from the two weights beside it.** It is the question the whole
    /// comparison exists to answer, and it is answered once, on the server.
    @JsonKey(name: 'printed_share_percent') required String printedSharePercent,

    /// How much of the period's *value* has a weight behind it.
    ///
    /// Three kinds of line legitimately have none: work a vendor made, a size with no shelf, and
    /// a shelf counted in pieces. Without this figure a month full of any of them shows a weight
    /// that looks wrong beside its own dinars, and no reader can tell «باعوا قليلاً» from «ما
    /// وزنوهش».
    @JsonKey(name: 'weight_coverage_percent') required String weightCoveragePercent,
  }) = _WeightComparison;

  const WeightComparison._();

  factory WeightComparison.fromJson(Map<String, dynamic> json) => _$WeightComparisonFromJson(json);

  /// Whether every dinar on the board has a weight behind it.
  ///
  /// At 100 the coverage figure is noise and the screen says nothing; below it, it is the
  /// difference between two readings of the same low number. A value that will not parse counts
  /// as covered, because printing a caveat over figures nobody could measure is the worse of the
  /// two mistakes.
  bool get isFullyCovered => (num.tryParse(weightCoveragePercent) ?? 100) >= 100;
}

/// عدد الأكياس المطبوعة — a count, and the weight it corresponds to.
///
/// **Two units on one small block, deliberately.** [count] is the figure the press's own share
/// will be computed from; [weightKg] is the same bags on the scale, repeated from
/// [WeightComparison.printedKg] so the count is never read as a weight.
@freezed
abstract class PrintedPieces with _$PrintedPieces {
  const factory PrintedPieces({
    required int count,
    @JsonKey(name: 'weight_kg') required String weightKg,
  }) = _PrintedPieces;

  const PrintedPieces._();

  factory PrintedPieces.fromJson(Map<String, dynamic> json) => _$PrintedPiecesFromJson(json);

  /// `5270` → `'5,270'` — a piece count is read at arm's length like every other figure.
  String get countLabel => count.grouped;
}
