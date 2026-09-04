// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_deal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestorDeal _$InvestorDealFromJson(Map<String, dynamic> json) =>
    _InvestorDeal(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      canBeEdited: json['can_be_edited'] as bool? ?? false,
      investorProfitSharePercent:
          json['investor_profit_share_percent'] as String,
      openedOn: json['opened_on'] as String?,
      closedAt: json['closed_at'] as String?,
      notes: json['notes'] as String?,
      investors:
          (json['investors'] as List<dynamic>?)
              ?.map((e) => DealParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealParticipant>[],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => DealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealItem>[],
      balances: json['balances'] == null
          ? null
          : DealBalances.fromJson(json['balances'] as Map<String, dynamic>),
      stock: json['stock'] == null
          ? null
          : DealStock.fromJson(json['stock'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InvestorDealToJson(_InvestorDeal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'can_be_edited': instance.canBeEdited,
      'investor_profit_share_percent': instance.investorProfitSharePercent,
      'opened_on': instance.openedOn,
      'closed_at': instance.closedAt,
      'notes': instance.notes,
      'investors': instance.investors.map((e) => e.toJson()).toList(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'balances': instance.balances?.toJson(),
      'stock': instance.stock?.toJson(),
    };

_DealParticipant _$DealParticipantFromJson(Map<String, dynamic> json) =>
    _DealParticipant(
      id: (json['id'] as num).toInt(),
      investorId: (json['investor_id'] as num).toInt(),
      investor: json['investor'] == null
          ? null
          : DealInvestorRef.fromJson(json['investor'] as Map<String, dynamic>),
      committedAmount: json['committed_amount'] as String,
      sharePercent: json['share_percent'] as String,
    );

Map<String, dynamic> _$DealParticipantToJson(_DealParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'investor_id': instance.investorId,
      'investor': instance.investor?.toJson(),
      'committed_amount': instance.committedAmount,
      'share_percent': instance.sharePercent,
    };

_DealInvestorRef _$DealInvestorRefFromJson(Map<String, dynamic> json) =>
    _DealInvestorRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$DealInvestorRefToJson(_DealInvestorRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
    };

_DealItem _$DealItemFromJson(Map<String, dynamic> json) => _DealItem(
  id: (json['id'] as num).toInt(),
  stockItemId: (json['stock_item_id'] as num).toInt(),
  stockItem: json['stock_item'] == null
      ? null
      : DealStockItemRef.fromJson(json['stock_item'] as Map<String, dynamic>),
  quantityExpected: json['quantity_expected'] as String?,
  expectedUnitCost: json['expected_unit_cost'] as String?,
  expectedUnitPrice: json['expected_unit_price'] as String?,
);

Map<String, dynamic> _$DealItemToJson(_DealItem instance) => <String, dynamic>{
  'id': instance.id,
  'stock_item_id': instance.stockItemId,
  'stock_item': instance.stockItem?.toJson(),
  'quantity_expected': instance.quantityExpected,
  'expected_unit_cost': instance.expectedUnitCost,
  'expected_unit_price': instance.expectedUnitPrice,
};

_DealStockItemRef _$DealStockItemRefFromJson(Map<String, dynamic> json) =>
    _DealStockItemRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String?,
      displayName: json['display_name'] as String?,
    );

Map<String, dynamic> _$DealStockItemRefToJson(_DealStockItemRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'display_name': instance.displayName,
    };

_DealBalances _$DealBalancesFromJson(Map<String, dynamic> json) =>
    _DealBalances(
      capital: json['capital'] as String,
      profit: json['profit'] as String,
      perInvestor:
          (json['per_investor'] as List<dynamic>?)
              ?.map(
                (e) => DealInvestorStanding.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <DealInvestorStanding>[],
    );

Map<String, dynamic> _$DealBalancesToJson(_DealBalances instance) =>
    <String, dynamic>{
      'capital': instance.capital,
      'profit': instance.profit,
      'per_investor': instance.perInvestor.map((e) => e.toJson()).toList(),
    };

_DealInvestorStanding _$DealInvestorStandingFromJson(
  Map<String, dynamic> json,
) => _DealInvestorStanding(
  investorId: (json['investor_id'] as num).toInt(),
  capital: json['capital'] as String,
  profit: json['profit'] as String,
);

Map<String, dynamic> _$DealInvestorStandingToJson(
  _DealInvestorStanding instance,
) => <String, dynamic>{
  'investor_id': instance.investorId,
  'capital': instance.capital,
  'profit': instance.profit,
};

_DealStock _$DealStockFromJson(Map<String, dynamic> json) => _DealStock(
  quantityReceived: json['quantity_received'] as String,
  quantityRemaining: json['quantity_remaining'] as String,
  quantitySold: json['quantity_sold'] as String,
  quantityDamaged: json['quantity_damaged'] as String,
  quantityShort: json['quantity_short'] as String,
  costRemaining: json['cost_remaining'] as String,
  costSold: json['cost_sold'] as String,
  costDamaged: json['cost_damaged'] as String,
  costShort: json['cost_short'] as String,
);

Map<String, dynamic> _$DealStockToJson(_DealStock instance) =>
    <String, dynamic>{
      'quantity_received': instance.quantityReceived,
      'quantity_remaining': instance.quantityRemaining,
      'quantity_sold': instance.quantitySold,
      'quantity_damaged': instance.quantityDamaged,
      'quantity_short': instance.quantityShort,
      'cost_remaining': instance.costRemaining,
      'cost_sold': instance.costSold,
      'cost_damaged': instance.costDamaged,
      'cost_short': instance.costShort,
    };
