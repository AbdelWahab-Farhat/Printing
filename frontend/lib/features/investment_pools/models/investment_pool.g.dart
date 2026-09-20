// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvestmentPool _$InvestmentPoolFromJson(
  Map<String, dynamic> json,
) => _InvestmentPool(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  kind: json['kind'] as String? ?? 'pool',
  kindLabel: json['kind_label'] as String? ?? 'صندوق',
  investorProfitSharePercent: json['investor_profit_share_percent'] as String,
  stockItems:
      (json['stock_items'] as List<dynamic>?)
          ?.map((e) => PoolStockItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PoolStockItem>[],
  investors:
      (json['investors'] as List<dynamic>?)
          ?.map((e) => PoolMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PoolMember>[],
  capitalTiming: json['capital_timing'] == null
      ? null
      : CapitalTiming.fromJson(json['capital_timing'] as Map<String, dynamic>),
  openedOn: json['opened_on'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$InvestmentPoolToJson(_InvestmentPool instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'kind': instance.kind,
      'kind_label': instance.kindLabel,
      'investor_profit_share_percent': instance.investorProfitSharePercent,
      'stock_items': instance.stockItems.map((e) => e.toJson()).toList(),
      'investors': instance.investors.map((e) => e.toJson()).toList(),
      'capital_timing': instance.capitalTiming?.toJson(),
      'opened_on': instance.openedOn,
      'notes': instance.notes,
    };

_PoolStockItem _$PoolStockItemFromJson(Map<String, dynamic> json) =>
    _PoolStockItem(
      stockItemId: (json['stock_item_id'] as num).toInt(),
      name: json['name'] as String?,
    );

Map<String, dynamic> _$PoolStockItemToJson(_PoolStockItem instance) =>
    <String, dynamic>{
      'stock_item_id': instance.stockItemId,
      'name': instance.name,
    };

_PoolMember _$PoolMemberFromJson(Map<String, dynamic> json) => _PoolMember(
  investorId: (json['investor_id'] as num).toInt(),
  name: json['name'] as String?,
  joinedAt: json['joined_at'] as String?,
  capital: json['capital'] as String? ?? '0.00',
  sharePercent: json['share_percent'] as String? ?? '0.0000',
  isCompany: json['is_company'] as bool? ?? false,
  capitalFreeOn: json['capital_free_on'] as String?,
);

Map<String, dynamic> _$PoolMemberToJson(_PoolMember instance) =>
    <String, dynamic>{
      'investor_id': instance.investorId,
      'name': instance.name,
      'joined_at': instance.joinedAt,
      'capital': instance.capital,
      'share_percent': instance.sharePercent,
      'is_company': instance.isCompany,
      'capital_free_on': instance.capitalFreeOn,
    };

_CapitalTiming _$CapitalTimingFromJson(Map<String, dynamic> json) =>
    _CapitalTiming(
      currentPeriod: json['current_period'] == null
          ? null
          : InvestmentPeriod.fromJson(
              json['current_period'] as Map<String, dynamic>,
            ),
      graceWindowEndsOn: json['grace_window_ends_on'] as String?,
      capitalTakesEffectOn: json['capital_takes_effect_on'] as String?,
      isInsideGraceWindow: json['is_inside_grace_window'] as bool? ?? false,
    );

Map<String, dynamic> _$CapitalTimingToJson(_CapitalTiming instance) =>
    <String, dynamic>{
      'current_period': instance.currentPeriod?.toJson(),
      'grace_window_ends_on': instance.graceWindowEndsOn,
      'capital_takes_effect_on': instance.capitalTakesEffectOn,
      'is_inside_grace_window': instance.isInsideGraceWindow,
    };

_PoolDeployableCash _$PoolDeployableCashFromJson(Map<String, dynamic> json) =>
    _PoolDeployableCash(
      capital: json['capital'] as String,
      unsettledProfit: json['unsettled_profit'] as String,
      bookValue: json['book_value'] as String,
      stockAtCost: json['stock_at_cost'] as String,
      deployableCash: json['deployable_cash'] as String,
    );

Map<String, dynamic> _$PoolDeployableCashToJson(_PoolDeployableCash instance) =>
    <String, dynamic>{
      'capital': instance.capital,
      'unsettled_profit': instance.unsettledProfit,
      'book_value': instance.bookValue,
      'stock_at_cost': instance.stockAtCost,
      'deployable_cash': instance.deployableCash,
    };
