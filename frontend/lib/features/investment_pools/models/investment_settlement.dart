import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_settlement.freezed.dart';
part 'investment_settlement.g.dart';

/// تسوية — a dated, signed statement of where a pool's money is.
///
/// **A review point, not a close.** It moves no money, liquidates no stock and touches no period;
/// the pool trades on through it. What it leaves behind is a position somebody approved and the
/// [drift].
///
/// **Lead with the drift.** Every other figure here can be read off the pool's live screens at any
/// time; the drift is the only one that could not, because it is a comparison of two derivations
/// that never consult each other — the wallet ledger on one side, a walk of the movements on the
/// other. A screen that buries it under eleven reassuring totals turns a finding into decoration.
@freezed
abstract class InvestmentSettlement with _$InvestmentSettlement {
  const factory InvestmentSettlement({
    required int id,
    String? code,
    @JsonKey(name: 'investment_pool_id') required int investmentPoolId,

    @JsonKey(name: 'period_from_id') int? periodFromId,
    @JsonKey(name: 'period_to_id') int? periodToId,
    @JsonKey(name: 'settled_on') String? settledOn,

    @JsonKey(name: 'approved_by') int? approvedBy,
    @JsonKey(name: 'approved_by_name') String? approvedByName,

    @JsonKey(name: 'total_capital') @Default('0.00') String totalCapital,
    @JsonKey(name: 'investor_capital') @Default('0.00') String investorCapital,
    @JsonKey(name: 'company_capital') @Default('0.00') String companyCapital,

    @JsonKey(name: 'deployable_cash') @Default('0.00') String deployableCash,
    @JsonKey(name: 'stock_at_cost') @Default('0.00') String stockAtCost,

    /// Real money the company is holding that [deployableCash] does **not** count as spendable —
    /// the open period's profit, which belongs to nobody yet.
    ///
    /// Printed beside [deployableCash] and **never added to it**.
    @JsonKey(name: 'undeployed_current_profit')
    @Default('0.00')
    String undeployedCurrentProfit,

    /// Booked as earned, not yet collected. Profit is recognised at delivery, so an order sold on
    /// credit counts as cash in hand everywhere else; this is the size of that assumption.
    @Default('0.00') String receivables,

    /// Undrawn profit sitting in wallets — money the company holds and does not own, and never
    /// working capital.
    @Default('0.00') String liabilities,

    @JsonKey(name: 'distributed_profit_to_date')
    @Default('0.00')
    String distributedProfitToDate,
    @JsonKey(name: 'damage_to_date') @Default('0.00') String damageToDate,
    @JsonKey(name: 'shortage_to_date') @Default('0.00') String shortageToDate,

    /// What the pool's cash *should* be, walked from the movements alone.
    @JsonKey(name: 'reconstructed_cash')
    @Default('0.00')
    String reconstructedCash,

    /// **A finding, not an error.** Nothing corrects it and nothing absorbs it: it stands on the
    /// record until somebody explains it, which is the only treatment that does not eventually
    /// teach people to ignore it.
    @Default('0.00') String drift,
    @JsonKey(name: 'has_drift') @Default(false) bool hasDrift,

    String? notes,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _InvestmentSettlement;

  factory InvestmentSettlement.fromJson(Map<String, dynamic> json) =>
      _$InvestmentSettlementFromJson(json);
}

/// The same position, derived now rather than read off a signed record.
///
/// This is what the screen shows **before** somebody signs, and it is the same arithmetic the
/// signing then freezes — a screen that asked for a signature on figures computed a second way
/// would have a person approve one thing and the record keep another.
@freezed
abstract class SettlementSnapshot with _$SettlementSnapshot {
  const factory SettlementSnapshot({
    @JsonKey(name: 'total_capital') @Default('0.00') String totalCapital,
    @JsonKey(name: 'investor_capital') @Default('0.00') String investorCapital,
    @JsonKey(name: 'company_capital') @Default('0.00') String companyCapital,

    @JsonKey(name: 'deployable_cash') @Default('0.00') String deployableCash,
    @JsonKey(name: 'stock_at_cost') @Default('0.00') String stockAtCost,
    @JsonKey(name: 'undeployed_current_profit')
    @Default('0.00')
    String undeployedCurrentProfit,

    @Default('0.00') String receivables,
    @Default('0.00') String liabilities,

    @JsonKey(name: 'distributed_profit_to_date')
    @Default('0.00')
    String distributedProfitToDate,

    /// A loss that ran past what an investor had in the pool, written off to the company. It moves
    /// no cash across a counter, but the pool really does go on holding goods it could not
    /// otherwise have paid for — so it is an inflow in the walk, and named rather than drifting.
    @JsonKey(name: 'company_absorbed_loss')
    @Default('0.00')
    String companyAbsorbedLoss,

    @JsonKey(name: 'damage_to_date') @Default('0.00') String damageToDate,
    @JsonKey(name: 'shortage_to_date') @Default('0.00') String shortageToDate,

    @JsonKey(name: 'book_value') @Default('0.00') String bookValue,
    @JsonKey(name: 'reconstructed_cash')
    @Default('0.00')
    String reconstructedCash,
    @JsonKey(name: 'reconstructed_value')
    @Default('0.00')
    String reconstructedValue,

    @Default('0.00') String drift,

    @JsonKey(name: 'period_from_id') int? periodFromId,
    @JsonKey(name: 'period_to_id') int? periodToId,

    /// When this pool was last signed off, and when the next review falls due.
    ///
    /// **Derived from the last settlement plus «مدة التسوية», never stored** — shorten the cycle
    /// and the next date moves; a settlement already signed keeps the date it was signed on.
    ///
    /// A pool nobody has ever settled is **not** overdue: it has no last settlement to count
    /// from, and inventing one would put a red mark on every new pool from the day it opened,
    /// which is how people learn to ignore a red mark.
    @JsonKey(name: 'last_settled_on') String? lastSettledOn,
    @JsonKey(name: 'next_settlement_due_on') String? nextSettlementDueOn,
    @JsonKey(name: 'settlement_is_overdue') @Default(false) bool settlementIsOverdue,
    @JsonKey(name: 'settlement_period_months') @Default(6) int settlementPeriodMonths,
  }) = _SettlementSnapshot;

  factory SettlementSnapshot.fromJson(Map<String, dynamic> json) =>
      _$SettlementSnapshotFromJson(json);
}
