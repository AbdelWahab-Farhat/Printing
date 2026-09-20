import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_period.freezed.dart';
part 'investment_period.g.dart';

/// فترة — one accounting period of one pool.
///
/// **This is what closes**, not the pool. A close divides what the period made, writes losses down
/// against capital, releases profit into wallets where it becomes withdrawable, pays whoever asked
/// to leave, and opens the next period in the same breath so the pool is never without one.
///
/// A closed period is **immutable**. Its [snapshot] is the arithmetic as it stood that day, frozen
/// deliberately: a correction posted afterwards lands in whichever period is open when somebody
/// notices, never back here — the money this one released has already been withdrawn.
@freezed
abstract class InvestmentPeriod with _$InvestmentPeriod {
  const factory InvestmentPeriod({
    required int id,
    @JsonKey(name: 'investment_pool_id') required int investmentPoolId,

    @JsonKey(name: 'starts_on') String? startsOn,

    /// The admin may move an **open** period's end date. A closed one cannot be reached from the
    /// settings screen at all, by construction rather than by a guard somebody remembers.
    @JsonKey(name: 'ends_on') String? endsOn,

    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'is_open') @Default(true) bool isOpen,

    /// Still open after the day it was meant to end.
    ///
    /// **Reported, never enforced.** Nothing closes a period but a person: a close divides profit
    /// and releases money into wallets it can be withdrawn from that afternoon, and it is
    /// legitimately refused while a returned-goods question is unanswered. A schedule doing that
    /// at three in the morning — or failing silently every night because of one question — is
    /// worse than a mark on a screen somebody looks at.
    ///
    /// A period that runs long keeps accruing perfectly correctly. What stops being true is only
    /// that its dates describe its contents.
    @JsonKey(name: 'is_overdue') @Default(false) bool isOverdue,
    @JsonKey(name: 'days_overdue') @Default(0) int daysOverdue,

    /// What would refuse the close if somebody pressed it now. Carried on the open period alone.
    @JsonKey(name: 'blocked_by_returned_goods')
    @Default(false)
    bool blockedByReturnedGoods,

    @JsonKey(name: 'closed_at') String? closedAt,

    /// Null while the period is open — there is nothing to freeze until it closes.
    PeriodSnapshot? snapshot,

    String? notes,
  }) = _InvestmentPeriod;

  factory InvestmentPeriod.fromJson(Map<String, dynamic> json) =>
      _$InvestmentPeriodFromJson(json);
}

/// The thirteen figures a close writes down and never revisits.
///
/// Not a breach of «الرصيد لا يُخزَّن»: this is a historical close, the way a manufacturing rate
/// snapshots the rate that was applied — not a running balance that could drift from the rows
/// beneath it.
@freezed
abstract class PeriodSnapshot with _$PeriodSnapshot {
  const factory PeriodSnapshot({
    @JsonKey(name: 'opening_cash') required String openingCash,
    @JsonKey(name: 'closing_cash') required String closingCash,
    @JsonKey(name: 'opening_stock_cost') required String openingStockCost,
    @JsonKey(name: 'closing_stock_cost') required String closingStockCost,

    @JsonKey(name: 'realized_margin') required String realizedMargin,
    @JsonKey(name: 'deductible_expenses') required String deductibleExpenses,
    @JsonKey(name: 'damage_cost') required String damageCost,
    @JsonKey(name: 'shortage_cost') required String shortageCost,
    @JsonKey(name: 'net_profit') required String netProfit,

    /// The terms actually applied, so a period read next year explains itself without anybody
    /// having to know what the settings said that month.
    @JsonKey(name: 'investor_share_percent_applied')
    required String investorSharePercentApplied,
    @JsonKey(name: 'investor_capital_weight_applied')
    required String investorCapitalWeightApplied,
    @JsonKey(name: 'total_pool_capital') required String totalPoolCapital,
    @JsonKey(name: 'total_investor_capital') required String totalInvestorCapital,
  }) = _PeriodSnapshot;

  factory PeriodSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PeriodSnapshotFromJson(json);
}

/// What a period has made **so far**, and whether anything is holding its close up.
///
/// **The same arithmetic the close then performs.** A close is an irreversible payout, so the
/// screen that asks somebody to press the button prints its working from this — two
/// implementations of the sum is how a person approves one figure and the ledger writes another.
@freezed
abstract class PeriodFigures with _$PeriodFigures {
  const factory PeriodFigures({
    @JsonKey(name: 'realized_margin') required String realizedMargin,
    @JsonKey(name: 'deductible_expenses') required String deductibleExpenses,

    /// «محسوبة مسبقاً» — shipping and customs typed on a purchase order. They are **already
    /// inside the cost of the layers that arrived**, so subtracting them again would charge the
    /// investors for one customs invoice twice.
    ///
    /// Shown beside the sum and never part of it. §6.2.4.
    @JsonKey(name: 'recorded_only_expenses')
    @Default('0.00')
    String recordedOnlyExpenses,

    @JsonKey(name: 'damage_cost') required String damageCost,
    @JsonKey(name: 'shortage_cost') required String shortageCost,
    @JsonKey(name: 'net_profit') required String netProfit,

    /// **The close is refused while this is true.** A cancelled printed order credits its material
    /// back to the shelf as good stock, and closing over that divides profit the pool did not earn
    /// on goods it does not have.
    @JsonKey(name: 'has_unanswered_returns')
    @Default(false)
    bool hasUnansweredReturns,

    InvestmentPeriod? period,
  }) = _PeriodFigures;

  factory PeriodFigures.fromJson(Map<String, dynamic> json) =>
      _$PeriodFiguresFromJson(json);
}
