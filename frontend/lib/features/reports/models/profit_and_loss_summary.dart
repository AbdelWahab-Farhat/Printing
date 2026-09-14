import 'package:dayaa/core/utils/digits.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profit_and_loss_summary.freezed.dart';
part 'profit_and_loss_summary.g.dart';

/// الأرباح والخسائر over one period, exactly as the server computed it.
///
/// **Nothing in this file is derived, and three of the figures look derivable but are not:**
///
///   * [grossProfit] is *not* [PnlRevenue.total] minus [PnlCostOfGoodsSold.total]. The server
///     subtracts the unrounded cost and rounds the answer once, so a subtraction repeated here
///     can land a قرش away — and a number the reader can compute two ways is the number they
///     stop believing.
///   * [PnlCostOfGoodsSold.total] and its three parts come from two different tables and need
///     not add up. See its own note.
///   * [cashCollected] belongs to none of the rows above it at all. See its own note.
///
/// Money is a `String` end to end, at exactly two decimals, and [grossProfit] carries a leading
/// `-` when the period lost money. The server builds this as a plain array rather than a
/// Resource, so there is no `whenLoaded` anywhere in it: **every key a given server publishes is
/// always present**, and an empty period reads as `'0.00'` rather than as a gap. The one
/// nullable field is [losses], and it is nullable against *older servers* rather than against
/// an empty period — see its own note.
///
/// Mirrors `ProfitAndLossSummaryQuery::__invoke()`.
@freezed
abstract class ProfitAndLossSummary with _$ProfitAndLossSummary {
  const factory ProfitAndLossSummary({
    required PnlPeriod period,
    required PnlRevenue revenue,
    @JsonKey(name: 'cost_of_goods_sold') required PnlCostOfGoodsSold costOfGoodsSold,
    @JsonKey(name: 'gross_profit') required String grossProfit,

    /// Money that came in over these same days — and nothing more than that. See [PnlPeriod]
    /// for what the days mean and the class note on the screen for why it is never netted.
    @JsonKey(name: 'cash_collected') required String cashCollected,

    /// What the business decided it will never collect — the difference on an order that came
    /// back short, closed on the record rather than typed in as a payment nobody received.
    ///
    /// **Not a loss, and deliberately not on the «الخسائر» card.** Nothing was made and nothing
    /// was spoiled: a write-off forgives a receivable. This statement recognises revenue when
    /// the order is delivered and carries no expense side at all, so there is nowhere in the
    /// arithmetic above to hang a bad debt — which is why the server publishes it beside
    /// [cashCollected] rather than inside [losses], and why it is read on the same
    /// reconciliation shelf. A write-off that was undone is not counted.
    ///
    /// Nullable for the reason [losses] is, and for one more: this key has been on the wire
    /// since the write-off feature shipped and no screen in this app has ever read it.
    @JsonKey(name: 'write_offs') String? writeOffs,

    /// Goods this business made and never sold — تلف on the press, and what a customer left on
    /// the counter.
    ///
    /// **Reported, never subtracted.** Both figures are already inside [grossProfit] by
    /// construction — the material left the shelf and its cost was recognised — so showing them
    /// as a deduction would tell the same story twice and make the arithmetic on screen fail to
    /// add up.
    ///
    /// The one nullable field in this class, and for a reason the others are not: it is the one
    /// key `ProfitAndLossSummaryQuery` did not always publish, so an app talking to a server
    /// older than the feature still parses its report rather than failing on a missing block.
    PnlLosses? losses,

    /// How many orders the revenue and cost blocks are actually about.
    ///
    /// **The honest denominator, and the only integer in the payload.** Without it, an
    /// all-zero report is unreadable: it could mean the shop delivered nothing, or it could
    /// mean the period was typed wrong. A zero here beside a non-zero [cashCollected] is an
    /// ordinary state — deposits taken against work not yet delivered — not a contradiction.
    @JsonKey(name: 'orders_recognized') required int ordersRecognized,
  }) = _ProfitAndLossSummary;

  const ProfitAndLossSummary._();

  factory ProfitAndLossSummary.fromJson(Map<String, dynamic> json) =>
      _$ProfitAndLossSummaryFromJson(json);

  /// `'12450.00'` → `'12,450'` — the one number this screen is opened for, at arm's length.
  String get grossProfitLabel => groupedDecimal(grossProfit);

  /// Whether the period cost more than it earned.
  ///
  /// `num.tryParse` only ever asks this question; the string is what gets rendered. A value it
  /// cannot read counts as a profit, because painting «خسارة» over a figure nobody could parse
  /// is the worse of the two mistakes.
  bool get isLoss => (num.tryParse(grossProfit) ?? 0) < 0;

  /// Whether the block of figures is about anything at all.
  ///
  /// Zero is not a failure and not an empty screen — it is a period in which nothing was
  /// delivered or settled, and saying so is more use than four rows of `'0.00'` with no
  /// explanation.
  bool get hasRecognisedOrders => ordersRecognized > 0;
}

/// The window the report actually covers, echoed back by the server.
///
/// **Held as `String`s, never as `DateTime`s.** They are display echoes of the two dates that
/// were sent, and round-tripping one through a `DateTime` is how a plain day grows a timezone
/// offset it never had.
///
/// **These are UTC day boundaries**, while the orders list asks its own questions in the shop's
/// timezone — so an order delivered just after midnight in طرابلس sits inside the month there
/// and outside it here. The two screens can differ by a couple of hours of orders at every
/// period edge; that is the server's arithmetic, and echoing the window rather than assuming it
/// is what lets the reader see which days they were actually given.
@freezed
abstract class PnlPeriod with _$PnlPeriod {
  const factory PnlPeriod({required String from, required String to}) = _PnlPeriod;

  const PnlPeriod._();

  factory PnlPeriod.fromJson(Map<String, dynamic> json) => _$PnlPeriodFromJson(json);

  /// «من 2026-03-01 إلى 2026-03-31» — both ends inclusive, whole days.
  String get label => 'من $from إلى $to';
}

/// What was recognised as earned over the period.
///
/// **[total] is not what the customers were billed.** It is [product] plus a chargeable
/// [service] fee and nothing else: delivery price is left out and the discount is not taken off,
/// so this will not agree with the sum of the orders' «الإجمالي». Calling it «إجمالي المبيعات»
/// on a screen would be a claim the number cannot support.
@freezed
abstract class PnlRevenue with _$PnlRevenue {
  const factory PnlRevenue({
    /// The lines on every recognised order, added up.
    required String product,

    /// The design fee — but only where the design was ours to charge for.
    ///
    /// A fee left on a customer-supplied design contributes `'0.00'` however large it is, since
    /// the fee stays on the row when the source flips so that toggling it back does not lose
    /// the number. It carries no cost anywhere in this system, deliberately, so there is no
    /// service-cost row to go looking for.
    required String service,

    required String total,
  }) = _PnlRevenue;

  factory PnlRevenue.fromJson(Map<String, dynamic> json) => _$PnlRevenueFromJson(json);
}

/// What was made and never sold, over the same period.
///
/// **Two failures, named apart, because they have two different fixes.** [scrap] is bags spoiled
/// on the press — ours to reduce by printing better. [partialDelivery] is bags made exactly as
/// ordered, counted, and left on the counter by the customer who asked for them: printed artwork
/// nobody else can buy. A single «خسائر» figure would hide which of the two a bad month was.
///
/// **[total] is the server's sum, not one made here**, for the reason every other figure on this
/// screen is the server's: two answers to one question is one answer too many.
@freezed
abstract class PnlLosses with _$PnlLosses {
  const factory PnlLosses({
    /// تلف — spoiled during production.
    required String scrap,

    /// ما لم يستلمه العميل — made, counted, refused.
    @JsonKey(name: 'partial_delivery') required String partialDelivery,

    required String total,
  }) = _PnlLosses;

  factory PnlLosses.fromJson(Map<String, dynamic> json) => _$PnlLossesFromJson(json);
}

/// What those same orders cost to make.
///
/// **[material] + [labor] + [overhead] need not equal [total], and that is not a rounding
/// error.** [total] is a cached column on the orders; the three parts are summed from the order
/// *lines*, a different table with its own scope. All four are rendered exactly as they arrived
/// — computing any one of them from the other three would be inventing a figure the server
/// never claimed.
@freezed
abstract class PnlCostOfGoodsSold with _$PnlCostOfGoodsSold {
  const factory PnlCostOfGoodsSold({
    /// What left the shelves, at what the batches it came out of actually cost.
    required String material,

    /// The two rate-driven costs, applied when an order first entered printing. American
    /// spelling because that is the key on the wire.
    required String labor,

    required String overhead,

    required String total,
  }) = _PnlCostOfGoodsSold;

  factory PnlCostOfGoodsSold.fromJson(Map<String, dynamic> json) =>
      _$PnlCostOfGoodsSoldFromJson(json);
}
