import 'package:dayaa/features/investment_pools/models/investment_period.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_pool.freezed.dart';
part 'investment_pool.g.dart';

/// صندوق — one continuous pool for one material.
///
/// **It never closes.** Its [InvestmentPeriod]s do, and its ownership is recomputed from capital
/// at each one — which is the whole difference from the صفقة that came before, where the partners
/// and their percentages were frozen the day the lorry was funded.
///
/// Like a deal it stores no money and no quantities. Capital, deployable cash, stock at cost and
/// unsettled profit are all walked from the ledger and the cost layers when a screen asks, so a
/// figure here can never disagree with the rows behind it.
@freezed
abstract class InvestmentPool with _$InvestmentPool {
  const factory InvestmentPool({
    required int id,
    required String code,
    required String name,

    /// Always `pool` on this model — a legacy صفقة can never be reached through a pool route,
    /// because the server binds `{pool}` to `kind = 'pool'`. Carried anyway so a screen showing
    /// both kinds in one list has the word rather than an inference.
    @Default('pool') String kind,
    @JsonKey(name: 'kind_label') @Default('صندوق') String kindLabel,

    /// The investors' share of this pool's net profit. Given once when the pool is opened and
    /// not editable after: it is the term the partners were shown.
    @JsonKey(name: 'investor_profit_share_percent')
    required String investorProfitSharePercent,

    /// The shelves this pool buys. **Each belongs to exactly one pool**, guaranteed by a unique
    /// index rather than by a rule anybody has to remember — which is why the purchase screen
    /// never asks who is financing a line.
    @JsonKey(name: 'stock_items')
    @Default(<PoolStockItem>[])
    List<PoolStockItem> stockItems,

    @Default(<PoolMember>[]) List<PoolMember> investors,

    /// Whether capital offered right now would work this period or wait for the next.
    ///
    /// Null off the list, which does not walk it. Read it **before** showing the capital form:
    /// it is answered by the same function that then acts on the request, so the warning and the
    /// behaviour cannot drift apart.
    @JsonKey(name: 'capital_timing') CapitalTiming? capitalTiming,

    @JsonKey(name: 'opened_on') String? openedOn,
    String? notes,
  }) = _InvestmentPool;

  factory InvestmentPool.fromJson(Map<String, dynamic> json) =>
      _$InvestmentPoolFromJson(json);
}

/// One shelf a pool owns.
@freezed
abstract class PoolStockItem with _$PoolStockItem {
  const factory PoolStockItem({
    @JsonKey(name: 'stock_item_id') required int stockItemId,
    String? name,
  }) = _PoolStockItem;

  factory PoolStockItem.fromJson(Map<String, dynamic> json) =>
      _$PoolStockItemFromJson(json);
}

/// Somebody who is in the pool.
///
/// **No percentage.** A pool's ownership is a plain capital ratio recomputed at every close, so
/// there is no stored share to show here — the figure that means something is his capital, and
/// that is on the period's own record.
@freezed
abstract class PoolMember with _$PoolMember {
  const factory PoolMember({
    @JsonKey(name: 'investor_id') required int investorId,
    String? name,
    @JsonKey(name: 'joined_at') String? joinedAt,

    /// What he has in this pool, walked from the ledger.
    @Default('0.00') String capital,

    /// **His weight as it stands today** — his capital over the pool's, derived on each read and
    /// stored nowhere.
    ///
    /// Not the same figure as the one on a closed period: this moves whenever anybody's capital
    /// moves, and it is what the next close *would* apply if it happened now. What he was actually
    /// paid last month is frozen on that period.
    @JsonKey(name: 'share_percent') @Default('0.0000') String sharePercent,

    /// The company's own row. It takes a capital weight like anybody else, and is **exempt from
    /// the minimum term** — it is the operator, not a partner who might take a month's profit
    /// and leave.
    @JsonKey(name: 'is_company') @Default(false) bool isCompany,

    /// The day his capital may be asked back, or null when it already may.
    ///
    /// Null covers the three cases a screen treats identically — no minimum is set, he holds
    /// nothing here, and the term has already run — because in all three there is nothing to
    /// tell him. Answered by the same function that then refuses an early exit, so the date
    /// shown and the date enforced are one.
    @JsonKey(name: 'capital_free_on') String? capitalFreeOn,
  }) = _PoolMember;

  factory PoolMember.fromJson(Map<String, dynamic> json) =>
      _$PoolMemberFromJson(json);
}

/// When capital offered now would actually start earning.
///
/// **The grace window, answered by the server.** For the first few days of a period money still
/// joins it and works the whole month; after that it waits for the next boundary, because
/// ownership is a capital ratio and a ratio is only exact if capital does not move mid-period.
///
/// The app never computes this. The admin may change the window, and a client that decided for
/// itself would warn about a boundary the server does not keep.
@freezed
abstract class CapitalTiming with _$CapitalTiming {
  const factory CapitalTiming({
    @JsonKey(name: 'current_period') InvestmentPeriod? currentPeriod,

    /// The last day money may still join the period that is running.
    @JsonKey(name: 'grace_window_ends_on') String? graceWindowEndsOn,

    /// The day capital offered **now** would begin to earn — today's period, or the next one.
    @JsonKey(name: 'capital_takes_effect_on') String? capitalTakesEffectOn,

    @JsonKey(name: 'is_inside_grace_window')
    @Default(false)
    bool isInsideGraceWindow,
  }) = _CapitalTiming;

  factory CapitalTiming.fromJson(Map<String, dynamic> json) =>
      _$CapitalTimingFromJson(json);
}

/// What a pool may spend — and, beside it, what it may not.
///
/// **The two are never added together on a screen.** Undrawn profit is money the company holds
/// and does not own: once a period closes an investor's share is his, and a lorry bought with it
/// would be spending somebody's settled earnings. The owner's ruling.
@freezed
abstract class PoolDeployableCash with _$PoolDeployableCash {
  const factory PoolDeployableCash({
    required String capital,

    /// The current period's earnings, banked whole and not yet divided.
    @JsonKey(name: 'unsettled_profit') required String unsettledProfit,

    @JsonKey(name: 'book_value') required String bookValue,
    @JsonKey(name: 'stock_at_cost') required String stockAtCost,
    @JsonKey(name: 'deployable_cash') required String deployableCash,
  }) = _PoolDeployableCash;

  factory PoolDeployableCash.fromJson(Map<String, dynamic> json) =>
      _$PoolDeployableCashFromJson(json);
}
