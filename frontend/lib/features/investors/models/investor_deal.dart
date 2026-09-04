import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor_deal.freezed.dart';
part 'investor_deal.g.dart';

/// صفقة — one financed purchase of stock.
///
/// It stores no money and no quantities; everything below is walked from the ledgers when the
/// screen asks, so a figure here can never disagree with the rows behind it.
@freezed
abstract class InvestorDeal with _$InvestorDeal {
  const factory InvestorDeal({
    required int id,
    required String code,
    required String name,

    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,

    /// Whether its terms may still be rewritten — true only while it is a draft.
    @JsonKey(name: 'can_be_edited') @Default(false) bool canBeEdited,

    /// The investors' share of **this** deal's profit, copied from the company default when it
    /// was created and frozen when it opened.
    @JsonKey(name: 'investor_profit_share_percent') required String investorProfitSharePercent,

    @JsonKey(name: 'opened_on') String? openedOn,
    @JsonKey(name: 'closed_at') String? closedAt,
    String? notes,

    @Default(<DealParticipant>[]) List<DealParticipant> investors,
    @Default(<DealItem>[]) List<DealItem> items,

    DealBalances? balances,
    DealStock? stock,
  }) = _InvestorDeal;

  factory InvestorDeal.fromJson(Map<String, dynamic> json) => _$InvestorDealFromJson(json);
}

@freezed
abstract class DealParticipant with _$DealParticipant {
  const factory DealParticipant({
    required int id,
    @JsonKey(name: 'investor_id') required int investorId,
    DealInvestorRef? investor,

    /// The pledge the percentage was agreed against — **not** what actually arrived, which is a
    /// walk of his wallet and is shown beside it rather than merged with it.
    @JsonKey(name: 'committed_amount') required String committedAmount,

    /// His slice of the investors' share, not of the whole profit.
    @JsonKey(name: 'share_percent') required String sharePercent,
  }) = _DealParticipant;

  factory DealParticipant.fromJson(Map<String, dynamic> json) => _$DealParticipantFromJson(json);
}

@freezed
abstract class DealInvestorRef with _$DealInvestorRef {
  const factory DealInvestorRef({
    required int id,
    required String code,
    required String name,
  }) = _DealInvestorRef;

  factory DealInvestorRef.fromJson(Map<String, dynamic> json) => _$DealInvestorRefFromJson(json);
}

@freezed
abstract class DealItem with _$DealItem {
  const factory DealItem({
    required int id,
    @JsonKey(name: 'stock_item_id') required int stockItemId,
    @JsonKey(name: 'stock_item') DealStockItemRef? stockItem,
    @JsonKey(name: 'quantity_expected') String? quantityExpected,
    @JsonKey(name: 'expected_unit_cost') String? expectedUnitCost,
    @JsonKey(name: 'expected_unit_price') String? expectedUnitPrice,
  }) = _DealItem;

  factory DealItem.fromJson(Map<String, dynamic> json) => _$DealItemFromJson(json);
}

@freezed
abstract class DealStockItemRef with _$DealStockItemRef {
  const factory DealStockItemRef({
    required int id,
    String? code,
    @JsonKey(name: 'display_name') String? displayName,
  }) = _DealStockItemRef;

  factory DealStockItemRef.fromJson(Map<String, dynamic> json) =>
      _$DealStockItemRefFromJson(json);
}

@freezed
abstract class DealBalances with _$DealBalances {
  const factory DealBalances({
    required String capital,
    required String profit,
    @JsonKey(name: 'per_investor') @Default(<DealInvestorStanding>[]) List<DealInvestorStanding> perInvestor,
  }) = _DealBalances;

  factory DealBalances.fromJson(Map<String, dynamic> json) => _$DealBalancesFromJson(json);
}

@freezed
abstract class DealInvestorStanding with _$DealInvestorStanding {
  const factory DealInvestorStanding({
    @JsonKey(name: 'investor_id') required int investorId,
    required String capital,
    required String profit,
  }) = _DealInvestorStanding;

  factory DealInvestorStanding.fromJson(Map<String, dynamic> json) =>
      _$DealInvestorStandingFromJson(json);
}

/// What the deal's goods are doing.
///
/// `quantityReceived` is derived by the server rather than summed off the layers, because a
/// transfer between warehouses mints a fresh layer and summing received quantities would
/// double-count every unit ever moved.
@freezed
abstract class DealStock with _$DealStock {
  const factory DealStock({
    @JsonKey(name: 'quantity_received') required String quantityReceived,
    @JsonKey(name: 'quantity_remaining') required String quantityRemaining,
    @JsonKey(name: 'quantity_sold') required String quantitySold,
    @JsonKey(name: 'quantity_damaged') required String quantityDamaged,
    @JsonKey(name: 'quantity_short') required String quantityShort,
    @JsonKey(name: 'cost_remaining') required String costRemaining,
    @JsonKey(name: 'cost_sold') required String costSold,
    @JsonKey(name: 'cost_damaged') required String costDamaged,
    @JsonKey(name: 'cost_short') required String costShort,
  }) = _DealStock;

  factory DealStock.fromJson(Map<String, dynamic> json) => _$DealStockFromJson(json);
}
